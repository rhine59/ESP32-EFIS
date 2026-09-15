#!/bin/zsh
# ESP32 EFIS development environment for macOS / zsh.
#
# IMPORTANT: source this file; do not execute it as a child process:
#   source scripts/efis-env.sh
# or:
#   . scripts/efis-env.sh
#
# Environment changes must be applied to the current shell.

EFIS_IDF_VERSION="5.4.4"
EFIS_IDF_ROOT="${HOME}/.espressif/v${EFIS_IDF_VERSION}/esp-idf"

if [[ ! -f "${EFIS_IDF_ROOT}/export.sh" ]]; then
    echo "ERROR: ESP-IDF ${EFIS_IDF_VERSION} was not found at:"
    echo "  ${EFIS_IDF_ROOT}"
    echo "Install ESP-IDF ${EFIS_IDF_VERSION} before using this script."
    return 1 2>/dev/null || exit 1
fi

echo "ESP32 EFIS development environment"
echo "----------------------------------"
echo "ESP-IDF: v${EFIS_IDF_VERSION}"

# Activate ESP-IDF in the current shell. This establishes IDF_PATH, its Python
# environment and the standard Espressif tool paths.
source "${EFIS_IDF_ROOT}/export.sh"
if [[ $? -ne 0 ]]; then
    echo "ERROR: ESP-IDF environment activation failed."
    return 1 2>/dev/null || exit 1
fi

# Espressif's qemu-xtensa package on the original Apple Silicon development
# machine was installed below ~/.espressif/tools/tools/qemu-xtensa but was not
# included in PATH by ESP-IDF's export step. Add the newest installed QEMU bin
# directory only when qemu-system-xtensa is not already available.
if ! command -v qemu-system-xtensa >/dev/null 2>&1; then
    QEMU_BIN=""
    for candidate in "${HOME}"/.espressif/tools/tools/qemu-xtensa/*/qemu/bin; do
        if [[ -x "${candidate}/qemu-system-xtensa" ]]; then
            QEMU_BIN="${candidate}"
        fi
    done

    if [[ -n "${QEMU_BIN}" ]]; then
        export PATH="${QEMU_BIN}:${PATH}"
        echo "Added Espressif QEMU to PATH: ${QEMU_BIN}"
    else
        echo "WARNING: qemu-system-xtensa was not found."
        echo "For emulator use install it with:"
        echo '  python "$IDF_PATH/tools/idf_tools.py" install qemu-xtensa'
    fi
fi

# Useful repository location. The script determines this from its own path so
# it still works if the repository is not checked out under ~/ESP32-EFIS.
EFIS_SCRIPT_PATH="${(%):-%N}"
export EFIS_ROOT="$(cd "$(dirname "${EFIS_SCRIPT_PATH}")/.." && pwd)"
export EFIS_FIRMWARE_DIR="${EFIS_ROOT}/firmware"

# Final checks and a concise status display.
echo
echo "Environment ready:"
echo "  IDF_PATH:          ${IDF_PATH}"
echo "  EFIS_ROOT:         ${EFIS_ROOT}"
echo "  Firmware:          ${EFIS_FIRMWARE_DIR}"
echo "  idf.py:            $(whence -w idf.py 2>/dev/null || echo not-found)"

if command -v qemu-system-xtensa >/dev/null 2>&1; then
    echo "  QEMU:              $(command -v qemu-system-xtensa)"
    qemu-system-xtensa --version 2>/dev/null | head -1 | sed 's/^/  QEMU version:      /'
else
    echo "  QEMU:              not found"
fi

echo
echo "To enter the firmware directory:"
echo '  cd "$EFIS_FIRMWARE_DIR"'
echo
echo "QEMU build/run directory: build-qemu"
