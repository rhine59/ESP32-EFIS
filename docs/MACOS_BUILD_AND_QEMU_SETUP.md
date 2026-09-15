# macOS build and QEMU setup

This is the authoritative setup/runbook for building and running ESP32 EFIS firmware on the current Apple Silicon macOS development machine. The project targets **ESP32-S3** and is pinned to **ESP-IDF v5.4.4**.

QEMU and synthetic data are development-only. Aircraft-target builds must keep simulation disabled.

## One-time prerequisites

Install Apple's command-line tools and Homebrew as required. The Espressif QEMU installation used here requires the Homebrew runtime libraries `libgcrypt` and `sdl2`:

```bash
xcode-select --install
brew install libgcrypt sdl2
```

The observed missing-library paths were `/opt/homebrew/opt/libgcrypt/lib/libgcrypt.20.dylib` and `/opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib`.

## Repository

The working checkout is normally:

```text
~/Documents/Xcode/ESP32-EFIS
```

Clone/update with:

```bash
cd ~/Documents/Xcode
git clone https://github.com/rhine59/ESP32-EFIS.git
```

or, for an existing checkout:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
```

## ESP-IDF v5.4.4

The pinned installation is:

```text
~/.espressif/v5.4.4/esp-idf
```

Install/repair the ESP32-S3 tool set with:

```bash
~/.espressif/v5.4.4/esp-idf/install.sh esp32s3
```

This also resolves an incomplete installation such as `tool esp-rom-elfs has no installed versions`.

## Standard new-shell setup

After the one-time installation, **do not manually assemble the environment each time**. Use the repository script:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
source scripts/efis-env.sh
```

It must be sourced because it modifies the current shell. The script:

- activates the pinned ESP-IDF v5.4.4 tree;
- forces the known interpreter `~/.espressif/tools/python/v5.4.4/venv/bin/python`;
- removes competing Espressif Python environment bin directories from PATH;
- defines `idf.py` through that pinned interpreter;
- exports `EFIS_ROOT` and `EFIS_FIRMWARE_DIR`;
- finds QEMU when Espressif installed it below `~/.espressif/tools/tools/qemu-xtensa/...` but omitted it from PATH;
- fails early if the active Python does not match the project interpreter.

This prevents the observed CMake failure where the current shell used `~/.espressif/python_env/idf5.4_py3.14_env/bin/python` but `build-qemu` had been configured with `~/.espressif/tools/python/v5.4.4/venv/bin/python`.

If that mismatch has already occurred, source the latest script and delete/recreate the affected build directory. CMake build directories record their configuring interpreter.

## Install QEMU once

After ESP-IDF is available:

```bash
source scripts/efis-env.sh
python "$IDF_PATH/tools/idf_tools.py" install qemu-xtensa
source scripts/efis-env.sh
```

The original installation selected `qemu-xtensa@esp_develop_9.2.2_20250817`. The project does not hard-code that version in the environment script; it searches installed QEMU versions.

Verify:

```bash
which qemu-system-xtensa
qemu-system-xtensa --version
```

The original Mac resolved QEMU under:

```text
~/.espressif/tools/tools/qemu-xtensa/esp_develop_9.2.2_20250817/qemu/bin/qemu-system-xtensa
```

## Normal hardware build

```bash
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
idf.py set-target esp32s3
idf.py build
```

The normal defaults enable the physical N16R2's 2 MB Quad PSRAM and keep bench simulation OFF.

## QEMU configuration

QEMU uses a separate `build-qemu` directory and overlays `sdkconfig.qemu.defaults` on the normal defaults. The overlay enables `CONFIG_EFIS_BENCH_SIMULATION` and `CONFIG_EFIS_QEMU` but explicitly contains:

```text
# CONFIG_SPIRAM is not set
```

That PSRAM override is essential. The physical ESP32-S3-WROOM-1-N16R2 has external Quad PSRAM, but this QEMU configuration does not provide that physical device. When QEMU inherited `CONFIG_SPIRAM=y`, boot failed before `app_main()` with:

```text
assert failed ... s_psram_chip_init
esp_psram_init
Rebooting...
```

Disabling SPIRAM only in `sdkconfig.qemu.defaults` fixes the emulator configuration without changing the real-hardware configuration.

## Clean QEMU build

After any QEMU Kconfig/defaults change, or after an ESP-IDF Python mismatch, rebuild from scratch:

```bash
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
rm -rf build-qemu

idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  set-target esp32s3

idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  build
```

The generic ESP-IDF message after a successful build may suggest `idf.py flash`. **Do not flash `build-qemu` to hardware.**

## Run QEMU graphics

```bash
idf.py -B build-qemu qemu --graphics monitor
```

The emulator uses Espressif's `esp_lcd_qemu_rgb` virtual 480×480 RGB565 display. Physical LCD, MCP23008, encoder, backlight and sensor initialization are bypassed. Synthetic pitch/roll/altitude/heading are enabled and every page must display the red **SIM** marker.

To capture a fault:

```bash
rm -f qemu.log
idf.py -B build-qemu qemu --graphics monitor 2>&1 | tee qemu.log
```

Then inspect it with:

```bash
grep -B 60 -A 15 -E "Guru|panic|abort|assert|Backtrace|Rebooting" qemu.log | tail -200
```

## Troubleshooting

**`qemu-system-xtensa` not found:** source `scripts/efis-env.sh`. Espressif's `idf_tools.py export` was observed not to add the installed `~/.espressif/tools/tools/qemu-xtensa/.../qemu/bin` directory; the script handles it.

**Python environment mismatch:** source `scripts/efis-env.sh`, confirm the summary shows `~/.espressif/tools/python/v5.4.4/venv/bin/python`, then delete/recreate the affected build directory.

**QEMU reboots in `esp_psram_init`:** pull the current repository, confirm `sdkconfig.qemu.defaults` has `# CONFIG_SPIRAM is not set`, delete `build-qemu` and recreate it using both defaults files.

**`dyld: Library not loaded`:** install the named Homebrew dependency. The observed requirements were `libgcrypt` and `sdl2`.

**Simulation unexpectedly disabled in QEMU:** recreate `build-qemu` with both `sdkconfig.defaults` and `sdkconfig.qemu.defaults`.

**Simulation unexpectedly enabled in a hardware build:** stop. Delete the normal build directory, rebuild from normal defaults and verify `BENCH SIMULATION: OFF` before any hardware/aircraft use.

## Safety boundary

QEMU and bench simulation are development facilities only. Synthetic data must never activate as a fallback for a missing, failed or stale real sensor. A real-source failure must produce an unmistakable invalid indication.

Keep `build` and `build-qemu` separate. Never flash `build-qemu` to aircraft hardware. The ESP32 EFIS remains a supplementary/non-primary experimental instrument.
