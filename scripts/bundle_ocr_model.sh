#!/usr/bin/env bash
# Package PaddleOCR-VL 1.6 weights into assets/models for release builds.
# Development uses the stub MANIFEST.json + mock OCR engine.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/assets/models/paddleocr-vl-1.6"
mkdir -p "$DEST"

echo "Bundle target: $DEST"
if [[ -n "${PADDLEOCR_VL_SOURCE:-}" && -d "$PADDLEOCR_VL_SOURCE" ]]; then
  rsync -a --delete "$PADDLEOCR_VL_SOURCE/" "$DEST/"
  echo "Copied weights from $PADDLEOCR_VL_SOURCE"
else
  echo "No PADDLEOCR_VL_SOURCE set — keeping stub MANIFEST for development."
  echo "Set PADDLEOCR_VL_SOURCE=/path/to/weights before release packaging."
fi

if command -v shasum >/dev/null 2>&1; then
  CHECKSUM="$(find "$DEST" -type f ! -name 'MANIFEST.json' -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')"
else
  CHECKSUM="placeholder-dev"
fi

cat > "$DEST/MANIFEST.json" <<EOF
{
  "name": "paddleocr-vl-1.6",
  "version": "1.6",
  "bundled": true,
  "checksum_sha256": "$CHECKSUM",
  "note": "Packaged by scripts/bundle_ocr_model.sh. Users never download this."
}
EOF
echo "Wrote MANIFEST.json checksum=$CHECKSUM"
