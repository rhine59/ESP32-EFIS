#!/bin/zsh
# Run the already-built ESP32 EFIS QEMU image with graphics and a persistent log.
# Source scripts/efis-env.sh before running this script.
set -euo pipefail

if [[ -z "${EFIS_FIRMWARE_DIR:-}" || -z "${IDF_PATH:-}" ]]; then
    echo "ERROR: ESP32 EFIS environment is not active."
    echo "Run: source scripts/efis-env.sh"
    exit 1
fi

cd "$EFIS_FIRMWARE_DIR"

if [[ ! -f build-qemu/CMakeCache.txt ]]; then
    echo "ERROR: build-qemu does not exist."
    echo "Run: ../scripts/build-qemu.sh --clean"
    exit 1
fi

rm -f qemu.log
echo "Starting ESP32 EFIS QEMU. Exit with Ctrl-]."
echo "Console output is also being saved to firmware/qemu.log."

idf.py -B build-qemu qemu --graphics monitor 2>&1 | tee qemu.log
