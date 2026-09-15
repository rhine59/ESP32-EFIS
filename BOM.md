# Bill of Materials

Evolving reference BOM for the ESP32 supplementary/non-primary multifunction flight instrument. Prices/stock are snapshots; recheck before ordering.

## Core prototype

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU | **ESP32-S3-WROOM-1-N16R2** | 2 | 16 MB flash, 2 MB Quad PSRAM; spare recommended |
| Attitude IMU | **Bosch SHUTTLE BOARD 3.0 BMI088** | 1 | SPI; rigid aircraft-axis mounting |
| Display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 480×480 round IPS, ST7701S |
| Display bench adapter | **Newhaven NHD-FFC40** | 1 | Bench only |
| Backlight driver | **Adafruit TPS61169 PID 6354** | 1 | Constant-current boost/PWM |
| User control | **Bourns PEC09-2320F-T0015** | 1 | Rotate + push |
| Prototype expander | **MCP23008-E/P** | 1 | Bench version; final PCB SMD |

## Multifunction sensors — choices frozen

| Function | Reference choice | Qty | UK source / checked price | Notes |
|---|---|---:|---|---|
| Static pressure / Altimeter | **Bosch BMP585** | 1 | DigiKey UK bare IC ~£3.34 ex VAT | Robust gel-filled BMP58x pressure sensor, 300–1250 hPa |
| First pressure module | **Adafruit BMP585 Ported breakout PID 6413** | 1 | DigiKey UK ~£11.33 ex VAT at 15 Sep 2026 check | Preferred first plumbing/bench module because it is ported; I2C/SPI |
| Magnetic heading | **PNI RM3100-CB, P/N 14754** | 1 | Solsta UK ~£46 ex VAT at 15 Sep 2026 check | Remote-mounted reference magnetometer; I2C/SPI; ruggedized compact board |

BMP585 replaces the briefly considered BMP581 because its gel-filled robust construction and available **ported development board** are more useful for an aircraft static-system prototype. Bosch specifies ±6 Pa typical relative accuracy and 0.08 Pa RMS noise; maximum absolute accuracy is ±50 Pa, so correct QNH/reference pressure remains essential.

## Still to freeze after physical fit

| Item | Requirement |
|---|---|
| Static-line bulkhead/tube fitting | Match the Skyranger's actual static tubing. Rear cover has a 12 mm reinforced boss with 3 mm pilot hole. |
| Pressure module mounting | First article may retain the ported Adafruit BMP585 module. After tests, decide whether final PCB uses bare BMP585 + engineered plenum or a separately mounted ported module. |
| Magnetometer connector/gland | Locking/strain-relieved and preferably non-magnetic; second 12 mm rear boss has 3 mm pilot hole. |
| RM3100-CB harness | 3.3 V/GND plus selected bus; routing/shield/twist after cable/EMC tests. |
| Remote magnetometer bracket | Rigid non-magnetic mount with FWD/UP/lateral-axis marks. |

## Custom carrier PCB — parked / do not order yet

Revision A retains ESP32, USB-C, TPS62162-Q1, MCP23008, LCD FFC, BMI088, encoder and TPS61169 interfaces and must now reserve: BMP58x pressure interface/mounting strategy, 3.3 V sensor bus/test points, locking RM3100-CB connector and spare interrupt/input where practical. Target remains ~68 mm diameter on 60 mm mounting PCD.

## Mechanical / installation

Use engineering filament (not PLA), hard-coated AR window, verified threaded hardware, locking wiring and strain relief. No loose Dupont wiring in assembled article. Static tubing/fitting is selected only after aircraft tubing is measured; RM3100-CB uses non-magnetic remote mounting hardware.

The 3 1/8-inch face and 58 mm depth remain the target. Current CAD changes only the rear cover by adding adaptable STATIC and MAG service bosses.

## Functional dependency map

| Panel | Required source |
|---|---|
| Horizon/PFD | BMI088 + live quaternion AHRS |
| Altimeter | BMP585 static pressure + QNH |
| Compass | remote RM3100-CB + BMI088 attitude for tilt-compensated magnetic heading |
| Future PFD TRK/GS | GNSS, explicitly labelled TRK/GS |

Bench simulation is permitted only when explicitly enabled. Aircraft-use firmware must have simulation disabled. Missing/stale/implausible source data invalidates the corresponding indication.

See `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md` and `docs/user-guides/`.
