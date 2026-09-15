# macOS build and QEMU setup

This is the authoritative setup/runbook for building and running ESP32 EFIS firmware on Apple Silicon macOS. The project targets **ESP32-S3** and is pinned to **ESP-IDF v5.4.4**. QEMU and synthetic data are development-only; aircraft-target builds must keep simulation disabled.

## Build scripts — preferred workflow

The repository now contains the complete routine build/run workflow under `scripts/`. Use these scripts instead of repeatedly typing the underlying `idf.py` commands:

- `scripts/efis-env.sh` — prepares the pinned ESP-IDF/Python/QEMU shell environment. **Source** this script.
- `scripts/build-qemu.sh` — builds the QEMU configuration in `firmware/build-qemu`. Pass `--clean` to delete and completely reconfigure it first.
- `scripts/run-qemu.sh` — starts graphical QEMU and automatically saves console output to `firmware/qemu.log`.
- `scripts/build-hardware.sh` — builds the real ESP32-S3 configuration in the separate `firmware/build` directory. Pass `--clean` for a fresh hardware configuration.

From a new Terminal, the normal emulator workflow is:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
zsh scripts/build-qemu.sh
zsh scripts/run-qemu.sh
```

After QEMU/Kconfig/default changes, an ESP-IDF/Python mismatch, or whenever a genuinely clean emulator build is required:

```bash
zsh scripts/build-qemu.sh --clean
zsh scripts/run-qemu.sh
```

For normal hardware firmware:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
zsh scripts/build-hardware.sh
```

Use `zsh scripts/build-hardware.sh --clean` when a fresh hardware configuration is required. **Never flash `build-qemu` to hardware.**

The scripts deliberately do not source `efis-env.sh` themselves: environment activation must modify the current interactive shell and therefore `efis-env.sh` is sourced once at the start of a development session.

## One-time prerequisites

Install Apple's command-line tools and Homebrew as required. The Espressif QEMU installation used here requires:

```bash
xcode-select --install
brew install libgcrypt sdl2
```

Observed library locations include `/opt/homebrew/opt/libgcrypt/lib/libgcrypt.20.dylib` and `/opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib`.

## Repository and ESP-IDF

The normal checkout is `~/Documents/Xcode/ESP32-EFIS`. The pinned ESP-IDF installation is `~/.espressif/v5.4.4/esp-idf`.

Install/repair the ESP32-S3 tools with:

```bash
~/.espressif/v5.4.4/esp-idf/install.sh esp32s3
```

## Environment script

Run this at the beginning of each new Terminal development session:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
source scripts/efis-env.sh
```

It activates ESP-IDF v5.4.4, forces `~/.espressif/tools/python/v5.4.4/venv/bin/python`, removes competing Espressif Python environment bin directories from PATH, defines `idf.py` through the pinned interpreter, exports `EFIS_ROOT` and `EFIS_FIRMWARE_DIR`, locates the installed Espressif QEMU binary, and fails early if the active Python is inconsistent.

This prevents the observed CMake mismatch between `~/.espressif/python_env/idf5.4_py3.14_env/bin/python` and `~/.espressif/tools/python/v5.4.4/venv/bin/python`. Existing CMake build directories remember their configuring interpreter, so use the appropriate build script with `--clean` after such a mismatch.

## Install QEMU once

```bash
source scripts/efis-env.sh
python "$IDF_PATH/tools/idf_tools.py" install qemu-xtensa
source scripts/efis-env.sh
```

Verify with `which qemu-system-xtensa` and `qemu-system-xtensa --version`. The original installation was `qemu-xtensa@esp_develop_9.2.2_20250817`; the environment script searches installed versions rather than hard-coding that release.

## What the QEMU build script does

`zsh scripts/build-qemu.sh` changes to `$EFIS_FIRMWARE_DIR` and builds with:

```bash
idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  build
```

If `build-qemu` has not yet been configured, or `--clean` is supplied, it first runs:

```bash
idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  set-target esp32s3
```

The QEMU defaults enable `CONFIG_EFIS_BENCH_SIMULATION` and `CONFIG_EFIS_QEMU` and explicitly contain `# CONFIG_SPIRAM is not set`. This PSRAM override is essential because the physical N16R2 has external Quad PSRAM but the QEMU configuration does not provide that physical device. Without the override, boot asserted in `s_psram_chip_init` before `app_main()`.

## What the QEMU run script does

`zsh scripts/run-qemu.sh` verifies that `build-qemu` exists, removes the previous `firmware/qemu.log`, and runs:

```bash
idf.py -B build-qemu qemu --graphics monitor 2>&1 | tee qemu.log
```

This opens the 480×480 RGB565 virtual display and retains the console log for diagnosis. Exit with `Ctrl-]`. The current QEMU acceptance stage locks the display to the Artificial Horizon/PFD and shows the test name/countdown directly on-screen.

For panic diagnosis, inspect the saved log with:

```bash
grep -B 60 -A 15 -E "Guru|panic|abort|assert|Backtrace|Rebooting" qemu.log | tail -200
```

## What the hardware build script does

`zsh scripts/build-hardware.sh` uses only the normal `firmware/build` directory and normal defaults. It never references `sdkconfig.qemu.defaults`. The physical build retains the ESP32-S3-WROOM-1-N16R2 PSRAM configuration and simulation remains OFF by default.

The underlying build is:

```bash
idf.py -B build set-target esp32s3   # first/clean configuration
idf.py -B build build
```

Before any aircraft use, verify the boot log reports `BENCH SIMULATION: OFF`.

## Troubleshooting

**`qemu-system-xtensa` not found:** source `scripts/efis-env.sh`; it handles the nested Espressif QEMU installation path.

**Python environment mismatch:** source `scripts/efis-env.sh`, confirm the pinned Python shown in its summary, then run `zsh scripts/build-qemu.sh --clean` or `zsh scripts/build-hardware.sh --clean` as appropriate.

**QEMU reboots in `esp_psram_init`:** pull the current repository and run `zsh scripts/build-qemu.sh --clean`. QEMU must use `sdkconfig.qemu.defaults` with SPIRAM disabled.

**`dyld: Library not loaded`:** install the named Homebrew dependency; the observed requirements were `libgcrypt` and `sdl2`.

**QEMU build does not exist:** run `zsh scripts/build-qemu.sh --clean` before `zsh scripts/run-qemu.sh`.

**Simulation unexpectedly enabled in a hardware build:** stop. Run `zsh scripts/build-hardware.sh --clean` and verify `BENCH SIMULATION: OFF` before hardware/aircraft use.

## Safety boundary

QEMU and bench simulation are development facilities only. Synthetic data must never activate as a fallback for a missing, failed or stale real sensor. A real-source failure must produce an unmistakable invalid indication. Keep `build` and `build-qemu` separate. Never flash `build-qemu` to aircraft hardware. The ESP32 EFIS remains a supplementary/non-primary experimental instrument.
