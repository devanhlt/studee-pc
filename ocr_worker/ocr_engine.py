"""PaddleOCR-VL wrapper with deterministic mock fallback for development/CI."""

from __future__ import annotations

import hashlib
import json
import logging
import os
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Optional, Protocol

logger = logging.getLogger("ocr_worker.engine")

MODEL_NAME = "paddleocr-vl"
MODEL_VERSION = "1.6"
MOCK_ENGINE_NAME = "paddleocr-vl-mock"
CLASSIC_ENGINE_NAME = "paddleocr-latin"


@dataclass
class OcrBlock:
    text: str
    bbox: list[float]  # [x0, y0, x1, y1] in image pixels
    confidence: float
    label: str = "text"

    def to_dict(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "bbox": self.bbox,
            "confidence": self.confidence,
            "label": self.label,
        }


@dataclass
class OcrResult:
    text: str
    blocks: list[OcrBlock]
    confidence: float
    engine: str
    model_name: str
    model_version: str
    mock: bool
    language_hints: list[str] = field(default_factory=lambda: ["vi", "en"])
    raw: dict[str, Any] = field(default_factory=dict)
    metadata: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "blocks": [b.to_dict() for b in self.blocks],
            "confidence": self.confidence,
            "engine": self.engine,
            "model_name": self.model_name,
            "model_version": self.model_version,
            "mock": self.mock,
            "language_hints": list(self.language_hints),
            "raw": self.raw,
            "metadata": self.metadata,
        }


class OcrEngine(Protocol):
    def run(
        self,
        image_path: str,
        *,
        language_hints: list[str],
        page: int = 1,
    ) -> OcrResult: ...


def _read_manifest(model_dir: Optional[str]) -> dict[str, Any]:
    if not model_dir:
        return {}
    manifest_path = Path(model_dir) / "MANIFEST.json"
    if not manifest_path.is_file():
        return {}
    try:
        return json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        logger.warning("failed to read model manifest: %s", exc)
        return {}


def _weights_look_present(model_dir: Path) -> bool:
    """Heuristic: real bundles include weight files beyond MANIFEST.json."""
    if not model_dir.is_dir():
        return False
    weight_suffixes = {
        ".pdiparams",
        ".pdmodel",
        ".json",
        ".yml",
        ".yaml",
        ".safetensors",
        ".bin",
        ".pdparams",
        ".onnx",
    }
    for path in model_dir.rglob("*"):
        if not path.is_file():
            continue
        if path.name in {"MANIFEST.json", "_warmup.png"}:
            continue
        if path.suffix.lower() in weight_suffixes and path.stat().st_size > 1024:
            return True
    return False


def _mlx_server_reachable(url: str = "http://127.0.0.1:8111") -> bool:
    try:
        with urllib.request.urlopen(url, timeout=0.4) as resp:
            return 200 <= getattr(resp, "status", 200) < 500
    except (urllib.error.URLError, TimeoutError, OSError):
        return False


class MockOcrEngine:
    """Deterministic CPU-only mock so Flutter can integrate without GPU/weights."""

    def __init__(self, model_dir: Optional[str] = None) -> None:
        self.model_dir = model_dir
        self.manifest = _read_manifest(model_dir)

    def run(
        self,
        image_path: str,
        *,
        language_hints: list[str],
        page: int = 1,
    ) -> OcrResult:
        path = Path(image_path)
        digest = hashlib.sha256()
        try:
            digest.update(path.read_bytes())
        except OSError:
            digest.update(image_path.encode("utf-8"))
        digest.update(f":{page}".encode("utf-8"))
        seed = digest.hexdigest()

        lines = [
            f"[MOCK OCR] Trang {page} — PaddleOCR-VL {MODEL_VERSION} (mock)",
            "Câu hỏi mẫu: Đạo hàm của hàm số f(x) = x² là gì?",
            "A. 2x",
            "B. x",
            "C. x²",
            "D. 2",
            "Sample English line: Select the correct derivative.",
            f"fingerprint={seed[:12]}",
        ]
        if "vi" in language_hints:
            lines.insert(1, "Hỗ trợ tiếng Việt: giữ nguyên dấu thanh (ă â ê ô ơ ư).")

        blocks: list[OcrBlock] = []
        y = 40.0
        confidences: list[float] = []
        for i, line in enumerate(lines):
            conf = 0.72 + (int(seed[i % len(seed)], 16) % 20) / 100.0
            confidences.append(conf)
            blocks.append(
                OcrBlock(
                    text=line,
                    bbox=[48.0, y, 720.0, y + 28.0],
                    confidence=round(conf, 4),
                    label="text",
                )
            )
            y += 36.0

        avg = sum(confidences) / len(confidences) if confidences else 0.0
        text = "\n".join(lines)
        return OcrResult(
            text=text,
            blocks=blocks,
            confidence=round(avg, 4),
            engine=MOCK_ENGINE_NAME,
            model_name=MODEL_NAME,
            model_version=MODEL_VERSION,
            mock=True,
            language_hints=list(language_hints),
            raw={"lines": lines, "seed": seed},
            metadata={
                "mock": True,
                "mock_reason": "paddleocr_vl_unavailable_or_stub_bundle",
                "image_path": str(path),
                "model_dir": self.model_dir,
                "manifest": self.manifest,
            },
        )


class PaddleOcrVlEngine:
    """Thin wrapper around paddleocr PaddleOCRVL (CPU / optional MLX server)."""

    def __init__(
        self,
        model_dir: Optional[str] = None,
        *,
        backend: str = "cpu",
    ) -> None:
        self.model_dir = model_dir
        self.manifest = _read_manifest(model_dir)
        self.backend = backend
        self._pipeline = self._load_pipeline(model_dir, backend=backend)
        self._engine_name = MODEL_NAME

    @staticmethod
    def _load_pipeline(model_dir: Optional[str], *, backend: str) -> Any:
        try:
            from paddleocr import PaddleOCRVL  # type: ignore
        except ImportError as exc:
            raise RuntimeError("paddleocr PaddleOCRVL is not installed") from exc

        kwargs: dict[str, Any] = {"device": "cpu"}
        if backend == "mlx":
            kwargs["vl_rec_backend"] = "mlx-vlm-server"
            kwargs["vl_rec_server_url"] = os.environ.get(
                "PADDLEOCR_VL_MLX_URL", "http://127.0.0.1:8111"
            )

        # Prefer local bundle when real weights exist; otherwise let PaddleX cache.
        if model_dir and _weights_look_present(Path(model_dir)):
            for key in ("vl_rec_model_dir", "model_dir"):
                try:
                    return PaddleOCRVL(**{**kwargs, key: model_dir})
                except TypeError:
                    continue
                except Exception as exc:  # noqa: BLE001
                    logger.warning("PaddleOCRVL(%s=…) failed: %s", key, exc)

        try:
            return PaddleOCRVL(**kwargs)
        except TypeError:
            # Older signatures without device=
            kwargs.pop("device", None)
            return PaddleOCRVL(**kwargs)

    def run(
        self,
        image_path: str,
        *,
        language_hints: list[str],
        page: int = 1,
    ) -> OcrResult:
        pipeline = self._pipeline
        raw_out: Any
        try:
            raw_out = pipeline.predict(image_path)
        except AttributeError:
            raw_out = pipeline.ocr(image_path)

        # PaddleOCRVL may return a generator / list of result objects.
        if hasattr(raw_out, "__iter__") and not isinstance(raw_out, (list, tuple, dict, str)):
            try:
                raw_out = list(raw_out)
            except TypeError:
                pass

        blocks, text_parts, confidences = _normalize_paddle_output(raw_out)
        text = "\n".join(text_parts)
        avg = sum(confidences) / len(confidences) if confidences else 0.0
        checksum = self.manifest.get("checksum_sha256")
        return OcrResult(
            text=text,
            blocks=blocks,
            confidence=round(avg, 4) if confidences else 0.9,
            engine=self._engine_name,
            model_name=MODEL_NAME,
            model_version=str(self.manifest.get("version") or MODEL_VERSION),
            mock=False,
            language_hints=list(language_hints),
            raw={"paddle": _json_safe_ocr(raw_out)},
            metadata={
                "mock": False,
                "page": page,
                "backend": self.backend,
                "model_dir": self.model_dir,
                "checksum_sha256": checksum,
                "quantization": self.manifest.get("quantization"),
            },
        )


class ClassicPaddleOcrEngine:
    """PP-OCR latin pipeline — solid Vietnamese Latin OCR on Apple Silicon CPU."""

    def __init__(self, model_dir: Optional[str] = None) -> None:
        self.model_dir = model_dir
        self.manifest = _read_manifest(model_dir)
        try:
            from paddleocr import PaddleOCR  # type: ignore
        except ImportError as exc:
            raise RuntimeError("paddleocr is not installed") from exc

        kwargs: dict[str, Any] = {
            "lang": "latin",
            "use_angle_cls": True,
            "show_log": False,
        }
        # Prefer new API when available.
        try:
            self._pipeline = PaddleOCR(lang="latin")
        except TypeError:
            self._pipeline = PaddleOCR(**kwargs)

    def run(
        self,
        image_path: str,
        *,
        language_hints: list[str],
        page: int = 1,
    ) -> OcrResult:
        pipeline = self._pipeline
        try:
            raw_out = pipeline.predict(image_path)
        except AttributeError:
            raw_out = pipeline.ocr(image_path)

        if hasattr(raw_out, "__iter__") and not isinstance(raw_out, (list, tuple, dict, str)):
            try:
                raw_out = list(raw_out)
            except TypeError:
                pass

        blocks, text_parts, confidences = _normalize_paddle_output(raw_out)
        text = "\n".join(text_parts)
        avg = sum(confidences) / len(confidences) if confidences else 0.0
        return OcrResult(
            text=text,
            blocks=blocks,
            confidence=round(avg, 4) if confidences else 0.85,
            engine=CLASSIC_ENGINE_NAME,
            model_name="paddleocr",
            model_version="ppocr",
            mock=False,
            language_hints=list(language_hints),
            raw={"paddle": _json_safe_ocr(raw_out)},
            metadata={
                "mock": False,
                "page": page,
                "backend": "classic-latin",
                "model_dir": self.model_dir,
                "fallback_from": "paddleocr-vl",
            },
        )


def _json_safe(value: Any) -> Any:
    try:
        json.dumps(value)
        return value
    except TypeError:
        return repr(value)


def _json_safe_ocr(value: Any) -> Any:
    """Serialize OCR results without dumping image arrays."""
    if value is None:
        return None
    if isinstance(value, (list, tuple)):
        return [_json_safe_ocr(v) for v in value]
    if hasattr(value, "json"):
        try:
            candidate = value.json
            data = candidate() if callable(candidate) else candidate
            return _strip_heavy_fields(_json_safe(data))
        except Exception:  # noqa: BLE001
            pass
    if isinstance(value, dict):
        return _strip_heavy_fields(_json_safe(value))
    return _json_safe(value)


def _strip_heavy_fields(value: Any) -> Any:
    if not isinstance(value, dict):
        return value
    out: dict[str, Any] = {}
    skip = {"output_img", "doc_preprocessor_res", "input_img", "img"}
    for k, v in value.items():
        if k in skip:
            continue
        if isinstance(v, dict):
            out[k] = _strip_heavy_fields(v)
        elif isinstance(v, list) and v and isinstance(v[0], dict):
            out[k] = [_strip_heavy_fields(x) if isinstance(x, dict) else x for x in v]
        else:
            try:
                json.dumps(v)
                out[k] = v
            except TypeError:
                out[k] = repr(v)[:500]
    return out


def _coerce_page_dict(page: Any) -> Optional[dict[str, Any]]:
    """Normalize PaddleOCRVLResult / nested {res:…} into a plain result dict."""
    if page is None:
        return None

    markdown_fallback: Optional[str] = None
    if hasattr(page, "markdown"):
        try:
            md = page.markdown
            md = md() if callable(md) else md
            if isinstance(md, dict):
                mt = md.get("markdown_texts") or md.get("markdown_text")
                if isinstance(mt, str) and mt.strip():
                    markdown_fallback = mt.strip()
                elif isinstance(mt, list):
                    markdown_fallback = "\n".join(str(x) for x in mt if str(x).strip())
            elif isinstance(md, str) and md.strip():
                markdown_fallback = md.strip()
        except Exception:  # noqa: BLE001
            pass

    if hasattr(page, "json"):
        try:
            candidate = page.json
            page = candidate() if callable(candidate) else candidate
        except Exception:  # noqa: BLE001
            pass

    if isinstance(page, dict) and "res" in page and isinstance(page["res"], dict):
        page = page["res"]

    if hasattr(page, "res") and not isinstance(page, dict):
        try:
            page = page.res
        except Exception:  # noqa: BLE001
            pass

    if isinstance(page, dict):
        if markdown_fallback and not page.get("_markdown_fallback"):
            page = {**page, "_markdown_fallback": markdown_fallback}
        return page
    return None


def _append_block(
    blocks: list[OcrBlock],
    texts: list[str],
    confidences: list[float],
    *,
    text: str,
    bbox: Any,
    confidence: float,
    label: str = "text",
) -> None:
    text_s = text.strip()
    if not text_s:
        return
    blocks.append(
        OcrBlock(
            text=text_s,
            bbox=_flatten_bbox(bbox),
            confidence=float(confidence),
            label=label,
        )
    )
    texts.append(text_s)
    confidences.append(float(confidence))


def _normalize_paddle_output(raw_out: Any) -> tuple[list[OcrBlock], list[str], list[float]]:
    blocks: list[OcrBlock] = []
    texts: list[str] = []
    confidences: list[float] = []

    pages = raw_out
    if pages is None:
        return blocks, texts, confidences
    if isinstance(pages, dict):
        pages = [pages]
    if not isinstance(pages, (list, tuple)):
        pages = [pages]

    for page in pages:
        if page is None:
            continue

        page_dict = _coerce_page_dict(page)
        if page_dict is not None:
            # Newer PP-OCR predict dict shape.
            if "rec_texts" in page_dict and isinstance(page_dict.get("rec_texts"), list):
                rec_texts = page_dict.get("rec_texts") or []
                rec_scores = page_dict.get("rec_scores") or []
                rec_boxes = page_dict.get("rec_boxes") or page_dict.get("dt_polys") or []
                for i, text in enumerate(rec_texts):
                    conf = float(rec_scores[i]) if i < len(rec_scores) else 0.85
                    box = rec_boxes[i] if i < len(rec_boxes) else [0, 0, 0, 0]
                    _append_block(
                        blocks, texts, confidences, text=str(text), bbox=box, confidence=conf
                    )
                if texts:
                    continue

            parsing = page_dict.get("parsing_res_list")
            if isinstance(parsing, list) and parsing:
                for item in parsing:
                    if not isinstance(item, dict):
                        continue
                    text = str(
                        item.get("block_content")
                        or item.get("text")
                        or item.get("content")
                        or ""
                    )
                    bbox = (
                        item.get("block_bbox")
                        or item.get("bbox")
                        or item.get("box")
                        or item.get("coordinate")
                        or [0, 0, 0, 0]
                    )
                    label = str(item.get("block_label") or item.get("label") or "text")
                    conf = float(item.get("confidence") or item.get("score") or 0.9)
                    _append_block(
                        blocks,
                        texts,
                        confidences,
                        text=text,
                        bbox=bbox,
                        confidence=conf,
                        label=label,
                    )
                if texts:
                    continue

            md = page_dict.get("_markdown_fallback")
            if isinstance(md, str) and md.strip():
                _append_block(
                    blocks, texts, confidences, text=md, bbox=[0, 0, 0, 0], confidence=0.9
                )
                continue

        if not isinstance(page, (list, tuple)):
            continue
        for item in page:
            if not item:
                continue
            if isinstance(item, (list, tuple)) and len(item) >= 2:
                box, meta = item[0], item[1]
                if isinstance(meta, (list, tuple)) and len(meta) >= 2:
                    text, conf = str(meta[0]), float(meta[1])
                elif isinstance(meta, dict):
                    text = str(meta.get("text") or "")
                    conf = float(meta.get("confidence") or meta.get("score") or 0.0)
                else:
                    continue
                _append_block(
                    blocks, texts, confidences, text=text, bbox=box, confidence=conf
                )
    return blocks, texts, confidences


def _flatten_bbox(box: Any) -> list[float]:
    if box is None:
        return [0.0, 0.0, 0.0, 0.0]
    if isinstance(box, (list, tuple)) and box and isinstance(box[0], (list, tuple)):
        xs = [float(p[0]) for p in box]
        ys = [float(p[1]) for p in box]
        return [min(xs), min(ys), max(xs), max(ys)]
    if isinstance(box, (list, tuple)) and len(box) >= 4:
        # Flat [x0,y0,x1,y1] or polygon flattened
        nums = [float(x) for x in box]
        if len(nums) == 4:
            return nums
        xs = nums[0::2]
        ys = nums[1::2]
        return [min(xs), min(ys), max(xs), max(ys)]
    # numpy arrays
    try:
        import numpy as np  # type: ignore

        if isinstance(box, np.ndarray):
            flat = box.astype(float).reshape(-1)
            if flat.size >= 4:
                xs = flat[0::2]
                ys = flat[1::2]
                return [float(xs.min()), float(ys.min()), float(xs.max()), float(ys.max())]
    except Exception:  # noqa: BLE001
        pass
    return [0.0, 0.0, 0.0, 0.0]


def create_engine(
    model_dir: Optional[str],
    *,
    force_mock: bool = False,
) -> OcrEngine:
    """
    Prefer real PaddleOCR-VL (CPU, optional MLX server). Fall back to classic
    PP-OCR latin, then mock.
    """
    env_force = os.environ.get("OCR_WORKER_FORCE_MOCK", "").strip().lower() in {
        "1",
        "true",
        "yes",
    }
    if force_mock or env_force:
        logger.info("using mock OCR engine (forced)")
        return MockOcrEngine(model_dir)

    # Allow env override for model dir when request omits it.
    if not model_dir:
        model_dir = os.environ.get("PADDLEOCR_VL_MODEL_DIR") or None

    prefer_classic = os.environ.get("OCR_WORKER_PREFER_CLASSIC", "").strip().lower() in {
        "1",
        "true",
        "yes",
    }

    if not prefer_classic:
        backend = "cpu"
        if os.environ.get("OCR_WORKER_USE_MLX", "").strip().lower() in {"1", "true", "yes"}:
            if _mlx_server_reachable(
                os.environ.get("PADDLEOCR_VL_MLX_URL", "http://127.0.0.1:8111")
            ):
                backend = "mlx"
                logger.info("MLX VLM server detected; using mlx-vlm-server backend")
        try:
            engine = PaddleOcrVlEngine(model_dir, backend=backend)
            logger.info("loaded PaddleOCR-VL backend=%s model_dir=%s", backend, model_dir)
            return engine
        except Exception as exc:  # noqa: BLE001
            logger.warning("PaddleOCR-VL unavailable (%s); trying classic PP-OCR", exc)

    try:
        engine = ClassicPaddleOcrEngine(model_dir)
        logger.info("loaded classic PaddleOCR (latin) as real OCR engine")
        return engine
    except Exception as exc:  # noqa: BLE001
        logger.warning("classic PaddleOCR unavailable (%s); using mock", exc)
        return MockOcrEngine(model_dir)
