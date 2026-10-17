# RedOne recovery diagnostics: tests and interpretation

The recovery firmware exposes an authenticated, read-only HTTP diagnostics report to the Lollipop iOS app. Each entry reports PASS, FAIL, or SKIP and includes what was measured, what was found, and any test limitation. Before a report arrives, the app shows TODO (grey). PASS is green, FAIL red, SKIP yellow.

## Tests that perform live hardware or firmware queries

- **ESP32 memory and flash:** Reads actual flash capacity with `esp_flash_get_size`, available 8-bit heap and largest free block using heap capabilities APIs. Pass thresholds: flash at least 8 MiB, heap more than 32 KiB, largest block more than 16 KiB. Also reports the PSRAM memory visible to the recovery allocator, but does not pass/fail PSRAM: recovery builds currently have SPIRAM support disabled. This is *not* a destructive flash write/readback or a RAM pattern test.
- **Wi-Fi communications:** Queries actual Wi-Fi mode and associated SoftAP client list. PASS requires AP/APSTA mode and a successful station-list query. Reports mode and connected-client count. An authenticated HTTP response confirms the diagnostics endpoint worked; RF sensitivity, throughput, and reconnect reliability are not measured.
- **Non-volatile configuration:** Reads partition-table entries for NVS and both OTA slots and verifies recovery is executing from the factory partition. PASS requires those partitions and factory execution. Does not alter NVS, read out credentials, validate credential integrity, or prove the OTA slots contain working images.

## Tests deliberately skipped

- **Power:** No validated voltage-divider ADC pin or calibration is available; no voltage measurement is attempted.
- **Display/backlight and rotary encoder:** The carrier display, backlight and MCP23008-connected controls need a verified assembled board and non-destructive drivers plus operator confirmation. No pins are driven by recovery.
- **BMI088, BMP585, RM3100, CAN/SMUX:** The presence and electrical connection of the external peripherals on this bench have not been verified. No bus probing or output stimulation is attempted; no claim of passing these devices is made.

## Safety and scope

This is a secondary, non-certified aviation instrument. A PASS means only that the specific check described passed; it is not a flightworthiness determination. The firmware does not change NVS, OTA images, calibration, GPIO output state, or sensor configuration. The recovery app was flashed at factory application offset `0x20000` only, preserving bootloader, partition table and NVS. The ESP-IDF build and flash write/hash verification succeeded; actual values and pass/fail results should be read from Lollipop after connecting to RedOne.

## Next stage: carrier-board integration

Before enabling external component tests, confirm the assembled carrier revision, wiring, fitted peripherals and voltage domains against `firmware/include/pins.h`. Then add read-only chip-ID checks on SPI/I2C, MCP23008 input sampling, display pattern with operator acknowledgement, PWM backlight ramp with operator acknowledgement, and TWAI loopback only when a safe transceiver arrangement is validated. Distinguish device absent (SKIP), unexpected ID or bus failure (FAIL), and confirmed response (PASS).
