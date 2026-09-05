#!/usr/bin/env python3
"""
OCR worker entrypoint.

Reads JSON Lines requests from stdin; writes JSON Lines events to stdout.
Logs go to stderr only (never secrets). Never binds a network socket.
"""

from __future__ import annotations

import json
import logging
import sys
import threading
import traceback
from typing import Any, Optional, TextIO

from pdf_pipeline import PdfPipeline
from protocol import OcrEvent, OcrRequest, PROTOCOL_VERSION

# Ensure unbuffered-friendly stdout when launched without `python -u`.
try:
    sys.stdout.reconfigure(line_buffering=True)  # type: ignore[attr-defined]
    sys.stderr.reconfigure(line_buffering=True)  # type: ignore[attr-defined]
except Exception:  # noqa: BLE001
    pass

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("ocr_worker")


class WorkerRuntime:
    """Single-flight job runner with cooperative cancel."""

    def __init__(self, out: TextIO = sys.stdout) -> None:
        self._out = out
        self._out_lock = threading.Lock()
        self._job_lock = threading.Lock()
        self._active_job_id: Optional[str] = None
        self._cancel_event = threading.Event()
        self._worker_thread: Optional[threading.Thread] = None

    def emit(self, event: OcrEvent) -> None:
        line = json.dumps(event.to_dict(), ensure_ascii=False)
        with self._out_lock:
            self._out.write(line + "\n")
            self._out.flush()

    def handle_line(self, raw: str) -> None:
        raw = raw.strip()
        if not raw:
            return
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as exc:
            self.emit(
                OcrEvent.error(
                    job_id="unknown",
                    code="INVALID_JSON",
                    message=str(exc),
                )
            )
            return

        try:
            request = OcrRequest.from_dict(data)
        except ValueError as exc:
            job_id = str(data.get("job_id") or "unknown")
            self.emit(OcrEvent.error(job_id=job_id, code="INVALID_REQUEST", message=str(exc)))
            return

        if request.action == "cancel":
            self._cancel(request.job_id)
            return

        self._start_job(request)

    def _cancel(self, job_id: str) -> None:
        with self._job_lock:
            if self._active_job_id == job_id:
                logger.info("cancel requested for job_id=%s", job_id)
                self._cancel_event.set()
            else:
                logger.info(
                    "cancel for inactive job_id=%s (active=%s)",
                    job_id,
                    self._active_job_id,
                )

    def _start_job(self, request: OcrRequest) -> None:
        with self._job_lock:
            if self._worker_thread and self._worker_thread.is_alive():
                self.emit(
                    OcrEvent.error(
                        job_id=request.job_id,
                        code="BUSY",
                        message="another OCR job is still running",
                    )
                )
                return
            self._active_job_id = request.job_id
            self._cancel_event = threading.Event()
            thread = threading.Thread(
                target=self._run_job,
                args=(request, self._cancel_event),
                name=f"ocr-job-{request.job_id[:8]}",
                daemon=True,
            )
            self._worker_thread = thread
            thread.start()

    def _run_job(self, request: OcrRequest, cancel_event: threading.Event) -> None:
        logger.info(
            "start job_id=%s action=%s protocol=%s quality=%s hints=%s",
            request.job_id,
            request.action,
            request.protocol_version,
            request.quality,
            request.language_hints,
        )
        try:
            pipeline = PdfPipeline(request, self.emit, cancel_event)
            pipeline.run()
            if cancel_event.is_set():
                # Page outputs already flushed; signal terminal cancelled state.
                self.emit(
                    OcrEvent.error(
                        job_id=request.job_id,
                        code="CANCELLED",
                        message="job cancelled",
                    )
                )
        except FileNotFoundError as exc:
            logger.exception("job failed: missing input")
            self.emit(
                OcrEvent.error(
                    job_id=request.job_id,
                    code="INPUT_NOT_FOUND",
                    message=str(exc),
                )
            )
        except Exception as exc:  # noqa: BLE001 — surface to Flutter
            logger.error("job failed: %s\n%s", exc, traceback.format_exc())
            self.emit(
                OcrEvent.error(
                    job_id=request.job_id,
                    code="WORKER_ERROR",
                    message=str(exc),
                )
            )
        finally:
            with self._job_lock:
                if self._active_job_id == request.job_id:
                    self._active_job_id = None
            logger.info("finished job_id=%s", request.job_id)

    def wait_idle(self, timeout: Optional[float] = None) -> None:
        thread = self._worker_thread
        if thread and thread.is_alive():
            thread.join(timeout=timeout)


def main(argv: Optional[list[str]] = None) -> int:
    _ = argv
    logger.info(
        "ocr_worker starting protocol_version=%s (stdin/stdout JSONL; no network)",
        PROTOCOL_VERSION,
    )
    runtime = WorkerRuntime()
    try:
        for line in sys.stdin:
            runtime.handle_line(line)
    except KeyboardInterrupt:
        logger.info("interrupted")
        if runtime._active_job_id:
            runtime._cancel(runtime._active_job_id)
        runtime.wait_idle(timeout=5.0)
        return 130

    runtime.wait_idle()
    logger.info("ocr_worker exiting (stdin closed)")
    return 0


if __name__ == "__main__":
    # Guard: this process must never open listening sockets.
    # Inference backends that bind ports are unsupported for this worker.
    sys.exit(main())
