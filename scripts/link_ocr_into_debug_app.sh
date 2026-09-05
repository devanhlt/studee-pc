#!/usr/bin/env bash
# Link bundled OCR runtime into the Debug .app so `flutter run -d macos`
# can find python + models without installing the DMG.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEBUG_RES="$ROOT/build/macos/Build/Products/Debug/studee_pc.app/Contents/Resources"
BUNDLE="$ROOT/build/ocr_bundle"

if [[ ! -d "$DEBUG_RES" ]]; then
  echo "Debug app not found. Run: flutter build macos --debug" >&2
  echo "  (or flutter run -d macos once)" >&2
  exit 1
fi

if [[ ! -x "$BUNDLE/python/bin/python3" ]]; then
  echo "OCR bundle missing. Run: ./scripts/prepare_ocr_bundle.sh" >&2
  exit 1
fi

ln -sfn "$BUNDLE" "$DEBUG_RES/ocr_runtime"
ln -sfn "$ROOT/ocr_worker" "$DEBUG_RES/ocr_worker"
echo "Linked OCR into Debug Resources:"
ls -la "$DEBUG_RES/ocr_runtime" "$DEBUG_RES/ocr_worker"
