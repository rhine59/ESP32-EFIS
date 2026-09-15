# Deploying the ESP32 EFIS firmware

This guide covers building, flashing and monitoring the **ESP32 EFIS** on the project **ESP32-S3-WROOM-1-N16R2** hardware from macOS. The firmware is rooted at `firmware/` and is pinned to **ESP-IDF v5.4.4**.

> **Important:** this is a supplementary/non-primary flight-development instrument. Do not use a newly flashed build in the aircraft until display, sensor, failure-state and power-up behaviour have been bench-tested.

## Development shell

The repository provides the standard environment setup script. In every new Terminal session:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
```

The script pins the known ESP-IDF v5.4.4 Python interpreter, configures `IDF_PATH`, prevents competing ESP-IDF Python environments from being mixed within a CMake build, and makes the installed QEMU binary available when Espressif's normal export omits its path.

For complete first-time Mac installation instructions see `../docs/MACOS_BUILD_AND_QEMU_SETUP.md`.

## Hardware connection

The carrier uses ESP32-S3 native USB:

- GPIO19 = USB D-
- GPIO20 = USB D+
- USB-C VBUS = regulated 5 V instrument input
- USB ground = carrier ground

Use a known-good USB data cable and avoid hubs during first bring-up.

## Normal hardware build

Normal aircraft-target development uses `sdkconfig.defaults`. It enables the N16R2's physical 2 MB Quad PSRAM and does **not** enable synthetic bench data.

```bash
cd "$EFIS_FIRMWARE_DIR"
idf.py set-target esp32s3
idf.py build
```

A successful build produces the `esp32_efis` application. Prefer deployment from a commit whose firmware CI build is green.

Before flashing an aircraft-target build, confirm QEMU/simulation configuration has not leaked into the normal build. QEMU has its own `build-qemu` directory and must never be used as the source of a hardware flash.

## Find the USB device

```bash
ls /dev/cu.usbmodem*
```

Use the actual device shown by the Mac, for example `/dev/cu.usbmodem1101`.

If automatic download mode fails, hold **BOOT**, press/release **RESET/EN**, then release **BOOT** and retry.

## Flash and monitor

```bash
idf.py -p /dev/cu.usbmodem1101 flash monitor
```

Replace the port with the actual device. Exit the ESP-IDF monitor with `Ctrl-]`.

For an aircraft-target build, verify the startup log reports:

```text
BENCH SIMULATION: OFF
```

If simulation is unexpectedly enabled, stop and do not use that image on hardware.

## Clean normal rebuild

After a significant configuration change or interpreter mismatch:

```bash
rm -rf build
idf.py set-target esp32s3
idf.py build
```

Deleting the build directory is also the safest recovery when CMake reports that the project was configured with a different Python interpreter.

## QEMU is not a deployment image

QEMU uses `sdkconfig.qemu.defaults`, enables synthetic data and the virtual display, and explicitly disables external SPIRAM because the emulated target does not provide the physical N16R2 PSRAM device in this configuration. A QEMU image is for desktop simulation only.

A clean emulator build is:

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

See `../docs/SIMULATION.md` for the simulation safety contract.

## Expected physical bring-up checks

On physical hardware, verify the MCP23008 initializes, the ST7701S/RGB display starts correctly, PSRAM allocation succeeds, the backlight behaves correctly, and the BMI088 accelerometer/gyro identities are valid. The BMI088 accelerometer chip ID is `0x1E` and gyro chip ID is `0x0F`.

The three-page UI and control framework now exists, but live sensor integration remains under development. A page must show an unmistakable invalid state whenever its real source is unavailable or stale; a plausible frozen value is unacceptable.

## Erase flash

During bench development, stale NVS/partition state can be removed with:

```bash
idf.py -p /dev/cu.usbmodem1101 erase-flash
```

Then rebuild and reflash. Do not erase casually once calibration data is stored persistently.

## Troubleshooting

If the build reports two different ESP-IDF Python paths, pull the latest repository, source `scripts/efis-env.sh`, delete the affected build directory and recreate it. Do not try to continue using a CMake directory configured by another interpreter.

If the physical display remains black, inspect serial logs before changing firmware. Check MCP23008 communication, LCD reset/chip-select, 3.3 V logic supply, TPS61169/backlight power, FFC orientation, ST7701S mode straps and RGB bus continuity.

If QEMU continuously reboots with an assertion in `s_psram_chip_init` / `esp_psram_init`, the QEMU build was created without the emulator PSRAM override. Pull the current repository, delete `build-qemu` and rebuild using both defaults files. `sdkconfig.qemu.defaults` must contain `# CONFIG_SPIRAM is not set`.

## Deployment discipline

For every firmware revision intended for hardware testing: commit/push the source, confirm firmware CI, pull the exact commit to the Mac, source `scripts/efis-env.sh`, build locally, flash over native USB, inspect the complete startup log, test all available failure states and record the Git commit installed in the instrument.

The ESP32 EFIS remains experimental and **supplementary/non-primary**. Live AHRS, altitude and heading indications are not considered trustworthy merely because they render convincingly; each sensing path requires calibration, freshness/health monitoring and progressive bench/aircraft comparison testing.
