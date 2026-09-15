# macOS build and QEMU setup

This document records the complete setup needed to build and run the ESP32 EFIS firmware on a new Apple Silicon Mac, including the problems encountered during the first working installation.

The project currently targets **ESP32-S3** and is built with **ESP-IDF v5.4.4**. QEMU is used only for development/simulation. The aircraft firmware must keep synthetic data disabled.

## 1. Prerequisites

Install Apple's command-line developer tools if they are not already present:

```bash
xcode-select --install
```

Install Homebrew if required, then make sure `git` is available:

```bash
git --version
brew --version
```

The Espressif QEMU binary used on Apple Silicon also required these Homebrew runtime libraries during the original installation:

```bash
brew install libgcrypt sdl2
```

The missing-library failures that led to these dependencies were:

```text
Library not loaded: /opt/homebrew/opt/libgcrypt/lib/libgcrypt.20.dylib
Library not loaded: /opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib
```

They can be checked with:

```bash
ls -l /opt/homebrew/opt/libgcrypt/lib/libgcrypt.20.dylib
ls -l /opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib
```

## 2. Clone the ESP32 EFIS repository

Clone the private repository using the GitHub authentication method configured on the Mac, then enter it:

```bash
git clone https://github.com/rhine59/ESP32-EFIS.git
cd ESP32-EFIS
```

For an existing checkout:

```bash
cd ~/ESP32-EFIS
git pull
```

## 3. Install ESP-IDF v5.4.4

This project is pinned to ESP-IDF **v5.4.4**. Keep that version rather than silently moving to a newer IDF release.

The working installation used this location:

```text
~/.espressif/v5.4.4/esp-idf
```

After ESP-IDF v5.4.4 has been placed there, install the ESP32-S3 toolchain and required packages:

```bash
~/.espressif/v5.4.4/esp-idf/install.sh esp32s3
```

This step is important. On the original machine an incomplete ESP-IDF installation caused activation to fail with:

```text
ERROR: tool esp-rom-elfs has no installed versions.
Please run '/Users/.../.espressif/v5.4.4/esp-idf/install.sh' to install it.
```

Running `install.sh esp32s3` installed the missing ESP-IDF tools.

## 4. Do not activate ESP-IDF from an unrelated Python venv

If the shell prompt shows another Python environment, for example:

```text
(venv) user@Mac ...
```

leave it first:

```bash
deactivate
```

ESP-IDF maintains its own Python environment under `~/.espressif/tools/python/`. Using the ESP-IDF environment avoids confusing project Python dependencies with the IDF toolchain.

## 5. Activate ESP-IDF

The repository now contains `scripts/efis-env.sh`, which is the preferred way to prepare a new Terminal session after the one-time installation is complete.

From anywhere inside the repository:

```bash
source scripts/efis-env.sh
```

If the current directory is not the repository root, source it using its full checkout path, for example:

```bash
source ~/Documents/Xcode/ESP32-EFIS/scripts/efis-env.sh
```

The script must be **sourced**, not simply executed, because `IDF_PATH` and `PATH` need to be changed in the current shell. It activates ESP-IDF v5.4.4, finds the repository root, exports `EFIS_ROOT` and `EFIS_FIRMWARE_DIR`, checks QEMU and works around the QEMU PATH issue encountered on the original Apple Silicon installation.

The manual equivalent is:

```bash
source ~/.espressif/v5.4.4/esp-idf/export.sh
```

Check the environment with:

```bash
echo $IDF_PATH
which idf.py
```

The expected `IDF_PATH` is:

```text
/Users/<username>/.espressif/v5.4.4/esp-idf
```

On this installation `idf.py` may appear as a shell function rather than a conventional executable path. That is normal; the function invokes ESP-IDF's own Python interpreter and `tools/idf.py`.

If activation reports that an ESP-IDF tool has no installed version, run:

```bash
~/.espressif/v5.4.4/esp-idf/install.sh esp32s3
```

and activate again.

## 6. Install Espressif QEMU

With ESP-IDF activated:

```bash
python "$IDF_PATH/tools/idf_tools.py" install qemu-xtensa
```

On the original Apple Silicon Mac this installed:

```text
qemu-xtensa@esp_develop_9.2.2_20250817
```

Do not depend on that exact QEMU package version forever: `idf_tools.py` should select the QEMU version appropriate to the installed ESP-IDF tools manifest.

If installation fails because `libgcrypt` is absent:

```bash
brew install libgcrypt
python "$IDF_PATH/tools/idf_tools.py" install qemu-xtensa
```

If it then fails because SDL2 is absent:

```bash
brew install sdl2
python "$IDF_PATH/tools/idf_tools.py" install qemu-xtensa
```

After QEMU installs successfully, refresh the environment:

```bash
source "$IDF_PATH/export.sh"
```

On the original machine `idf_tools.py` installed QEMU below:

```text
~/.espressif/tools/tools/qemu-xtensa/<version>/qemu/bin
```

but `idf_tools.py export` did not include that directory in `PATH`. `scripts/efis-env.sh` detects this condition and adds an installed `qemu-system-xtensa` automatically rather than requiring the long path to be entered for every shell.

Verify QEMU with:

```bash
which qemu-system-xtensa
qemu-system-xtensa --version
```

Do not proceed to QEMU testing until the version command runs without a dynamic-library error.

## 7. Build the normal ESP32-S3 firmware

The ordinary hardware build deliberately uses the project's normal defaults, in which bench simulation is OFF:

```bash
cd "$EFIS_FIRMWARE_DIR"
idf.py set-target esp32s3
idf.py build
```

The project also has GitHub Actions CI for the normal ESP-IDF firmware build. A successful local build and successful CI build are complementary checks.

## 8. Build the QEMU firmware separately

Never reuse the normal hardware build directory for QEMU. The project provides `sdkconfig.qemu.defaults`, which explicitly enables both the QEMU backend and synthetic bench data.

From the firmware directory:

```bash
cd "$EFIS_FIRMWARE_DIR"
rm -rf build-qemu

idf.py \
  -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  set-target esp32s3
```

Then build:

```bash
idf.py \
  -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  build
```

A successful build ends with ESP-IDF reporting that the project build is complete.

Keeping `build-qemu` separate from the normal `build` directory is a safety feature: it reduces the risk of accidentally carrying emulator/synthetic-data configuration into a hardware build.

## 9. Run the graphical EFIS in QEMU

After the QEMU build has succeeded:

```bash
idf.py -B build-qemu qemu --graphics monitor
```

The QEMU build uses Espressif's virtual RGB LCD component rather than the physical ST7701S panel interface. The virtual display is 480 × 480 RGB565, matching the EFIS instrument framebuffer.

The QEMU configuration intentionally enables synthetic pitch, roll, altitude and heading data. Simulated data is visibly marked **SIM** on the rendered instrument screens and the boot log warns that synthetic data is active.

The emulator build can automatically exercise the Horizon/PFD, Altimeter and Compass screens without requiring the physical display, BMI088, MCP23008, encoder or other bench hardware.

## 10. Safety rules

QEMU and bench simulation are development facilities only. The ESP32 EFIS is a supplementary/non-primary instrument.

`CONFIG_EFIS_BENCH_SIMULATION` defaults to OFF. Synthetic data must never be used as a fallback when a real sensor is absent, invalid or stale.

Before putting firmware on aircraft hardware, use a clean normal build and confirm the boot log contains:

```text
BENCH SIMULATION: OFF
```

Do not flash a `build-qemu` image to aircraft hardware.

## 11. New-machine quick sequence

Once Homebrew, Git and ESP-IDF v5.4.4 are available, the one-time installation is:

```bash
brew install libgcrypt sdl2

~/.espressif/v5.4.4/esp-idf/install.sh esp32s3
source ~/.espressif/v5.4.4/esp-idf/export.sh
python "$IDF_PATH/tools/idf_tools.py" install qemu-xtensa
```

After that, each new shell only needs:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
```

For a clean QEMU build:

```bash
rm -rf build-qemu
idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  set-target esp32s3
idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  build
idf.py -B build-qemu qemu --graphics monitor
```

## 12. Troubleshooting checklist

If `source .../export.sh` fails, read the first `ERROR:` line rather than reinstalling everything. A message such as `tool <name> has no installed versions` normally means the ESP-IDF tool installation is incomplete.

If `qemu-system-xtensa` is not found after ESP-IDF activation, use `source scripts/efis-env.sh`. It includes the workaround for the QEMU installation path seen on the original Mac.

If QEMU is found but terminates immediately with `dyld: Library not loaded`, install the named Homebrew dependency and retry the QEMU installation/check. The two dependencies encountered on the original Apple Silicon installation were `libgcrypt` and `sdl2`.

If a QEMU build behaves as though simulation is disabled, remove `build-qemu` and recreate it using both `sdkconfig.defaults` and `sdkconfig.qemu.defaults`. Do not modify the normal defaults to turn simulation on globally.

If a normal aircraft-target build unexpectedly reports simulation enabled, stop: delete the build directory/configuration, rebuild from the normal defaults, and verify `BENCH SIMULATION: OFF` before proceeding.
