#!/usr/bin/env bash
# Completely uninstall Studee for macOS (app + data + legacy keychain leftovers + caches).
#
# Usage:
#   ./uninstall_macos.sh                 # from DMG volume (interactive)
#   ./uninstall_macos.sh --yes           # no prompt
#   /Applications/Studee.app/Contents/Resources/uninstall_macos.sh
#
# Removes:
#   - /Applications/Studee.app
#   - Application Support / Containers / Caches / Preferences / Saved State
#     (includes ApplicationData/credentials.v1.dat)
#   - OCR resolve log
#   - Legacy Keychain items from older builds (flutter_secure_storage)
#   - ~/.paddlex (shared PaddleOCR cache from older setups)
#   - Repo build/ocr_bundle + dist (only when run from the studee-pc git repo)
set -uo pipefail

YES=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) YES=1 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Usage: $0 [--yes]" >&2
      exit 1
      ;;
  esac
done

BUNDLE_ID="com.studee.studeePc"
APP="/Applications/Studee.app"
SUPPORT="${HOME}/Library/Application Support/${BUNDLE_ID}"
CONTAINER="${HOME}/Library/Containers/${BUNDLE_ID}"
CACHES="${HOME}/Library/Caches/${BUNDLE_ID}"
PREFS="${HOME}/Library/Preferences/${BUNDLE_ID}.plist"
SAVED="${HOME}/Library/Saved Application State/${BUNDLE_ID}.savedState"
OCR_LOG="${HOME}/Library/Logs/studee_ocr_resolve.log"
PADDLEX="${HOME}/.paddlex"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# If launched from inside Studee.app, re-exec from /tmp so we can delete the app.
case "$SCRIPT_DIR" in
  */Studee.app/*|*/studee_pc.app/*)
    tmp_script="$(mktemp /tmp/studee_uninstall.XXXXXX.sh)"
    cp "${BASH_SOURCE[0]}" "$tmp_script"
    chmod +x "$tmp_script"
    exec "$tmp_script" "$@"
    ;;
esac

echo "This will permanently remove Studee and local study data."
echo "  App:              ${APP}"
echo "  Application Support: ${SUPPORT}"
echo "  Container:        ${CONTAINER}"
echo "  Caches:           ${CACHES}"
echo "  Preferences:      ${PREFS}"
echo "  Saved state:      ${SAVED}"
echo "  OCR log:          ${OCR_LOG}"
echo "  Credentials file: ${SUPPORT}/ApplicationData/credentials.v1.dat"
echo "  Legacy Keychain:  flutter_secure_storage leftovers (if any)"
echo "  PaddleX cache:    ${PADDLEX}"
if [[ -f "${REPO_ROOT}/pubspec.yaml" ]] && grep -q 'name: studee_pc' "${REPO_ROOT}/pubspec.yaml" 2>/dev/null; then
  echo "  Repo artifacts:   ${REPO_ROOT}/build/ocr_bundle , ${REPO_ROOT}/dist"
fi
echo

if [[ "$YES" != "1" ]]; then
  read -r -p "Type YES to uninstall: " confirm
  if [[ "$confirm" != "YES" ]]; then
    echo "Cancelled."
    exit 1
  fi
fi

echo "==> Quitting Studee…"
osascript -e 'quit app "Studee"' 2>/dev/null || true
osascript -e 'quit app "studee_pc"' 2>/dev/null || true
pkill -f "/Applications/Studee.app" 2>/dev/null || true
pkill -f "Contents/MacOS/studee_pc" 2>/dev/null || true
sleep 1

WARNINGS=0

remove_path() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    echo "  skip (missing) $path"
    return 0
  fi
  echo "  rm  $path"
  if rm -rf "$path" 2>/tmp/studee_uninstall_rm.err; then
    return 0
  fi
  # Retry after making writable (common for caches).
  chmod -R u+w "$path" 2>/dev/null || true
  if rm -rf "$path" 2>/tmp/studee_uninstall_rm.err; then
    return 0
  fi
  echo "  WARN: could not fully remove $path"
  if [[ -s /tmp/studee_uninstall_rm.err ]]; then
    sed 's/^/         /' /tmp/studee_uninstall_rm.err | head -5
  fi
  WARNINGS=$((WARNINGS + 1))
  return 0
}

remove_container() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "  skip (missing) $path"
    return 0
  fi
  echo "  clean container $path"
  # User data is under Data/; metadata.plist is often TCC-protected.
  if [[ -d "$path/Data" ]]; then
    chmod -R u+w "$path/Data" 2>/dev/null || true
    rm -rf "$path/Data" 2>/dev/null || true
  fi
  # Best-effort remove of remaining files (may fail on metadata.plist).
  find "$path" -mindepth 1 -maxdepth 1 ! -name '.com.apple.containermanagerd.metadata.plist' \
    -exec rm -rf {} + 2>/dev/null || true
  if rm -rf "$path" 2>/dev/null; then
    echo "  removed $path"
    return 0
  fi
  if [[ -e "$path" ]]; then
    echo "  WARN: leftover container (macOS protects metadata): $path"
    echo "         Grant Terminal Full Disk Access, then re-run, or ignore —"
    echo "         it is empty aside from Apple metadata (~30KB)."
    WARNINGS=$((WARNINGS + 1))
  fi
  return 0
}

echo "==> Removing app and data…"
remove_path "$APP"
remove_path "$SUPPORT"
remove_container "$CONTAINER"
remove_path "$CACHES"
remove_path "$PREFS"
remove_path "$SAVED"
remove_path "$OCR_LOG"

echo "==> Removing legacy Keychain leftovers (older builds)…"
# flutter_secure_storage stores key name as the Keychain account.
deleted_key=0
for service in \
  "flutter_secure_storage_service" \
  "${BUNDLE_ID}" \
  "FlutterSecureStorage"
do
  for account in \
    "deepseek_api_key" \
    "studee_api_credentials_v1" \
    "mathpix_app_id" \
    "mathpix_app_key" \
    "mathpix_base_url"
  do
    if security delete-generic-password -s "$service" -a "$account" >/dev/null 2>&1; then
      echo "  deleted keychain item service=$service account=$account"
      deleted_key=1
    fi
  done
done
if [[ "$deleted_key" -eq 0 ]]; then
  echo "  (no matching Keychain item found — OK if never used or already migrated)"
fi

echo "==> Removing shared PaddleX cache…"
remove_path "$PADDLEX"

if [[ -f "${REPO_ROOT}/pubspec.yaml" ]] && grep -q 'name: studee_pc' "${REPO_ROOT}/pubspec.yaml" 2>/dev/null; then
  echo "==> Removing repo packaging artifacts…"
  remove_path "${REPO_ROOT}/build/ocr_bundle"
  remove_path "${REPO_ROOT}/dist"
fi

echo
if [[ "$WARNINGS" -gt 0 ]]; then
  echo "Studee uninstall finished with $WARNINGS warning(s)."
  echo "Study data and the app are removed. See warnings above for leftovers."
else
  echo "Studee uninstall complete."
fi
echo "If a Keychain prompt appeared and you cancelled, delete the item manually in Keychain Access."
exit 0
