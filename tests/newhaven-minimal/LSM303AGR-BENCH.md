# Temporary LSM303AGR heading sensor — wiring and GPIO audit

**Status (20 Nov 2026):** Adafruit LSM303AGR STEMMA QT/Qwiic PID 4413 ordered, not received. Replaces RM3100-CB **temporarily** for bench magnetic-field and heading development; PNI RM3100-CB 14754 remains final target. No live sensor testing or aircraft calibration has occurred.

## Current physical display allocation (ESP32-S3 N16R8)

LCD: GPIO1 (PCLK), 2 (DE), 4–18 and 21 (RGB), 38/39 (sync), 35/36 (serial LCD control), 40/41 (CS/reset), 42 (PWM). BOOT GPIO0 must remain usable. Native USB uses GPIO19/20. GPIO3,45,46 are strapping/special-purpose and should not be allocated casually; GPIO26–32 and some additional pins are tied to flash/PSRAM on this module; GPIO43/44 are often UART0; availability of GPIO33/34/37 and GPIO47/48 depends on the exact development board and memory wiring. **Do not interpret numeric GPIO gaps as exposed, usable pins.**

## Proposed shared I2C (NOT CONNECT UNTIL BOARD PINOUT CONFIRMED)

| Signal | Candidate ESP32 GPIO | Notes |
|---|---|---|
| LSM303AGR VIN | 3V3 | Adafruit breakout regulator; 3.3V preferred for ESP32 |
| LSM303AGR GND | GND | Common ground |
| LSM303AGR SDA | GPIO47 | Candidate only: check exposed pad and no conflicts |
| LSM303AGR SCL | GPIO48 | Candidate only: check exposed pad and no conflicts |

LSM303AGR magnetometer 7-bit I2C address `0x1E` (WHO_AM_I_M register `0x4F`, expected `0x40`); accelerometer address `0x19` (not needed for heading; BMI088 is attitude source). BMP585 can share the same I2C wires if its address and electrical loading are compatible. A STEMMA QT cable plus the already-received QT breadboard adapter can be used. **Do not attach until the development-board pin labels have been checked.**

The existing `firmware/include/pins.h` is for a **different custom carrier design**: it allocates 35/36 to SPI and 40/41 to BMI088, which conflicts with the validated display bench. Do not flash carrier firmware onto this breadboard as though its GPIO assignments were valid. BMI088 needs SCK, MOSI, MISO and two chip selects, so its simultaneous connection remains **unresolved** until the exact dev-board breakout and possible pin reassignment/expander are reviewed. GPIO47/48 alone do not solve the full pin budget.

## Firmware

`firmware/main/lsm303agr.c` provides an I2C magnetometer driver (identity verification, continuous mode, three-axis field in microtesla) using a caller-owned I2C bus. It is compiled into the carrier firmware but **not activated at runtime**; the validated no-PSRAM display diagnostic is unchanged. Future work: board-pin audit, I2C chip-ID diagnostic, magnetic calibration, axis mapping and tilt compensation; never present raw magnetic bearing as validated flight heading.

## Shared I2C BMI088 option (software prepared, NOT wired or activated)

Bosch Shuttle Board 3.0 P1: pin 1 VDD -> 3V3; pin 2 VDDIO -> 3V3; pin 3 GND -> GND. P2: pin 1 CS -> 3V3 (accelerometer I2C); pin 2 SCK/SCL -> shared SCL; pin 4 SDI/SDA -> shared SDA; pin 6 GPIO5/PS -> 3V3 (gyro I2C); pin 5 GPIO4/gyro CS -> leave disconnected in I2C mode; pin 3 SDO is shared accelerometer/gyro address selection and must be tied to GND to select 0x18 and 0x68. **Check board jumper and pin-1 orientation before applying power.** P1 interrupt pins remain disconnected. The BMI088 accel address 0x18 avoids the LSM303AGR accel 0x19. See Bosch BMI088 Shuttle Board 3.0 flyer and BMI088 datasheet.

The new `firmware/main/bmi088_i2c.c` offers separate opt-in I2C init/read/deinit functions and does not change the SPI transport or the validated LCD test. No electrical or motion validation has been performed.
