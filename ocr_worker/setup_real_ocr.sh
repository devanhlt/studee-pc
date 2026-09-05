#!/usr/bin/env bash
# Install a real PaddleOCR-VL environment for the Study Overlay OCR worker.
#
# When this script lives inside Studee.app, the venv is created in Application
# Support (writable) so the signed .app bundle is not modified.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

PYTHON_BIN="${PYTHON_BIN:-}"
if [[ -z "$PYTHON_BIN" ]]; then
  if command -v python3.12 >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python3.12)"
  elif command -v python3.11 >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python3.11)"
  else
    PYTHON_BIN="$(command -v python3)"
  fi
fi

# shellcheck disable=SC1091
source "$ROOT/_venv_path.sh"
VENV_DIR="$(ocr_worker_venv_dir "$ROOT")"
if [[ "$ROOT" == *".app/Contents/Resources/ocr_worker"* ]]; then
  echo "Packaged install detected."
  echo "Creating venv outside the .app at:"
  echo "  $VENV_DIR"
fi

echo "Using Python: $PYTHON_BIN ($("$PYTHON_BIN" --version 2>&1))"
"$PYTHON_BIN" -m venv "$VENV_DIR"
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
python -m pip install -U pip setuptools wheel

echo "Installing PaddlePaddle CPU…"
python -m pip install "paddlepaddle==3.2.1" \
  -i https://www.paddlepaddle.org.cn/packages/stable/cpu/

echo "Installing PaddleOCR (doc-parser) + PDF/image deps…"
python -m pip install -U "paddleocr[doc-parser]" pypdfium2 Pillow

# Optional Apple Silicon VLM acceleration (used when MLX server is running).
if [[ "$(uname -m)" == "arm64" && "$(uname -s)" == "Darwin" ]]; then
  echo "Installing mlx-vlm for Apple Silicon acceleration (optional)…"
  python -m pip install "mlx-vlm>=0.3.11" || echo "mlx-vlm install skipped/failed (CPU path still works)"
fi

python - <<'PY'
import paddle
print("paddle:", paddle.__version__)
from paddleocr import PaddleOCRVL
print("PaddleOCRVL import OK")
PY

# Marker so we know which worker scripts this venv pairs with.
if [[ "$VENV_DIR" != "$ROOT/.venv" ]]; then
  printf '%s\n' "$ROOT" > "$(dirname "$VENV_DIR")/worker_src.txt"
fi

echo
echo "Setup complete."
echo "Python: $VENV_DIR/bin/python"
echo "Worker scripts: $ROOT"
echo "Flutter launches: $VENV_DIR/bin/python -u $ROOT/main.py"
echo
echo "Next: ./warmup_models.sh"
