#!/usr/bin/env bash
# Launch the OCR worker with unbuffered stdout/stderr for JSONL streaming.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source "$ROOT/_venv_path.sh"
VENV_DIR="$(ocr_worker_venv_dir "$ROOT")"
if [[ -x "$VENV_DIR/bin/python" || -L "$VENV_DIR/bin/python" ]]; then
  export PYTHONPATH="$ROOT${PYTHONPATH:+:$PYTHONPATH}"
  exec "$VENV_DIR/bin/python" -u main.py "$@"
fi
exec python3 -u main.py "$@"
