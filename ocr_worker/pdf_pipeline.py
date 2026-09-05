"""PDF / image ingestion pipeline: text-layer inspect, render, OCR, resume."""

from __future__ import annotations

import json
import logging
import os
import re
import tempfile
import threading
from collections.abc import Callable
from pathlib import Path
from typing import Any, Optional

from ocr_engine import OcrEngine, OcrResult, create_engine
from protocol import OcrEvent, OcrRequest

logger = logging.getLogger("ocr_worker.pdf_pipeline")

# Quality thresholds for native PDF text layers (section 10.5).
MIN_USABLE_CHARS = 40
MAX_REPLACEMENT_RATIO = 0.02
MAX_CONTROL_RATIO = 0.05
MIN_AVG_TOKEN_LEN = 1.6
MIN_LATIN_RATIO = 0.08

EventEmitter = Callable[[OcrEvent], None]
CancelCheck = Callable[[], bool]


def page_result_filename(page: int) -> str:
    return f"page_{page:04d}.json"


def page_result_path(output_directory: str, page: int) -> Path:
    return Path(output_directory) / page_result_filename(page)


def page_image_filename(page: int) -> str:
    return f"page_{page:04d}.png"


def dpi_for_quality(quality: str) -> int:
    if quality == "fast":
        return 300
    if quality == "balanced":
        return 320
    return 350  # highest — within 300–400 DPI


def text_layer_is_usable(text: str, *, page_area_hint: Optional[float] = None) -> tuple[bool, str]:
    """
    Return (usable, reason_code). reason_code is empty when usable.
    """
    if text is None:
        return False, "MISSING_TEXT_LAYER"

    normalized = text.replace("\x00", "")
    stripped = normalized.strip()
    if not stripped:
        return False, "EMPTY_TEXT_LAYER"

    # Unexpectedly low character count for a typical study page.
    min_chars = MIN_USABLE_CHARS
    if page_area_hint and page_area_hint > 0:
        # Rough density: expect ~1 char per 2500 pt² on text-heavy pages.
        expected = max(MIN_USABLE_CHARS, int(page_area_hint / 2500))
        min_chars = min(expected, 200)
    if len(stripped) < min_chars:
        return False, "LOW_CHAR_COUNT"

    replacement = stripped.count("\ufffd")
    if replacement / max(len(stripped), 1) > MAX_REPLACEMENT_RATIO:
        return False, "REPLACEMENT_CHARS"

    control = sum(1 for ch in stripped if ord(ch) < 32 and ch not in "\n\r\t")
    if control / max(len(stripped), 1) > MAX_CONTROL_RATIO:
        return False, "CONTROL_CHARS"

    tokens = re.findall(r"\S+", stripped)
    if tokens:
        avg_len = sum(len(t) for t in tokens) / len(tokens)
        # Severely fragmented extractions often yield many 1-char tokens.
        if len(tokens) >= 20 and avg_len < MIN_AVG_TOKEN_LEN:
            return False, "FRAGMENTED_TEXT"

    latin = len(re.findall(r"[A-Za-zÀ-ỹĂăÂâÊêÔôƠơƯưĐđ0-9]", stripped, re.UNICODE))
    if latin / max(len(stripped), 1) < MIN_LATIN_RATIO and len(stripped) > 80:
        return False, "UNEXPECTED_SCRIPT"

    return True, ""


def _atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(
        prefix=f".{path.stem}.",
        suffix=".tmp",
        dir=str(path.parent),
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_name, path)
    finally:
        if os.path.exists(tmp_name):
            try:
                os.remove(tmp_name)
            except OSError:
                pass


def load_completed_page(output_directory: str, page: int) -> Optional[dict[str, Any]]:
    path = page_result_path(output_directory, page)
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(data, dict):
        return None
    if data.get("page") != page:
        return None
    if data.get("status") != "completed":
        return None
    return data


def build_page_payload(
    *,
    page: int,
    method: str,
    text: str,
    ocr: Optional[OcrResult],
    warnings: list[dict[str, str]],
    image_relative_path: Optional[str],
    language_hints: list[str],
) -> dict[str, Any]:
    confidence = ocr.confidence if ocr else 1.0
    engine = ocr.engine if ocr else "pdfium_text_layer"
    model_name = ocr.model_name if ocr else "pdfium"
    model_version = ocr.model_version if ocr else "bundled"
    mock = bool(ocr.mock) if ocr else False
    blocks = [b.to_dict() for b in ocr.blocks] if ocr else []
    raw = ocr.raw if ocr else {"text_layer": text}
    metadata = dict(ocr.metadata) if ocr else {}
    metadata.update(
        {
            "method": method,
            "language_hints": language_hints,
        }
    )
    return {
        "page": page,
        "status": "completed",
        "method": method,
        "text": text,
        "normalized_text": text,
        "blocks": blocks,
        "bbox": blocks,
        "confidence": confidence,
        "engine": engine,
        "model_name": model_name,
        "model_version": model_version,
        "mock": mock,
        "image_relative_path": image_relative_path,
        "warnings": warnings,
        "raw": raw,
        "metadata": metadata,
    }


class PdfPipeline:
    """Processes PDFs page-by-page and single images via the OCR engine."""

    def __init__(
        self,
        request: OcrRequest,
        emit: EventEmitter,
        cancel_event: threading.Event,
        engine: Optional[OcrEngine] = None,
    ) -> None:
        self.request = request
        self.emit = emit
        self.cancel_event = cancel_event
        self.engine = engine or create_engine(request.model_dir)

    def cancelled(self) -> bool:
        return self.cancel_event.is_set()

    def run(self) -> None:
        action = self.request.action
        if action == "parse_image":
            self._run_image()
        elif action == "parse_document":
            self._run_document()
        else:
            raise ValueError(f"unsupported pipeline action: {action}")

    def _emit_progress(self, page: int, total: int, stage: str) -> None:
        self.emit(OcrEvent.progress(self.request.job_id, page, total, stage))

    def _emit_page_done(self, page: int, result_file: str) -> None:
        self.emit(
            OcrEvent.page_completed(self.request.job_id, page, result_file)
        )

    def _emit_warning(self, code: str, message: str, page: Optional[int] = None) -> None:
        self.emit(
            OcrEvent.warning(self.request.job_id, code, message=message, page=page)
        )

    def _run_image(self) -> None:
        input_path = Path(self.request.input_path)
        if not input_path.is_file():
            raise FileNotFoundError(f"input image not found: {input_path}")

        out_dir = Path(self.request.output_directory)
        out_dir.mkdir(parents=True, exist_ok=True)
        page = 1
        total = 1

        existing = load_completed_page(str(out_dir), page)
        if existing is not None and not self.request.should_force_ocr(page):
            self._emit_progress(page, total, "resume_skip")
            self._emit_page_done(page, page_result_filename(page))
            self.emit(OcrEvent.completed(self.request.job_id))
            return

        if self.cancelled():
            self._emit_warning("CANCELLED", "job cancelled before OCR", page=page)
            return

        self._emit_progress(page, total, "ocr")
        ocr = self.engine.run(
            str(input_path),
            language_hints=self.request.language_hints,
            page=page,
        )
        if ocr.mock:
            self._emit_warning(
                "MOCK_ENGINE",
                "OCR used mock engine (no PaddleOCR-VL weights / GPU)",
                page=page,
            )
        if ocr.confidence < 0.55:
            self._emit_warning(
                "LOW_CONFIDENCE",
                f"page confidence {ocr.confidence:.3f}",
                page=page,
            )

        payload = build_page_payload(
            page=page,
            method="ocr",
            text=ocr.text,
            ocr=ocr,
            warnings=[],
            image_relative_path=None,
            language_hints=self.request.language_hints,
        )
        result_file = page_result_filename(page)
        _atomic_write_json(out_dir / result_file, payload)
        self._emit_page_done(page, result_file)
        if not self.cancelled():
            self.emit(OcrEvent.completed(self.request.job_id))

    def _run_document(self) -> None:
        try:
            import pypdfium2 as pdfium
        except ImportError as exc:
            raise RuntimeError(
                "pypdfium2 is required for PDF processing; pip install -r requirements.txt"
            ) from exc

        input_path = Path(self.request.input_path)
        if not input_path.is_file():
            raise FileNotFoundError(f"input PDF not found: {input_path}")

        out_dir = Path(self.request.output_directory)
        pages_dir = out_dir / "pages"
        out_dir.mkdir(parents=True, exist_ok=True)
        pages_dir.mkdir(parents=True, exist_ok=True)

        pdf = pdfium.PdfDocument(str(input_path))
        try:
            page_count = len(pdf)
            selected = self.request.pages or list(range(1, page_count + 1))
            selected = [p for p in selected if 1 <= p <= page_count]
            if not selected:
                raise ValueError("no valid pages to process")

            total = len(selected)
            dpi = dpi_for_quality(self.request.quality)

            for index, page_number in enumerate(selected):
                if self.cancelled():
                    self._emit_warning(
                        "CANCELLED",
                        "job cancelled; remaining pages skipped",
                        page=page_number,
                    )
                    return

                existing = load_completed_page(str(out_dir), page_number)
                if existing is not None and not self.request.should_force_ocr(page_number):
                    self._emit_progress(page_number, total, "resume_skip")
                    self._emit_page_done(page_number, page_result_filename(page_number))
                    continue

                self._process_pdf_page(
                    pdf=pdf,
                    page_number=page_number,
                    total=total,
                    dpi=dpi,
                    out_dir=out_dir,
                    pages_dir=pages_dir,
                    page_index_in_job=index,
                )
        finally:
            pdf.close()

        if not self.cancelled():
            self.emit(OcrEvent.completed(self.request.job_id))

    def _process_pdf_page(
        self,
        *,
        pdf: Any,
        page_number: int,
        total: int,
        dpi: int,
        out_dir: Path,
        pages_dir: Path,
        page_index_in_job: int,
    ) -> None:
        page = pdf[page_number - 1]
        warnings: list[dict[str, str]] = []
        force = self.request.should_force_ocr(page_number)

        self._emit_progress(page_number, total, "inspect_text_layer")
        width, height = page.get_size()
        area = float(width) * float(height)

        text_layer = ""
        try:
            textpage = page.get_textpage()
            try:
                text_layer = textpage.get_text_bounded() or ""
            finally:
                textpage.close()
        except Exception as exc:  # noqa: BLE001
            logger.warning("text layer read failed on page %s: %s", page_number, exc)
            text_layer = ""
            warnings.append({"code": "TEXT_LAYER_READ_FAILED", "message": str(exc)})

        usable, reason = text_layer_is_usable(text_layer, page_area_hint=area)
        use_text_layer = usable and not force

        image_relative: Optional[str] = None
        ocr_result: Optional[OcrResult] = None
        method: str
        final_text: str

        if use_text_layer:
            self._emit_progress(page_number, total, "extract_text")
            method = "text_layer"
            final_text = text_layer.strip()
        else:
            if force:
                self._emit_warning(
                    "FORCE_OCR",
                    "user requested OCR for this page",
                    page=page_number,
                )
                warnings.append({"code": "FORCE_OCR", "message": "forced"})
            elif reason:
                self._emit_warning(
                    reason,
                    f"text layer unusable ({reason}); rendering for OCR",
                    page=page_number,
                )
                warnings.append({"code": reason, "message": "fallback_to_ocr"})

            if self.cancelled():
                return

            self._emit_progress(page_number, total, "render")
            scale = dpi / 72.0
            bitmap = page.render(scale=scale)
            pil_image = bitmap.to_pil()
            image_name = page_image_filename(page_number)
            image_path = pages_dir / image_name
            pil_image.save(image_path, format="PNG")
            image_relative = f"pages/{image_name}"

            if self.cancelled():
                return

            self._emit_progress(page_number, total, "ocr")
            ocr_result = self.engine.run(
                str(image_path),
                language_hints=self.request.language_hints,
                page=page_number,
            )
            method = "ocr"
            final_text = ocr_result.text
            if ocr_result.mock:
                self._emit_warning(
                    "MOCK_ENGINE",
                    "OCR used mock engine (no PaddleOCR-VL weights / GPU)",
                    page=page_number,
                )
            if ocr_result.confidence < 0.55:
                self._emit_warning(
                    "LOW_CONFIDENCE",
                    f"page confidence {ocr_result.confidence:.3f}",
                    page=page_number,
                )

        # Always save page status immediately for crash-safe resume.
        payload = build_page_payload(
            page=page_number,
            method=method,
            text=final_text,
            ocr=ocr_result,
            warnings=warnings,
            image_relative_path=image_relative,
            language_hints=self.request.language_hints,
        )
        payload["page_index_in_job"] = page_index_in_job
        payload["dpi"] = dpi if method == "ocr" else None
        payload["text_layer_preview"] = text_layer[:500] if text_layer else ""

        result_file = page_result_filename(page_number)
        _atomic_write_json(out_dir / result_file, payload)
        self._emit_page_done(page_number, result_file)
