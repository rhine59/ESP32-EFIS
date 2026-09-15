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
EFIS_IDF_PYTHON="${HOME}/.espressif/tools/python/v${EFIS_IDF_VERSION}/venv/bin/python"
EFIS_IDF_PYTHON_BIN="${EFIS_IDF_PYTHON:h}"

_efis_fail() {
    echo "ERROR: $1"
    return 1 2>/dev/null || exit 1
}

if [[ ! -f "${EFIS_IDF_ROOT}/export.sh" ]]; then
    _efis_fail "ESP-IDF ${EFIS_IDF_VERSION} was not found at ${EFIS_IDF_ROOT}"
fi

if [[ ! -x "${EFIS_IDF_PYTHON}" ]]; then
    _efis_fail "Pinned ESP-IDF Python was not found at ${EFIS_IDF_PYTHON}"
fi

echo "ESP32 EFIS development environment"
echo "----------------------------------"
echo "ESP-IDF: v${EFIS_IDF_VERSION}"

# Remove ESP-IDF Python environments that may have been activated by a different
# ESP-IDF installation. The project has previously encountered two v5.4 Python
# environments (~/.espressif/python_env/... and ~/.espressif/tools/python/...).
# A CMake build directory records the Python interpreter used to configure it,
# so silently switching interpreters causes idf.py to reject an existing build.
path=(${path:#${HOME}/.espressif/python_env/*/bin})
path=(${path:#${HOME}/.espressif/tools/python/*/venv/bin})
export PATH
unset IDF_PYTHON_ENV_PATH

# Activate the pinned ESP-IDF installation to establish IDF_PATH and all normal
# Espressif compiler/debugger/tool paths.
source "${EFIS_IDF_ROOT}/export.sh"
if [[ $? -ne 0 ]]; then
    _efis_fail "ESP-IDF environment activation failed"
fi

# Force the same known Python environment used by the ESP32 EFIS development
# build. Put it first after export.sh so `python` and ESP-IDF/CMake agree.
path=(${path:#${HOME}/.espressif/python_env/*/bin})
path=(${path:#${HOME}/.espressif/tools/python/*/venv/bin})
path=("${EFIS_IDF_PYTHON_BIN}" $path)
export PATH
export IDF_PYTHON_ENV_PATH="${EFIS_IDF_PYTHON:h:h}"

# Define idf.py explicitly through the pinned interpreter. This avoids an
# export.sh shell function or PATH entry invoking a different ESP-IDF Python.
unfunction idf.py 2>/dev/null || true
function idf.py() {
    "${EFIS_IDF_PYTHON}" "${EFIS_IDF_ROOT}/tools/idf.py" "$@"
}

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
# it still works if the repository is checked out somewhere else.
EFIS_SCRIPT_PATH="${(%):-%N}"
export EFIS_ROOT="$(cd "$(dirname "${EFIS_SCRIPT_PATH}")/.." && pwd)"
export EFIS_FIRMWARE_DIR="${EFIS_ROOT}/firmware"

# Final checks. Fail now rather than discovering an interpreter mismatch after
# a long build or when QEMU is launched.
EFIS_ACTIVE_PYTHON="$(command -v python)"
if [[ "${EFIS_ACTIVE_PYTHON}" != "${EFIS_IDF_PYTHON}" ]]; then
    _efis_fail "Python mismatch: expected ${EFIS_IDF_PYTHON}, got ${EFIS_ACTIVE_PYTHON}"
fi

echo
echo "Environment ready:"
echo "  IDF_PATH:          ${IDF_PATH}"
echo "  ESP-IDF Python:    ${EFIS_ACTIVE_PYTHON}"
echo "  EFIS_ROOT:         ${EFIS_ROOT}"
echo "  Firmware:          ${EFIS_FIRMWARE_DIR}"
echo "  idf.py:            pinned shell function -> ${EFIS_IDF_ROOT}/tools/idf.py"

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
