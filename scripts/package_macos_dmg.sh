#!/usr/bin/env bash
# Build a macOS release .app and wrap it in a distributable DMG.
#
# Includes a self-contained OCR runtime (Python + PaddleOCR + models) by
# default so end users do not need Homebrew / pip / warmup scripts.
#
# Usage:
#   ./scripts/package_macos_dmg.sh
#   SKIP_BUILD=1 ./scripts/package_macos_dmg.sh
#   SKIP_OCR_BUNDLE=1 ./scripts/package_macos_dmg.sh   # slim app (OCR setup required)
#   PREPARE_OCR=1 ./scripts/package_macos_dmg.sh       # run prepare_ocr_bundle.sh first
#
# Output: dist/Studee-<version>-macos.dmg
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)"
BUILD_NUM="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f2)"
APP_SRC="$ROOT/build/macos/Build/Products/Release/studee_pc.app"
STAGE="$ROOT/dist/dmg_stage"
APP_NAME="Studee.app"
DMG_NAME="Studee-${VERSION}-macos.dmg"
DMG_PATH="$ROOT/dist/$DMG_NAME"
VOLUME_NAME="Studee ${VERSION}"
OCR_BUNDLE="$ROOT/build/ocr_bundle"

if [[ "${PREPARE_OCR:-0}" == "1" ]]; then
  echo "==> Preparing OCR bundle…"
  "$ROOT/scripts/prepare_ocr_bundle.sh"
fi

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "==> Building macOS release (v${VERSION}+${BUILD_NUM})..."
  flutter pub get
  flutter build macos --release
else
  echo "==> SKIP_BUILD=1 — using existing Release app"
fi

if [[ ! -d "$APP_SRC" ]]; then
  echo "ERROR: Release app not found at $APP_SRC" >&2
  exit 1
fi

echo "==> Staging ${APP_NAME}..."
rm -rf "$STAGE"
mkdir -p "$STAGE"
ditto "$APP_SRC" "$STAGE/$APP_NAME"

RESOURCES="$STAGE/$APP_NAME/Contents/Resources"
mkdir -p "$RESOURCES"

echo "==> Bundling ocr_worker scripts…"
RSYNC_EXCLUDES=(
  --exclude '.venv'
  --exclude '__pycache__'
  --exclude '*.pyc'
  --exclude '.pytest_cache'
  --exclude '.mypy_cache'
  --exclude 'tests'
)
rsync -a "${RSYNC_EXCLUDES[@]}" "$ROOT/ocr_worker/" "$RESOURCES/ocr_worker/"

INCLUDE_OCR=1
if [[ "${SKIP_OCR_BUNDLE:-0}" == "1" ]]; then
  INCLUDE_OCR=0
fi

if [[ "$INCLUDE_OCR" == "1" ]]; then
  if [[ ! -x "$OCR_BUNDLE/python/bin/python3" ]]; then
    echo "ERROR: OCR runtime bundle missing at $OCR_BUNDLE" >&2
    echo "Run: ./scripts/prepare_ocr_bundle.sh" >&2
    echo "Or package a slim app with: SKIP_OCR_BUNDLE=1 $0" >&2
    exit 1
  fi
  if [[ ! -d "$OCR_BUNDLE/paddlex_cache/official_models/PaddleOCR-VL-1.6" ]]; then
    echo "ERROR: OCR models missing under $OCR_BUNDLE/paddlex_cache" >&2
    echo "Run: ./scripts/prepare_ocr_bundle.sh" >&2
    exit 1
  fi
  echo "==> Bundling self-contained OCR runtime + models (large)…"
  rsync -a --delete \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    "$OCR_BUNDLE/" "$RESOURCES/ocr_runtime/"
  # Drop build marker noise from app if any temp files appear
  rm -f "$RESOURCES/ocr_runtime/"*.tar.gz 2>/dev/null || true
else
  echo "==> SKIP_OCR_BUNDLE=1 — users must run setup_real_ocr.sh"
fi

if [[ "$INCLUDE_OCR" == "1" ]]; then
  cat > "$STAGE/HOW_TO_INSTALL.txt" <<EOF
Studee ${VERSION} — install on macOS
====================================

1) Drag Studee.app into Applications.
2) First launch: right-click → Open → Open.
   (App is ad-hoc signed; Gatekeeper may warn.)
3) Open Settings and paste your DeepSeek API key.

OCR (images / screen capture / scanned PDFs) is bundled —
no Homebrew, Python, or model download is required.

Screen Recording (screenshot / region capture)
----------------------------------------------
Debug (flutter run) and this packaged app are separate permissions:
  • Studee (Debug)  → com.studee.studeePc.debug
  • Studee          → com.studee.studeePc  (this DMG)

If System Settings shows Screen Recording "on" but capture still fails
(common after reinstalling an older ad-hoc build):

  1) Quit Studee completely.
  2) From this DMG run:  ./reset_screen_capture_permission.sh
     OR in the app: Cài đặt → Đặt lại quyền Ghi màn hình
  3) Open /Applications/Studee.app, allow when prompted.
  4) Quit and reopen once more (required by macOS).

Note: This build is large because it includes the local OCR engine.
Apple Silicon (arm64) is required for this OCR package.

Uninstall (complete removal)
----------------------------
Quit Studee, then in Terminal:

  # From this DMG volume:
  ./uninstall_macos.sh

  # Or after install:
  /Applications/Studee.app/Contents/Resources/uninstall_macos.sh

Type YES when prompted (or pass --yes). See HOW_TO_UNINSTALL.txt.
EOF
else
  cat > "$STAGE/HOW_TO_INSTALL.txt" <<EOF
Studee ${VERSION} — install on macOS
====================================

1) Drag Studee.app into Applications.
2) First launch: right-click → Open → Open.
3) Open Settings and paste your DeepSeek API key.
4) OCR setup (this slim build):

     brew install python@3.12
     cd /Applications/Studee.app/Contents/Resources/ocr_worker
     ./setup_real_ocr.sh
     ./warmup_models.sh

Screen Recording: if capture fails after using a Debug build, reset permission
(see HOW_TO_INSTALL full build notes / reset_screen_capture_permission.sh).

Uninstall (complete removal)
----------------------------
Quit Studee, then in Terminal:

  ./uninstall_macos.sh

  # Or:
  /Applications/Studee.app/Contents/Resources/uninstall_macos.sh

See HOW_TO_UNINSTALL.txt.
EOF
fi

echo "==> Adding uninstall / permission scripts + docs to DMG…"
cp "$ROOT/scripts/uninstall_macos.sh" "$STAGE/uninstall_macos.sh"
chmod +x "$STAGE/uninstall_macos.sh"
cp "$ROOT/scripts/uninstall_macos.sh" "$RESOURCES/uninstall_macos.sh"
chmod +x "$RESOURCES/uninstall_macos.sh"
cp "$ROOT/scripts/reset_screen_capture_permission.sh" "$STAGE/reset_screen_capture_permission.sh"
chmod +x "$STAGE/reset_screen_capture_permission.sh"
cp "$ROOT/scripts/reset_screen_capture_permission.sh" "$RESOURCES/reset_screen_capture_permission.sh"
chmod +x "$RESOURCES/reset_screen_capture_permission.sh"

cat > "$STAGE/HOW_TO_UNINSTALL.txt" <<EOF
Studee ${VERSION} — complete uninstall (macOS)
=============================================

This removes the app, local study data, preferences, OCR caches,
and the DeepSeek API key stored in Keychain.

1) Quit Studee completely (Dock icon too).

2) Run the uninstall script in Terminal.

   From this DMG (open the volume, then):

     cd /Volumes/Studee\\ ${VERSION}
     ./uninstall_macos.sh

   Or after Studee is installed:

     /Applications/Studee.app/Contents/Resources/uninstall_macos.sh

3) Type YES when asked (or use --yes to skip the prompt).

What is deleted
---------------
- /Applications/Studee.app
- ~/Library/Application Support/com.studee.studeePc
- ~/Library/Containers/com.studee.studeePc  (user Data; Apple metadata may remain)
- ~/Library/Caches/com.studee.studeePc
- ~/Library/Preferences/com.studee.studeePc.plist
- ~/Library/Saved Application State/com.studee.studeePc.savedState
- ~/Library/Logs/studee_ocr_resolve.log
- Keychain item for deepseek_api_key
- ~/.paddlex (shared PaddleOCR cache from older setups)

Developers running the script from the studee-pc repo also clear
build/ocr_bundle and dist/.

Notes
-----
macOS may refuse to delete ~/Library/Containers/.../metadata.plist without
Full Disk Access for Terminal (System Settings → Privacy & Security →
Full Disk Access). That leftover is harmless (~30KB Apple metadata).
Grant Full Disk Access and re-run the script if you want it gone.
EOF

ln -sf /Applications "$STAGE/Applications"

echo "==> Codesign…"
ENTITLEMENTS="$ROOT/macos/Runner/Release.entitlements"
# Prefer a stable identity when the developer has one (Apple Development or a
# trusted local cert). Ad-hoc ("-") changes CDHash every rebuild and leaves
# Screen Recording stuck "on" in Settings while the app still cannot capture.
SIGN_ID="${CODESIGN_IDENTITY:-}"
if [[ -z "$SIGN_ID" ]]; then
  # Prefer a trusted "Studee Local Distribution" if the user created one.
  if security find-identity -v -p codesigning 2>/dev/null | grep -F "Studee Local Distribution" >/dev/null; then
    SIGN_ID="Studee Local Distribution"
  fi
fi

if [[ -n "$SIGN_ID" && "$SIGN_ID" != "-" ]]; then
  echo "    Signing with identity: $SIGN_ID"
  if ! codesign --force --deep --sign "$SIGN_ID" \
      --entitlements "$ENTITLEMENTS" \
      "$STAGE/$APP_NAME"; then
    echo "WARNING: codesign with '$SIGN_ID' failed; falling back to ad-hoc."
    SIGN_ID=""
  fi
fi

if [[ -z "$SIGN_ID" || "$SIGN_ID" == "-" ]]; then
  echo "    Ad-hoc sign (if Screen Recording sticks after reinstall, run"
  echo "    ./reset_screen_capture_permission.sh on the DMG)."
  codesign --force --deep --sign - \
    --entitlements "$ENTITLEMENTS" \
    "$STAGE/$APP_NAME" 2>/dev/null || \
  codesign --force --deep --sign - "$STAGE/$APP_NAME" || {
    echo "WARNING: codesign failed; continuing with unsigned app."
  }
fi

echo "==> Creating DMG…"
mkdir -p "$ROOT/dist"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH" >/dev/null
SIZE="$(du -h "$DMG_PATH" | awk '{print $1}')"
echo ""
echo "Done: $DMG_PATH ($SIZE)"
echo "Share this file. Recipients: drag to Applications, then right-click → Open."
