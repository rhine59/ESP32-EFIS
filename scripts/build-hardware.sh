#!/bin/zsh
# Build the normal ESP32-S3 hardware firmware. This never uses build-qemu.
# Source scripts/efis-env.sh before running this script.
set -euo pipefail

if [[ -z "${EFIS_FIRMWARE_DIR:-}" || -z "${IDF_PATH:-}" ]]; then
    echo "ERROR: ESP32 EFIS environment is not active."
    echo "Run: source scripts/efis-env.sh"
    exit 1
fi

cd "$EFIS_FIRMWARE_DIR"

if [[ "${1:-}" == "--clean" ]]; then
    echo "Removing normal hardware build directory..."
    rm -rf build
    idf.py -B build set-target esp32s3
fi

if [[ ! -f build/CMakeCache.txt ]]; then
    idf.py -B build set-target esp32s3
fi

idf.py -B build build

echo
echo "Hardware build complete in firmware/build."
echo "Before aircraft use verify BENCH SIMULATION is OFF."
