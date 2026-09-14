# Deploying the firmware to the ESP32-S3

This guide explains how to build, flash and monitor the artificial-horizon firmware on the project **ESP32-S3-WROOM-1-N16R2** hardware from macOS.

The firmware is an ESP-IDF project rooted at `firmware/` and currently targets **ESP-IDF v5.4.4**.

> **Important:** this project is a supplementary/non-primary flight-development instrument. Do not use a newly flashed build in the aircraft until the display, sensor, failure-state and power-up behaviour have been bench-tested.

## 1. Hardware connection

The custom carrier uses the ESP32-S3 native USB connection:

- GPIO19 = USB D-
- GPIO20 = USB D+
- USB-C VBUS = regulated 5 V instrument input
- USB ground = carrier ground

The ESP32-S3 can be flashed directly over native USB; no external USB-to-UART adapter is required for the normal deployment path.

For first bring-up, connect the board directly to the Mac with a known-good **USB data cable**. Avoid hubs initially.

## 2. Install ESP-IDF on the Mac

The project baseline is ESP-IDF **v5.4.4**. Keep the development machine on that version until the project is deliberately migrated and CI is updated.

Espressif's Installation Manager can install a specific version. If the GUI has already installed v5.4.4, the normal activation script on macOS is:

```bash
source "$HOME/.espressif/tools/activate_idf_v5.4.4.sh"
```

If the Python environment was not created during installation, initialise it once with:

```bash
cd "$HOME/.espressif/v5.4.4/esp-idf"
./install.sh esp32s3
```

Then activate ESP-IDF again:

```bash
source "$HOME/.espressif/tools/activate_idf_v5.4.4.sh"
```

Verify the active toolchain:

```bash
idf.py --version
which idf.py
which python
python --version
```

Expected ESP-IDF result:

```text
ESP-IDF v5.4.4
```

The Python executable should normally be inside Espressif's dedicated environment under `~/.espressif/python_env/` rather than an unrelated pyenv/virtualenv environment.

Do not place the repository in a filesystem path containing spaces; ESP-IDF does not support project paths containing spaces reliably.

## 3. Clone or update the project

If cloning for the first time, do not create the target directory manually first. Let Git create it:

```bash
cd ~/Documents/Xcode
git clone https://github.com/rhine59/ESP32-Artificial-Horizon.git
cd ESP32-Artificial-Horizon
```

If the repository is already present:

```bash
cd ~/Documents/Xcode/ESP32-Artificial-Horizon
git pull
```

Then enter the firmware project:

```bash
cd firmware
```

## 4. Select the ESP32-S3 target

Normally this only needs doing when creating a fresh build directory or after a major configuration change:

```bash
idf.py set-target esp32s3
```

The project also contains `sdkconfig.defaults`, which records the intended flash/PSRAM configuration for the N16R2 module.

## 5. Build before flashing

Always build locally before deploying:

```bash
idf.py build
```

A successful build ends with output similar to:

```text
Successfully created esp32s3 image.
Project build complete. To flash, run:
 idf.py flash
```

The generated application binary is:

```text
firmware/build/esp32_artificial_horizon.bin
```

The repository also has GitHub Actions CI for the same ESP32-S3 firmware using ESP-IDF v5.4.4. Local deployment should preferably be done from a commit whose firmware CI build is green.

## 6. Find the USB device on macOS

With the ESP32 connected, list likely serial devices:

```bash
ls /dev/cu.usbmodem*
```

You may see something similar to:

```text
/dev/cu.usbmodem1101
```

Use the actual device shown by your Mac.

If no device appears, check:

1. the cable supports data, not charging only;
2. the board is powered;
3. GPIO19/20 are correctly connected to USB D-/D+;
4. no other hardware is loading GPIO19/20;
5. the ESP32 is in download mode if this is the first flash.

## 7. First flash / force download mode

For an ESP32-S3 that has not yet been programmed, or if automatic reset into download mode fails:

1. press and hold **BOOT**;
2. press and release **RESET/EN**;
3. release **BOOT**;
4. re-run the device listing command if necessary.

Then flash using the detected port:

```bash
idf.py -p /dev/cu.usbmodem1101 flash
```

Replace `/dev/cu.usbmodem1101` with the actual device name.

The ESP32-S3 ROM bootloader supports flashing directly through the native USB connection.

## 8. Flash and immediately monitor

During development the most useful command is:

```bash
idf.py -p /dev/cu.usbmodem1101 flash monitor
```

This:

1. rebuilds changed files if necessary;
2. flashes the firmware;
3. resets the ESP32;
4. opens the serial log monitor.

Exit the ESP-IDF monitor with:

```text
Ctrl-]
```

## 9. Expected first-boot behaviour

The current proof-of-life firmware should perform this sequence:

1. boot the ESP32-S3;
2. keep the display backlight off;
3. hold BMI088 chip-selects inactive;
4. initialize the MCP23008;
5. reset the ST7701S display controller;
6. run the Newhaven-derived ST7701S initialization sequence;
7. configure the RGB interface at 480 × 480 RGB565;
8. allocate two PSRAM-backed framebuffers;
9. render the static artificial horizon;
10. enable the display backlight;
11. initialize the BMI088 SPI bus;
12. identify the BMI088 accelerometer and gyro.

The display should show a static test attitude containing:

- blue sky;
- brown ground;
- white horizon line;
- pitch-ladder marks;
- fixed yellow aircraft symbol.

This is deliberately not yet a live attitude solution.

## 10. What to look for in the serial log

Typical startup logging should confirm the major initialization stages. In particular, verify that:

- the MCP23008 initializes at address `0x20`;
- the RGB display initializes successfully;
- the static horizon is rendered before the backlight is enabled;
- the BMI088 accelerometer chip ID is `0x1E`;
- the BMI088 gyro chip ID is `0x0F`.

Any BMI088 communication problem should be investigated before continuing into AHRS development.

## 11. Normal firmware update workflow

For subsequent firmware changes, the normal sequence is:

```bash
cd ~/Documents/Xcode/ESP32-Artificial-Horizon
git pull

source "$HOME/.espressif/tools/activate_idf_v5.4.4.sh"

cd firmware
idf.py build
idf.py -p /dev/cu.usbmodem1101 flash monitor
```

Usually it is not necessary to run `set-target` again.

## 12. Clean rebuild

If the build configuration becomes inconsistent after significant changes:

```bash
idf.py fullclean
idf.py set-target esp32s3
idf.py build
```

Then flash normally.

Do not use `fullclean` routinely; it deletes generated build state and makes the next build slower.

## 13. Erase flash completely

If the ESP32 behaves unexpectedly because of stale NVS, partition or boot data, a complete flash erase may be useful during bench development:

```bash
idf.py -p /dev/cu.usbmodem1101 erase-flash
```

Then rebuild and reflash:

```bash
idf.py build
idf.py -p /dev/cu.usbmodem1101 flash monitor
```

Do not perform an erase casually once calibration or other persistent data is introduced; future versions of the firmware may store calibration values in NVS.

## 14. If flashing fails

### `No serial data received`

Force download mode manually using BOOT + RESET/EN, then try again.

### No `/dev/cu.usbmodem*` device

Check the USB data cable, power, connector soldering and GPIO19/20 routing. Test without a hub.

### Port disappears after flashing

The ESP32-S3 may re-enumerate after reset. Re-run:

```bash
ls /dev/cu.usbmodem*
```

and use the new device name.

### Build fails before flashing

Confirm the environment first:

```bash
idf.py --version
```

Then try:

```bash
idf.py fullclean
idf.py set-target esp32s3
idf.py build
```

### Display remains black

Check serial logs before changing firmware. Specifically verify:

- MCP23008 communication;
- LCD reset and chip-select control;
- 3.3 V LCD logic supply;
- TPS61169 backlight supply;
- FFC orientation;
- ST7701S mode straps IM0=0, IM1=1, IM2=0;
- backlight PWM output;
- 30 MHz RGB timing wiring and data-bus continuity.

A black display can be either an LCD logic problem or simply a backlight problem, so distinguish those before debugging graphics code.

## 15. Deployment discipline for this project

For every firmware revision intended for hardware testing:

1. commit the code to GitHub;
2. confirm the GitHub firmware CI build succeeds;
3. pull that exact commit onto the Mac;
4. build locally;
5. flash over USB;
6. capture and inspect the startup log;
7. confirm the display test pattern;
8. confirm BMI088 chip IDs;
9. record any hardware/firmware anomaly before changing multiple variables at once.

For later flight-development builds, also record the Git commit SHA installed in the instrument so the running firmware can always be traced back to its exact source revision.

## 16. Current safety limitation

The present build shows a static artificial-horizon test screen and verifies basic BMI088 communication. It is **not yet a live AHRS**.

Do not interpret the displayed horizon as aircraft attitude until the live sensor pipeline, gyro calibration, quaternion AHRS, validity monitoring and unmistakable `ATTITUDE INVALID` state have all been implemented and tested.
