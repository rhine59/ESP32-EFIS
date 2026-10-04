#!/bin/sh
set -eu

# Creates a deterministic, NON-FLASHABLE payload for end-to-end OTA transport tests.
# It is intentionally not an ESP32 application image.
VERSION="${1:-2.4.1-test.1}"
OUT="${2:-/tmp/esp32-efis-$VERSION.bin}"
SIZE="${SIM_TEST_IMAGE_SIZE:-4096}"

case "$VERSION" in *[!0-9A-Za-z._-]*|'') echo "Invalid VERSION" >&2; exit 2;; esac
case "$SIZE" in *[!0-9]*|'') echo "SIM_TEST_IMAGE_SIZE must be numeric" >&2; exit 2;; esac
[ "$SIZE" -ge 1024 ] || { echo "SIM_TEST_IMAGE_SIZE must be at least 1024" >&2; exit 2; }

python - "$VERSION" "$OUT" "$SIZE" <<'PY'
import hashlib, pathlib, sys
version, out, size = sys.argv[1], pathlib.Path(sys.argv[2]), int(sys.argv[3])
header=("MICROSKY-HORIZON-SIMULATOR-OTA\n"
        "NON-FLASHABLE TEST PAYLOAD\n"
        f"VERSION={version}\n").encode()
seed=hashlib.sha256(header).digest()
body=(seed*((size-len(header)+len(seed)-1)//len(seed)))[:size-len(header)]
out.write_bytes(header+body)
print(out)
print(hashlib.sha256(out.read_bytes()).hexdigest())
PY

echo "Created deterministic simulator-only OTA payload."
echo "DO NOT FLASH THIS FILE TO AN ESP32."
