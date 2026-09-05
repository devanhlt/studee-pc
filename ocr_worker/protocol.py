"""JSONL protocol dataclasses for the OCR worker (protocol_version = 1)."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Literal, Optional

PROTOCOL_VERSION = 1

Action = Literal["parse_document", "parse_image", "cancel"]
EventType = Literal["progress", "page_completed", "warning", "completed", "error"]
Quality = Literal["highest", "balanced", "fast"]


@dataclass
class OcrRequest:
    """Inbound request line from Flutter (stdin JSONL)."""

    protocol_version: int
    job_id: str
    action: Action
    input_path: str = ""
    output_directory: str = ""
    pages: Optional[list[int]] = None
    language_hints: list[str] = field(default_factory=lambda: ["vi", "en"])
    quality: Quality = "highest"
    model_dir: Optional[str] = None
    force_ocr: bool | list[int] = False

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "OcrRequest":
        if not isinstance(data, dict):
            raise ValueError("request must be a JSON object")

        version = int(data.get("protocol_version", 0))
        if version != PROTOCOL_VERSION:
            raise ValueError(
                f"unsupported protocol_version={version}; expected {PROTOCOL_VERSION}"
            )

        job_id = data.get("job_id")
        if not job_id or not isinstance(job_id, str):
            raise ValueError("job_id is required")

        action = data.get("action")
        if action not in ("parse_document", "parse_image", "cancel"):
            raise ValueError(f"unsupported action: {action!r}")

        pages = data.get("pages")
        if pages is not None:
            if not isinstance(pages, list) or not all(isinstance(p, int) for p in pages):
                raise ValueError("pages must be a list of ints (1-based)")
            if any(p < 1 for p in pages):
                raise ValueError("pages must be 1-based positive integers")

        language_hints = data.get("language_hints") or ["vi", "en"]
        if not isinstance(language_hints, list) or not all(
            isinstance(x, str) for x in language_hints
        ):
            raise ValueError("language_hints must be a list of strings")

        quality = data.get("quality") or "highest"
        if quality not in ("highest", "balanced", "fast"):
            quality = "highest"

        force_ocr = data.get("force_ocr", False)
        if not isinstance(force_ocr, (bool, list)):
            raise ValueError("force_ocr must be bool or list of page ints")
        if isinstance(force_ocr, list) and not all(isinstance(p, int) for p in force_ocr):
            raise ValueError("force_ocr list must contain ints")

        model_dir = data.get("model_dir")
        if model_dir is not None and not isinstance(model_dir, str):
            raise ValueError("model_dir must be a string path")

        input_path = data.get("input_path") or ""
        output_directory = data.get("output_directory") or ""

        if action != "cancel":
            if not input_path:
                raise ValueError("input_path is required")
            if not output_directory:
                raise ValueError("output_directory is required")

        return cls(
            protocol_version=version,
            job_id=job_id,
            action=action,  # type: ignore[arg-type]
            input_path=input_path,
            output_directory=output_directory,
            pages=pages,
            language_hints=list(language_hints),
            quality=quality,  # type: ignore[arg-type]
            model_dir=model_dir,
            force_ocr=force_ocr,
        )

    def should_force_ocr(self, page: int) -> bool:
        if self.force_ocr is True:
            return True
        if isinstance(self.force_ocr, list):
            return page in self.force_ocr
        return False


@dataclass
class OcrEvent:
    """Outbound event line to Flutter (stdout JSONL)."""

    job_id: str
    type: EventType
    page: Optional[int] = None
    total_pages: Optional[int] = None
    stage: Optional[str] = None
    result_path: Optional[str] = None
    code: Optional[str] = None
    message: Optional[str] = None

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {"job_id": self.job_id, "type": self.type}
        if self.page is not None:
            payload["page"] = self.page
        if self.total_pages is not None:
            payload["total_pages"] = self.total_pages
        if self.stage is not None:
            payload["stage"] = self.stage
        if self.result_path is not None:
            payload["result_path"] = self.result_path
        if self.code is not None:
            payload["code"] = self.code
        if self.message is not None:
            payload["message"] = self.message
        return payload

    @classmethod
    def progress(
        cls, job_id: str, page: int, total_pages: int, stage: str
    ) -> "OcrEvent":
        return cls(
            job_id=job_id,
            type="progress",
            page=page,
            total_pages=total_pages,
            stage=stage,
        )

    @classmethod
    def page_completed(cls, job_id: str, page: int, result_path: str) -> "OcrEvent":
        return cls(
            job_id=job_id,
            type="page_completed",
            page=page,
            result_path=result_path,
        )

    @classmethod
    def warning(
        cls,
        job_id: str,
        code: str,
        message: Optional[str] = None,
        page: Optional[int] = None,
    ) -> "OcrEvent":
        return cls(
            job_id=job_id,
            type="warning",
            page=page,
            code=code,
            message=message,
        )

    @classmethod
    def completed(cls, job_id: str) -> "OcrEvent":
        return cls(job_id=job_id, type="completed")

    @classmethod
    def error(
        cls, job_id: str, code: str, message: Optional[str] = None
    ) -> "OcrEvent":
        return cls(job_id=job_id, type="error", code=code, message=message)


def event_to_jsonable(event: OcrEvent) -> dict[str, Any]:
    """Serialize an event; drops None fields via to_dict()."""
    return event.to_dict()


def request_debug_dict(request: OcrRequest) -> dict[str, Any]:
    """Safe request summary for stderr logs (no secrets expected)."""
    data = asdict(request)
    return data
