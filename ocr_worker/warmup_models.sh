#!/usr/bin/env bash
# Warm up / download PaddleOCR-VL models into the local cache (and optional bundle dir).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$ROOT/_venv_path.sh"
VENV_DIR="$(ocr_worker_venv_dir "$ROOT")"

if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
  echo "ERROR: OCR venv not found at:" >&2
  echo "  $VENV_DIR" >&2
  echo "Run ./setup_real_ocr.sh first." >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
echo "Using venv: $VENV_DIR"

# Prefer Application Support model dir for packaged installs (writable).
DEFAULT_BUNDLE="$ROOT/../assets/models/paddleocr-vl-1.6"
if [[ "$ROOT" == *".app/Contents/Resources/ocr_worker" ]]; then
  DEFAULT_BUNDLE="${HOME}/Library/Application Support/com.studee.studeePc/ApplicationData/models/paddleocr-vl-1.6"
fi
BUNDLE_DIR="${1:-$DEFAULT_BUNDLE}"
mkdir -p "$BUNDLE_DIR"

export PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True

python - <<PY
from pathlib import Path
import json

bundle = Path(r"""$BUNDLE_DIR""").resolve()
bundle.mkdir(parents=True, exist_ok=True)

from paddleocr import PaddleOCRVL

print("Loading PaddleOCRVL(device='cpu') — first run downloads models…")
pipeline = PaddleOCRVL(device="cpu")
# Touch a tiny prediction so weights are fully resolved.
from PIL import Image
img = bundle / "_warmup.png"
Image.new("RGB", (64, 64), (255, 255, 255)).save(img)
try:
    list(pipeline.predict(str(img)))
except Exception as exc:  # noqa: BLE001
    print("warmup predict warning:", type(exc).__name__, exc)

manifest = {
    "name": "paddleocr-vl-1.6",
    "version": "1.6",
    "bundled": True,
    "engine": "PaddleOCRVL",
    "device": "cpu",
    "note": "Weights cached by PaddleX/PaddleOCR; app resolves via model_dir + default cache.",
}
(bundle / "MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print("Wrote", bundle / "MANIFEST.json")
print("Real OCR ready.")
PY
