#!/usr/bin/env bash
# Optional: create a stable local codesigning identity for Studee DMG builds.
#
# Why: ad-hoc signing changes every rebuild. macOS Screen Recording then shows
# "allowed" in System Settings for an old binary while the new app still fails
# CGPreflightScreenCaptureAccess().
#
# This is OPTIONAL. Without it, use:
#   ./scripts/reset_screen_capture_permission.sh
# after reinstalling a DMG, or Cài đặt → Đặt lại quyền Ghi màn hình in the app.
#
# After this script imports the cert you MUST trust it once in Keychain Access:
#   Keychain Access → login → My Certificates → "Studee Local Distribution"
#   → double-click → Trust → Code Signing → Always Trust → close (enter password)
# Then: security find-identity -v -p codesigning   # should list it under Valid
#
# Usage:
#   ./scripts/ensure_studee_codesign_identity.sh
set -euo pipefail

NAME="Studee Local Distribution"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"
[[ -f "$KEYCHAIN" ]] || KEYCHAIN="${HOME}/Library/Keychains/login.keychain"

if security find-identity -v -p codesigning 2>/dev/null | grep -F "$NAME" >/dev/null; then
  echo "Valid codesigning identity already present: $NAME"
  security find-identity -v -p codesigning | grep -F "$NAME" || true
  exit 0
fi

echo "Creating self-signed codesigning certificate: $NAME"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/studee_codesign.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

cat > "$TMP/cert.cnf" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${NAME}
O = Studee
C = VN

[v3_req]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

openssl req -new -x509 -days 3650 -nodes \
  -newkey rsa:2048 \
  -keyout "$TMP/key.pem" \
  -out "$TMP/cert.pem" \
  -config "$TMP/cert.cnf" >/dev/null 2>&1

P12_PASS="studee-local-codesign"
openssl pkcs12 -export \
  -inkey "$TMP/key.pem" \
  -in "$TMP/cert.pem" \
  -out "$TMP/cert.p12" \
  -name "$NAME" \
  -passout "pass:${P12_PASS}" >/dev/null 2>&1

security import "$TMP/cert.p12" \
  -k "$KEYCHAIN" \
  -P "$P12_PASS" \
  -T /usr/bin/codesign \
  -T /usr/bin/security \
  -T /usr/bin/productsign

security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s \
  -k "" \
  "$KEYCHAIN" >/dev/null 2>&1 || true

echo
echo "Certificate imported. Complete ONE manual step:"
echo "  1) Open Keychain Access"
echo "  2) login → My Certificates → ${NAME}"
echo "  3) Double-click → Trust → Code Signing → Always Trust"
echo "  4) Close the window and enter your Mac password if asked"
echo "  5) Verify:  security find-identity -v -p codesigning"
echo "     (should list ${NAME} under Valid identities)"
echo
echo "Then rebuild the DMG; package_macos_dmg.sh will use this identity."
