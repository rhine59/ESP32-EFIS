#!/bin/sh
set -eu

# Historical filename retained for compatibility. This command now STAGES only.
# Publishing is a separate deliberate action in the private OTA Admin UI.
if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
  echo "Usage: $0 VERSION BUILD FIRMWARE_BIN [MINIMUM_VERSION] [RELEASE_NOTES]" >&2
  exit 2
fi
VERSION="$1"; BUILD="$2"; FIRMWARE="$3"; MINIMUM="${4:-build:0}"; NOTES="${5:-ESP32 EFIS release $VERSION}"
case "$VERSION" in *[!0-9A-Za-z._-]*|'') echo "Invalid VERSION" >&2; exit 2;; esac
# Validate using the same policy as OTA Admin BEFORE creating any files.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
POLICY_DIR="$SCRIPT_DIR/../admin"
if ! PYTHONPATH="$POLICY_DIR" python3 - "$BUILD" "$MINIMUM" <<'VALIDATE'
import sys
from release_build_policy import validate_release_build
try:
    validate_release_build(sys.argv[1], sys.argv[2])
except ValueError as exc:
    print(f"Invalid signed release build policy: {exc}", file=sys.stderr)
    sys.exit(2)
VALIDATE
then
  exit 2
fi
[ -f "$FIRMWARE" ] || { echo "Firmware not found: $FIRMWARE" >&2; exit 2; }
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd); ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
RELEASE_DIR="$ROOT/public/efis/releases/$VERSION"; META_DIR="$ROOT/public/efis/release-metadata"; IMAGE_NAME="esp32-efis-$VERSION.bin"
[ ! -e "$RELEASE_DIR" ] || { echo "Release $VERSION already exists; refusing overwrite" >&2; exit 2; }
mkdir -p "$RELEASE_DIR" "$META_DIR"; cp "$FIRMWARE" "$RELEASE_DIR/$IMAGE_NAME"
if command -v shasum >/dev/null 2>&1; then SHA256=$(shasum -a 256 "$RELEASE_DIR/$IMAGE_NAME"|awk '{print $1}'); elif command -v sha256sum >/dev/null 2>&1; then SHA256=$(sha256sum "$RELEASE_DIR/$IMAGE_NAME"|awk '{print $1}'); else echo "Need shasum or sha256sum" >&2; exit 2; fi
cat > "$META_DIR/$VERSION.json" <<EOF
{
  "version": "$VERSION",
  "build": $BUILD,
  "minimum_allowed_version": "$MINIMUM",
  "release_notes": "$NOTES",
  "sha256": "$SHA256"
}
EOF
printf '\nSTAGED ONLY — NOT PUBLISHED\nImage: %s\nSHA-256: %s\nMetadata: %s\n\nUse the private OTA Admin dashboard and select Publish only after review.\n' "$RELEASE_DIR/$IMAGE_NAME" "$SHA256" "$META_DIR/$VERSION.json"
