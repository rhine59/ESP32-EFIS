#!/bin/zsh
# Record the ESP32 EFIS QEMU demonstration on macOS.
# The firmware supplies the deterministic instrument sequence; macOS captures
# the QEMU graphics window. No physical EFIS hardware is involved.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/docs/media"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${1:-$OUT_DIR/ESP32-EFIS-QEMU-Demo-$STAMP.mov}"
DURATION="${EFIS_DEMO_SECONDS:-100}"

mkdir -p "$OUT_DIR"

if [[ -z "${EFIS_FIRMWARE_DIR:-}" || -z "${IDF_PATH:-}" ]]; then
  echo "ERROR: ESP32 EFIS environment is not active."
  echo "Run: source scripts/efis-env.sh"
  exit 1
fi

if [[ ! -f "$EFIS_FIRMWARE_DIR/build-qemu/CMakeCache.txt" ]]; then
  echo "ERROR: build-qemu does not exist."
  echo "Run: zsh scripts/build-qemu.sh --clean"
  exit 1
fi

if ! command -v screencapture >/dev/null 2>&1; then
  echo "ERROR: macOS screencapture is unavailable."
  exit 1
fi

cd "$EFIS_FIRMWARE_DIR"
rm -f qemu-demo.log

echo "Starting the deterministic ESP32 EFIS QEMU demonstration..."
(idf.py -B build-qemu qemu --graphics monitor >qemu-demo.log 2>&1) &
QEMU_JOB=$!

cleanup() {
  kill "$QEMU_JOB" >/dev/null 2>&1 || true
  wait "$QEMU_JOB" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

sleep 5

echo
 echo "QEMU should now be visible."
echo "macOS will ask you to select a window: click the QEMU instrument window."
echo "Recording will stop automatically after ${DURATION} seconds."
echo "If macOS asks for Screen Recording permission, grant it to Terminal and run this script again."
echo

# -v records video, -w selects a window, -V limits duration, -C excludes cursor.
screencapture -v -w -V "$DURATION" -C "$OUT"

echo
echo "Demo recording created:"
echo "$OUT"
echo
echo "QEMU log: $EFIS_FIRMWARE_DIR/qemu-demo.log"
