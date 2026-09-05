#!/usr/bin/env bash
# Build a relocatable OCR runtime for packaging into Studee.app:
#   build/ocr_bundle/python/          — standalone CPython + site-packages
#   build/ocr_bundle/paddlex_cache/   — offline PaddleX official models
#
# Usage:
#   ./scripts/prepare_ocr_bundle.sh
#   FORCE=1 ./scripts/prepare_ocr_bundle.sh          # rebuild even if present
#   SKIP_PIP=1 ./scripts/prepare_ocr_bundle.sh       # only refresh models
#
# Requires network on first run (Python tarball + optional pip). Prefer an
# existing working OCR venv via OCR_SRC_VENV to copy packages quickly.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/ocr_bundle"
PY_DIR="$OUT/python"
CACHE_DIR="$OUT/paddlex_cache"
ARCH="$(uname -m)"
TAG="${PBS_TAG:-20260901}"
PY_VER="${PBS_PY_VER:-3.12.14}"

case "$ARCH" in
  arm64) TRIPLE="aarch64-apple-darwin" ;;
  x86_64) TRIPLE="x86_64-apple-darwin" ;;
  *)
    echo "ERROR: unsupported arch $ARCH" >&2
    exit 1
    ;;
esac

ASSET="cpython-${PY_VER}+${TAG}-${TRIPLE}-install_only_stripped.tar.gz"
URL="https://github.com/astral-sh/python-build-standalone/releases/download/${TAG}/${ASSET}"

SRC_VENV="${OCR_SRC_VENV:-}"
if [[ -z "$SRC_VENV" ]]; then
  for candidate in \
    "$HOME/Library/Application Support/com.studee.studeePc/ocr_runtime/.venv" \
    "$ROOT/ocr_worker/.venv"
  do
    if [[ -x "$candidate/bin/python" || -L "$candidate/bin/python" ]]; then
      SRC_VENV="$candidate"
      break
    fi
  done
fi

MODELS_SRC="${OCR_MODELS_SRC:-$HOME/.paddlex/official_models}"

echo "==> OCR bundle output: $OUT"
mkdir -p "$OUT"

need_python=0
if [[ "${FORCE:-0}" == "1" ]]; then
  need_python=1
elif [[ ! -x "$PY_DIR/bin/python3" ]]; then
  need_python=1
fi

if [[ "$need_python" == "1" ]]; then
  echo "==> Downloading standalone Python: $ASSET"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  curl -fL --retry 3 -o "$TMP/$ASSET" "$URL"
  rm -rf "$PY_DIR"
  mkdir -p "$OUT"
  tar -xzf "$TMP/$ASSET" -C "$TMP"
  # tarball contains top-level "python/"
  if [[ -d "$TMP/python" ]]; then
    mv "$TMP/python" "$PY_DIR"
  else
    echo "ERROR: unexpected tarball layout" >&2
    exit 1
  fi
  # Make the tree movable: prefer relative @loader_path style is already in PBS.
  "$PY_DIR/bin/python3" -V
fi

if [[ "${SKIP_PIP:-0}" != "1" ]]; then
  PY="$PY_DIR/bin/python3"
  if [[ ! -x "$PY" ]]; then
    echo "ERROR: missing $PY" >&2
    exit 1
  fi

  echo "==> Ensuring pip on bundled Python…"
  "$PY" -m ensurepip --upgrade >/dev/null
  "$PY" -m pip install -U pip setuptools wheel

  if [[ -n "$SRC_VENV" && -d "$SRC_VENV/lib/python3.12/site-packages" ]]; then
    echo "==> Copying site-packages from: $SRC_VENV"
    echo "    (excluding mlx* to keep CPU-only / smaller bundle)"
    DEST_SP="$PY_DIR/lib/python3.12/site-packages"
    mkdir -p "$DEST_SP"
    rsync -a --delete \
      --exclude 'mlx' \
      --exclude 'mlx-*' \
      --exclude 'mlx_*' \
      --exclude 'mlx_vlm*' \
      --exclude 'mlx_audio*' \
      --exclude '__pycache__' \
      --exclude '*.pyc' \
      "$SRC_VENV/lib/python3.12/site-packages/" \
      "$DEST_SP/"
  else
    echo "==> No source venv — pip installing PaddleOCR (slow)…"
    "$PY" -m pip install "paddlepaddle==3.2.1" \
      -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
    "$PY" -m pip install -U "paddleocr[doc-parser]" pypdfium2 Pillow
  fi

  echo "==> Verifying imports…"
  "$PY" - <<'PY'
import paddle
from paddleocr import PaddleOCRVL
print("paddle", paddle.__version__, "PaddleOCRVL OK")
PY
fi

echo "==> Bundling PaddleX official models…"
mkdir -p "$CACHE_DIR/official_models"
for name in PaddleOCR-VL-1.6 PP-DocLayoutV3; do
  src="$MODELS_SRC/$name"
  dst="$CACHE_DIR/official_models/$name"
  if [[ ! -d "$src" ]]; then
    echo "ERROR: missing model cache $src" >&2
    echo "Run ocr_worker/warmup_models.sh once on this machine first." >&2
    exit 1
  fi
  echo "    $name"
  rsync -a --delete --exclude '__pycache__' "$src/" "$dst/"
done

# Marker for the app / packaging script
cat > "$OUT/BUNDLE_INFO.txt" <<EOF
arch=$ARCH
python=$PY_VER
tag=$TAG
built=$(date -u +%Y-%m-%dT%H:%M:%SZ)
paddlex_cache=paddlex_cache
EOF

echo
echo "Done."
du -sh "$OUT" "$PY_DIR" "$CACHE_DIR" | sed 's/^/  /'
echo
echo "Next: ./scripts/package_macos_dmg.sh"
echo "DMG will be large (~2–4 GB) because OCR runtime + models are included."
