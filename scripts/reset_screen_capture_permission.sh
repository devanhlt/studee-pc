#!/usr/bin/env bash
# Reset macOS Screen Recording TCC entries for Studee (debug + packaged).
#
# Use when the Screen Recording toggle is stuck / won't stay on after switching
# between flutter-run and /Applications/Studee.app.
#
# Usage:
#   ./scripts/reset_screen_capture_permission.sh
set -euo pipefail

echo "Resetting Screen Recording permission for Studee identities…"
tccutil reset ScreenCapture com.studee.studeePc 2>/dev/null && \
  echo "  reset com.studee.studeePc  (packaged /Applications/Studee.app)" || \
  echo "  (no entry / already clear) com.studee.studeePc"

tccutil reset ScreenCapture com.studee.studeePc.debug 2>/dev/null && \
  echo "  reset com.studee.studeePc.debug  (flutter run / Studee (Debug))" || \
  echo "  (no entry / already clear) com.studee.studeePc.debug"

# Older / mistaken identifiers that may appear in Privacy list
tccutil reset ScreenCapture studee_pc 2>/dev/null || true

echo
echo "Done. Next steps:"
echo "  1) Quit every Studee process (Dock → Quit; also quit flutter-run Debug)."
echo "  2) Open only the app you want:"
echo "       Packaged:  open /Applications/Studee.app"
echo "       Debug:     flutter run -d macos"
echo "  3) Try capture once; allow Screen Recording when prompted."
echo "  4) In System Settings you should see TWO entries if both were used:"
echo "       • Studee          → DMG / Applications"
echo "       • Studee (Debug)  → flutter run"
echo "  5) Enable the one matching the app you opened, then quit & reopen that app."
echo
echo "System Settings shortcut:"
echo "  open 'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture'"
