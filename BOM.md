# Bill of Materials

Evolving reference BOM for the ESP32 supplementary/non-primary multifunction flight instrument. Prices and stock are snapshots; recheck before ordering.

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

## Multifunction sensors — choices now frozen

| Function | Reference choice | Qty | UK prototype source | Notes |
|---|---|---:|---|---|
| Static pressure / altimeter | **Bosch BMP581** | 1 final | DigiKey/Mouser | Bare IC for final carrier; 300–1250 hPa, 3.3 V-compatible I2C/SPI |
| Pressure bench module | **Adafruit BMP581 breakout PID 6407** | 1 | DigiKey UK, ~£7.45 ex VAT at 15 Sep 2026 check | Easy bench wiring; not final flight-development packaging |
| Magnetic heading | **PNI RM3100-CB, P/N 14754** | 1 | Solsta UK, ~£46 ex VAT at 15 Sep 2026 check | Remote-mounted reference magnetometer; I2C/SPI; ruggedized compact board |

The BMP581 is selected over the older BMP390/DPS310-class options because of its low noise, temperature behaviour, 300–1250 hPa range, modern active supply and strong UK availability. The RM3100-CB is selected because it is a higher-performance magneto-inductive three-axis sensor with documented vibration robustness and is suitable for remote mounting away from panel interference.

## Still to freeze after physical installation survey

| Item | Requirement |
|---|---|
| Static-line fitting | Must match the Skyranger's actual static tubing. Rear cover now has a reinforced 12 mm service boss with a 3 mm pilot hole; enlarge only to the purchased fitting. |
| BMP581 pressure plenum/seal | Sealed chamber exposing the sensor pressure opening without adhesive, coating or debris obstructing it. |
| Magnetometer connector/gland | Locking/strain-relieved and preferably non-magnetic. Rear cover has a second 12 mm service boss with a 3 mm pilot hole. |
| RM3100-CB harness | 3.3 V/GND plus selected bus; routing and shielding/twisting frozen after cable/EMC tests. |
| Remote magnetometer bracket | Rigid non-magnetic mount with FWD/UP/lateral-axis marks. |

## Custom carrier PCB — parked / do not order yet

Revision A now must include the original ESP32, USB-C, TPS62162-Q1, MCP23008, LCD FFC, BMI088, encoder and TPS61169 interfaces plus:

- bare Bosch BMP581
- sealed static-pressure plenum/interface
- 3.3 V sensor power/ground and bus test points
- locking connector for remote RM3100-CB
- spare interrupt/input where practical

The target remains about 68 mm diameter on a 60 mm mounting PCD. Connector placement must be revisited before fabrication.

## Mechanical / installation

- ASA/ABS/engineering-filament enclosure; no PLA for cockpit article
- ~62 mm × 2 mm hard-coated AR optical polycarbonate window
- verified M5/M2/M2.5/M3 inserts and screws
- thin window perimeter gasket only
- USB-C data/power cable and regulated 5 V bench supply
- proper locking wiring/strain relief; no loose Dupont wiring in assembled article
- static tubing/fitting after aircraft tubing size is confirmed
- non-magnetic remote RM3100-CB mounting hardware

The 3 1/8-inch front geometry and 58 mm depth remain the target. Only the rear cover currently changes: two adaptable service bosses are added for static pressure and the remote magnetometer harness.

## Functional dependency map

| Panel | Required source |
|---|---|
| Horizon/PFD | BMI088 + live quaternion AHRS |
| Altimeter | BMP581 static pressure + QNH |
| Compass | remote RM3100-CB + BMI088 attitude for tilt-compensated magnetic heading |
| Future PFD TRK/GS | GNSS, explicitly labelled TRK/GS |

Bench simulation is permitted only when explicitly enabled. Aircraft-use firmware must have simulation disabled. Missing/stale/implausible attitude, pressure or heading data must invalidate the corresponding indication.

See `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md` and `docs/user-guides/`.
