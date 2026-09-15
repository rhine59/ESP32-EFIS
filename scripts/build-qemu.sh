#!/bin/zsh
# Build the ESP32 EFIS QEMU configuration.
# Source scripts/efis-env.sh before running this script.
set -euo pipefail

if [[ -z "${EFIS_FIRMWARE_DIR:-}" || -z "${IDF_PATH:-}" ]]; then
    echo "ERROR: ESP32 EFIS environment is not active."
    echo "Run: source scripts/efis-env.sh"
    exit 1
fi

cd "$EFIS_FIRMWARE_DIR"

if [[ "${1:-}" == "--clean" ]]; then
    echo "Removing build-qemu for a clean configure..."
    rm -rf build-qemu
    idf.py -B build-qemu \
      -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
      set-target esp32s3
fi

# Configure automatically if the QEMU build directory does not yet exist.
if [[ ! -f build-qemu/CMakeCache.txt ]]; then
    idf.py -B build-qemu \
      -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
      set-target esp32s3
fi

idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  build

echo
echo "QEMU build complete. Do NOT flash build-qemu to hardware."
echo "Run with: scripts/run-qemu.sh"
