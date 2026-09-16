#!/bin/sh
set -eu

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 VERSION BUILD FIRMWARE_BIN PUBLIC_BASE_URL" >&2
  exit 2
fi

VERSION="$1"
BUILD="$2"
FIRMWARE="$3"
BASE_URL="${4%/}"

case "$VERSION" in
  *[!0-9A-Za-z._-]*|'') echo "Invalid VERSION" >&2; exit 2 ;;
esac
case "$BUILD" in
  *[!0-9]*|'') echo "BUILD must be numeric" >&2; exit 2 ;;
esac

[ -f "$FIRMWARE" ] || { echo "Firmware not found: $FIRMWARE" >&2; exit 2; }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
RELEASE_DIR="$ROOT/public/efis/releases/$VERSION"
IMAGE_NAME="esp32-efis-$VERSION.bin"
mkdir -p "$RELEASE_DIR"
cp "$FIRMWARE" "$RELEASE_DIR/$IMAGE_NAME"

if command -v shasum >/dev/null 2>&1; then
  SHA256=$(shasum -a 256 "$RELEASE_DIR/$IMAGE_NAME" | awk '{print $1}')
elif command -v sha256sum >/dev/null 2>&1; then
  SHA256=$(sha256sum "$RELEASE_DIR/$IMAGE_NAME" | awk '{print $1}')
else
  echo "Need shasum or sha256sum" >&2
  exit 2
fi

cat > "$ROOT/public/efis/manifest.json" <<EOF
{
  "product": "ESP32-EFIS",
  "version": "$VERSION",
  "build": $BUILD,
  "hardware_profile": "s3-n16r2-v1",
  "idf": "5.4.4",
  "image_url": "$BASE_URL/efis/releases/$VERSION/$IMAGE_NAME",
  "sha256": "$SHA256",
  "minimum_allowed_version": "0.0.0",
  "release_notes": "Approved ESP32 EFIS release $VERSION"
}
EOF

printf 'Published %s\nSHA-256: %s\nManifest: %s\n' "$RELEASE_DIR/$IMAGE_NAME" "$SHA256" "$ROOT/public/efis/manifest.json"
