# RM3100 magnetometer — ESP-IDF port and validation record

**Project:** Lollipop EFIS (RedOne / Horizon), supplementary/non-primary instrument  
**Target:** ESP32-S3-WROOM-1-N16R2  
**Framework:** ESP-IDF 5.4.4  
**Recorded:** 17 October 2026  
**Status:** Driver and complete EFIS firmware compile-validated; physical hardware verification pending.

## Purpose and component decision

The EFIS BOM identifies the **PNI RM3100-CB (P/N 14754)** as the remote three-axis magnetometer. It remains a separate, remotely mounted sensor because magnetic interference from the display, backlight, switching supplies, wiring and nearby ferrous material makes an on-board magnetometer unsuitable without careful installation evidence. BMI088 supplies inertial data; BMP585 supplies pressure/temperature; GNSS selection is separate. The RM3100 is not yet purchased/bench-commissioned. This work concerns **EFIS only**, not SMUX.

An Arduino RM3100 library was identified as a reference: https://github.com/EvdokimovVladimir/RM3100 . The committed implementation is a **native ESP-IDF C adaptation of the device register protocol**, not a line-by-line translation of Arduino source. It uses the ESP-IDF 5.x `driver/i2c_master.h` API, not Arduino `Wire`.

## Files committed

- `firmware/components/rm3100/include/rm3100.h`: public driver API and types.
- `firmware/components/rm3100/rm3100.c`: I²C transactions, register operations, measurements and conversion.
- `firmware/components/rm3100/CMakeLists.txt`: component dependencies (`esp_driver_i2c`, `esp_timer`).
- `firmware/components/rm3100/README.md`: standalone usage, constraints and integration gates.
- `firmware/main/mcp23008.h` and `.c`: accessor for existing shared I²C bus handle.
- `firmware/main/CMakeLists.txt`: RM3100 component dependency.
- `firmware/main/Kconfig.projbuild`: optional diagnostic enable and configurable I²C address.
- `firmware/main/app_main.c`: diagnostic-only startup and sample logging.

The RM3100 code and integration were committed to GitHub `main`, with latest integration commit **438a614e5a11b68f78614966a6527815615af9b9**. The source of truth is GitHub: https://github.com/rhine59/ESP32-EFIS .

## Driver API and behavior

- I²C addresses **0x20–0x23** (SA1/SA0 board strapping), default 0x20.
- Initialisation, bus probe, revision-register read, device removal.
- Programmable cycle count (default 200) and TMRC register (default 0x94).
- Single-shot `POLL` and continuous three-axis `CMM` operation.
- Data-ready polling with finite timeout.
- Nine-byte XYZ measurement, sign extension of signed 24-bit axis values.
- Timestamp at read time using `esp_timer_get_time()`; **not** a hardware sample timestamp.
- Approximate raw-count to microtesla conversion based on configured cycle count.
- ESP-IDF error returns for I²C failures and invalid arguments.

### Limitations

This first port is **I²C-only**. SPI, DRDY GPIO interrupt mode and built-in self-test/BIST are not implemented. The revision register is not a unique chip identity check. Conversion to microtesla is approximate and **not** hard/soft-iron calibration. There is no tilt-compensated heading, magnetic declination handling or live EFIS compass connection. Magnetic axes, cable installation, electromagnetic interference and stale-data handling require bench validation.

The existing MCP23008 module owns the I²C master bus; the RM3100 only borrows the handle. Confirm pull-ups, electrical levels, bus loading and remote cable design before hardware use.

## Diagnostic integration

`CONFIG_EFIS_RM3100_DIAGNOSTICS` is **disabled by default**. When enabled on a non-QEMU build, the EFIS attempts to initialise the RM3100 on the MCP23008 I²C bus, starts continuous conversion, and logs revision information, XYZ magnetic readings in µT and read errors. `CONFIG_EFIS_RM3100_I2C_ADDRESS` selects 0x20–0x23.

The diagnostics deliberately **do not feed the heading display**. The live instrument remains isolated from uncommissioned sensor readings. For bench use, configure via `idf.py menuconfig` (ESP32 EFIS development options), select the actual board I²C address, and monitor serial logs. Disable the option for normal aircraft-use builds.

## Build-validation record — 17 October 2026

The Mac's local repository was still at **7f580e1**, and several `git pull --ff-only` attempts hung in Git HTTPS transfer. A separate `git ls-remote` succeeded and confirmed GitHub HEAD at **438a614e5a11b68f78614966a6527815615af9b9**. The original checkout was **not modified**. Rather than claim synchronisation, the validation used direct downloads of committed GitHub files into temporary directories.

### 1. Standalone RM3100 component

- Test project: `/tmp/rm3100-standalone`.
- Source downloaded from `firmware/components/rm3100` on GitHub `main`.
- ESP-IDF toolchain: `/Users/richardhine/.espressif/v5.4.4/esp-idf`.
- Target: `esp32s3`.
- Command: `idf.py set-target esp32s3 build`.
- **Result: PASS** — `rm3100.c` compiled, `librm3100.a` linked, `rm3100_check.bin` generated, exit status 0.
- Build log: `/tmp/rm3100-idf-build.log` (temporary Mac-local artifact).

### 2. Full EFIS, normal configuration

- Isolated test tree: `/tmp/efis-rm3100-verify`.
- Started from a copy of the existing Mac firmware tree; replaced the changed integration files with the committed GitHub versions.
- Command: `idf.py build`.
- **Result: PASS** — complete `esp32_efis.bin` generated, exit status 0.
- Log: `/tmp/efis-full-build.log`.
- This initial build used inherited QEMU configuration from the copied tree and **does not prove diagnostic code was enabled**.

### 3. Full EFIS with RM3100 diagnostics enabled

- In isolated test-tree `sdkconfig`: QEMU disabled, bench simulation disabled, `CONFIG_EFIS_RM3100_DIAGNOSTICS=y`, `CONFIG_EFIS_RM3100_I2C_ADDRESS=0x20`.
- Command: `idf.py reconfigure build`.
- Verified generated `build/config/sdkconfig.h` contained:
  - `#define CONFIG_EFIS_RM3100_DIAGNOSTICS 1`
  - `#define CONFIG_EFIS_RM3100_I2C_ADDRESS 0x20`
- **Result: PASS** — complete EFIS firmware built and linked; `esp32_efis.bin` generated, exit status 0.
- Log: `/tmp/efis-diag-build3.log`.
- Firmware binary: `/tmp/efis-rm3100-verify/build/esp32_efis.bin` (temporary Mac-local artifact; not a released image).

**Scope of PASS:** successful compiler/linker/build-system validation on ESP32-S3 with ESP-IDF 5.4.4. It is **not** evidence of sensor communication, calibrated heading, electrical suitability or aircraft readiness.

## Hardware and integration acceptance checklist

- [x] Native ESP-IDF RM3100 I²C driver committed.
- [x] Driver standalone build passes for ESP32-S3.
- [x] Full EFIS normal build passes in isolated copy.
- [x] Full EFIS diagnostic-enabled, non-QEMU build passes in isolated copy.
- [ ] Local Mac checkout synchronised to GitHub `main` (Git pull was hanging).
- [ ] RM3100 board procured and connected to known 3.3 V, GND, SDA, SCL, correct pull-ups and address straps.
- [ ] Physical probe and revision read verified.
- [ ] XYZ signs, units, sample rates, DRDY and fault/timeout behavior measured.
- [ ] Test bus sharing with MCP23008 and display activity; confirm remote cable integrity and interference.
- [ ] Add and test self-test/BIST and optionally interrupt/SPI support if needed.
- [ ] Install remotely; establish axis mapping and hard/soft-iron calibration.
- [ ] Implement tilt compensation with BMI088, magnetic/true heading handling, data age and validity.
- [ ] Review and test heading failure annunciation; only then consider connecting to display.
- [ ] Hardware firmware flash and serial monitor run (none performed in this work).

## Safety and deployment

The EFIS is supplementary/non-primary. No device was flashed and no operational firmware was deployed. Do not use the unvalidated RM3100 output for flight navigation. The default diagnostics-off setting is intentional. Avoid replacing or resetting the working device merely to demonstrate compilation.

## Next action

Resolve the Git HTTPS pull problem without overwriting local work; pull `main` into the Mac checkout; then perform a hardware bench test when the RM3100 is available. Record observed I²C address, wiring, raw XYZ samples, rotated-axis checks, error cases and any corrections here.
