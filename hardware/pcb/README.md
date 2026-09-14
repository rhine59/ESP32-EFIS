# Custom Carrier PCB — Revision A requirements

This directory records the physical and layout requirements for the custom ESP32-S3 carrier PCB.

## Board role

The PCB replaces the ESP32 development board and the former printed electronics carrier. It mounts directly to the four rear-cover standoffs in the instrument enclosure.

## Mechanical definition

- nominal board outline: **68.0 mm diameter**
- board thickness: **1.6 mm FR-4** starting point
- four mounting holes: **2.7 mm diameter**
- mounting pattern: **60.0 mm PCD**, holes at 45/135/225/315 degrees
- USB-C connector located near 6 o'clock to align with rear service slot
- ESP32-S3-WROOM-1-N16R2 placed near 12 o'clock with antenna at board edge
- antenna region to use explicit copper/component/metal keepout and board-edge cutout as required by Espressif guidance

A printable mechanical gauge is generated as:

`enclosure/stl/ESP32_Artificial_Horizon_Custom_PCB_Fit_Gauge.stl`

Print and test the gauge before ordering PCBs.

## Preferred layer stack

Four layers:

1. Top — components/signals
2. Inner 1 — continuous GND
3. Inner 2 — power and limited signals
4. Bottom — limited signals / GND fill

Do not route signals through the ESP32 antenna keepout.

## Placement zones

### 12 o'clock — ESP32 module

- ESP32-S3-WROOM-1-N16R2
- antenna facing board edge
- EN/BOOT passives nearby
- local 3.3 V decoupling close to module supply pads

### 6 o'clock — USB-C

- USB-C receptacle centered on rear service slot
- ESD array immediately behind connector
- CC resistors close to connector
- D+/D- route directly toward GPIO19/20

### Power regulator zone

- TPS62162-Q1
- input capacitor, regulator, inductor and output capacitor in one tight switching cell
- place away from BMI088 connector/cradle and ESP32 antenna
- minimize SW copper area

### Display connector zone

- 40-pin FFC connector oriented to minimize FFC twist and RGB trace length
- PCLK route short with optional source-series resistor footprint
- RGB data and timing traces referenced to uninterrupted ground

### BMI088 connector zone

- located as close as practical to the rigid BMI088 cradle
- no switching regulator inductor/node nearby
- SCLK/MOSI/MISO short and ground referenced

### MCP23008 zone

- SMD MCP23008 with local 100 nF decoupling
- short I2C traces
- encoder harness connector nearby if mechanically practical

## Routing priorities

1. USB D+/D-
2. 3.3 V power integrity and ground plane
3. LCD PCLK/timing
4. RGB565 bus
5. BMI088 SPI
6. I2C / encoder / control
7. backlight PWM and slow signals

## EMI/noise separation

Keep these noisy elements away from the IMU path:

- TPS62162 switch node and inductor
- TPS61169 board/wiring
- LCD PCLK
- high-current backlight loops

Ground-stitch around noisy zones while respecting the antenna keepout.

## Connector philosophy

Flight-development assembly must use locking or positively retained connectors. No Dupont jumpers should remain in the assembled instrument.

Revision A interfaces:

- J1 USB-C
- J2 40-pin LCD FFC
- J3 BMI088 harness/carrier connector
- J4 rotary encoder harness
- J5 TPS61169 plug-in backlight-driver interface

## Test points

Provide labeled access to at least:

- +5V_USB
- +3V3_SYS
- GND
- EN
- GPIO0/BOOT
- GPIO44 spare/debug
- regulator PG
- SPI SCLK/MOSI/MISO
- BMI088 ACC_CS
- BMI088 GYRO_CS
- I2C SDA/SCL
- LCD PCLK
- backlight PWM

High-speed test pads should be compact and avoid long stubs.

## Revision-A exclusions

Do **not** integrate these yet:

- bare TPS61169 LED driver
- BMI088 sensor IC directly on the main PCB
- aircraft 12 V input/transient protection
- GNSS
- ambient light sensor

Those can follow once the display, USB, regulator and AHRS paths are proven.

## Fabrication review checklist

Before releasing Gerbers:

- run ERC and DRC
- verify every WROOM pad against the Espressif footprint
- verify antenna keepout against current Espressif guidance
- verify USB-C footprint and CC orientation
- verify 3.3 V regulator layout against TI recommended placement
- verify 40-pin FFC pin 1 orientation against the Newhaven display
- verify board diameter and 60 mm PCD against printed fit gauge
- verify USB-C connector aligns with rear-cover slot
- verify no component collision with rear-cover standoffs, BMI088 cradle or display carrier
- inspect all strapping pins for unintended pull-ups/pull-downs
- inspect GPIO35–37 remain free from internal-memory conflicts by confirming the exact `N16R2` module

The first PCB should be treated as a bench prototype until electrical, thermal, vibration and failure-mode testing are complete.
