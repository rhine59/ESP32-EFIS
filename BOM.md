# Bill of Materials

This BOM records the evolving reference hardware for the ESP32 supplementary multifunction flight instrument. Supplier prices/stock in the original prototype list were checked 14 September 2026 and must be rechecked before ordering.

## Core prototype — already selected

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU | ESP32-S3-WROOM-1-N16R2 | 2 | 16 MB flash, 2 MB Quad PSRAM; one spare recommended |
| IMU | Bosch SHUTTLE BOARD 3.0 BMI088 | 1 | Pitch/roll AHRS sensor, SPI |
| Display | Newhaven NHD-2.1-480480AF-ASXP | 1 | 480×480 round IPS, ST7701S |
| Display bench adapter | Newhaven NHD-FFC40 | 1 | Bench only |
| Backlight driver | Adafruit TPS61169 PID 6354 | 1 | Constant-current boost/PWM |
| Encoder | Bourns PEC09-2320F-T0015 | 1 | Rotate + push control |
| Prototype expander | MCP23008-E/P | 1 | Bench version; final PCB SMD |

## New multifunction dependencies — buy for bench development

The new Altimeter and Compass pages require real sensors before they can be enabled outside simulation.

| Item | Qty | Status / purpose |
|---|---:|---|
| Precision barometric/static-pressure sensor breakout | 1 | **Required for Altimeter. Selection not frozen yet.** Buy only after sensor comparison; candidates should include modern BMP390-class and DPS310-class devices. Prefer a breakout with documented 3.3 V I²C/SPI interface for bench work. |
| Static-pressure pneumatic hardware | set | **Required for aircraft installation, not for initial electronics bench test.** Static port/source, suitable small-bore tubing, secure fittings and strain relief depend on aircraft installation. Do not select plumbing from the electronics BOM alone. |
| 3-axis magnetometer breakout | 1 | **Required if Compass is to show magnetic heading. Selection not frozen yet.** Must support remote mounting away from panel magnetic/current interference. |
| Magnetometer harness/connector | 1 | Final length/connector TBD after installation survey; twisted/secured wiring and remote mounting preferred. |

**Do not order the pressure sensor or magnetometer solely from a generic module name yet.** Their exact parts affect the carrier PCB, connector allocation, enclosure penetrations and calibration strategy. The firmware currently simulates these sources explicitly for bench screen testing.

## Custom carrier PCB — parked / do not order yet

Revision A must now reserve expansion for the new functions before layout resumes:

- 3.3 V sensor power and ground
- accessible I²C bus for pressure sensor and/or remote magnetometer
- at least one spare interrupt/input where practical
- locking connector for pressure sensor if it is not PCB-mounted
- locking connector for remotely mounted magnetometer
- test points for sensor bus and power
- original ESP32, USB-C, TPS62162-Q1, MCP23008, LCD FFC, BMI088, encoder and TPS61169 interfaces

The PCB remains approximately 68 mm diameter / 60 mm mounting PCD, but connector placement must be revisited before fabrication.

## Mechanical / installation items

- ASA/ABS/engineering-filament enclosure set; no PLA for cockpit article
- ~62 mm × 2 mm hard-coated AR optical polycarbonate window
- four M5 brass inserts and matching screws after CAD fit confirmation
- M2/M2.5/M3 retention hardware as finalized by physical fit checks
- thin black silicone/EPDM window perimeter gasket if required
- USB-C data/power cable and regulated 5 V bench supply
- proper wire, locking connectors, heat-shrink and strain relief; no loose Dupont wiring in the assembled article
- future static-pressure tube pass-through/fitting provision
- future remote-magnetometer cable pass-through/strain relief provision

## Functional sensor map

| Panel | Primary data source | Current state |
|---|---|---|
| Horizon/PFD | BMI088 + quaternion AHRS | BMI088 communication exists; live AHRS pending |
| Altimeter | static-pressure sensor + QNH | simulated only; pressure sensor TBD |
| Compass | absolute heading source, preferably remote magnetometer/fusion | simulated only; heading sensor TBD |

GNSS may later provide **TRK** and **GS**, but neither is to be mislabeled as magnetic heading or IAS.

## Simulation and flight-build rule

The repository contains an explicit synthetic-data simulator so all three displays can be exercised before the extra sensors arrive. Simulation must be disabled before any aircraft-use firmware build. Synthetic values must never silently substitute for a failed real sensor.

## Mechanical impact of new sensors

The 3 1/8-inch front-panel envelope does **not** need to grow simply because Altimeter and Compass were added. The display and encoder remain unchanged. Expected changes are internal/rearward: connector clearance, a static-pressure tube/fitting route, and a strain-relieved cable route for a preferably remote magnetometer. The current 58 mm body depth is retained as the design target until real sensor/connector fit checks prove otherwise.

## Key existing design constraints

- ESP32-S3-WROOM-1-N16R2, not an Octal-PSRAM variant under the current GPIO map
- two 480×480 RGB565 buffers require 921,600 bytes
- LCD uses 16-bit RGB565, 30 MHz RGB timing baseline
- normal flight firmware keeps Wi-Fi/Bluetooth disabled unless deliberately needed
- supplementary/non-primary instrument; fail-obvious validity handling remains mandatory
