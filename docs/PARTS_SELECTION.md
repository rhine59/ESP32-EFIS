# Reference Parts Selection and Sourcing

Checked: 14 September 2026.

This document records the exact reference IMU and display chosen for the ESP32 artificial-horizon prototype. Availability and prices are time-sensitive and should be rechecked before ordering.

## 1. IMU — Bosch Sensortec SHUTTLE BOARD 3.0 BMI088

**Selected part:** Bosch Sensortec `SHUTTLE BOARD 3.0 BMI088`

Why this board:

- official Bosch evaluation hardware
- genuine BMI088 mounted and documented by the sensor manufacturer
- supports SPI, which is the interface selected for this project
- mechanical drawing is published
- compact 22 mm × 14 mm board envelope
- avoids uncertainty around regulator, pull-up, decoupling and axis marking on inexpensive third-party modules

Mechanical notes:

- approximate board outline: 22 mm × 14 mm
- board thickness: about 1.6 mm
- overall connector/component height shown by Bosch is about 6.7 mm
- connector pitch: 1.27 mm

The 1.27 mm pitch means this is not a normal 2.54 mm breadboard module. The prototype should use a suitable carrier/adapter or mating socket.

Current UK sourcing found during selection:

- DigiKey UK listed the Bosch Shuttle Board 3.0 BMI088 in stock at the time of selection.
- Manufacturer product page and shuttle-board flyer should be treated as the authoritative source for dimensions and pin behaviour.

Useful references:

- Bosch BMI088 product page: https://www.bosch-sensortec.com/en/products/motion-sensors/imus/bmi088/
- Bosch Shuttle Board 3.0 flyer: https://www.bosch-sensortec.com/media/boschsensortec/downloads/shuttle_board_flyer/application_board_3_1/bst-bmi088-sf000.pdf
- DigiKey UK part page: https://www.digikey.co.uk/en/products/detail/bosch-sensortec/SHUTTLE-BOARD-3-0-BMI088/14617528

### SPI implementation note

The BMI088 accelerometer and gyro are separate logical devices and require separate chip-select handling. The accelerometer powers up in I²C mode and must be explicitly transitioned into SPI mode using the sequence documented by Bosch. Firmware must implement this intentionally rather than assume both halves of the sensor behave identically.

## 2. Display — Newhaven Display NHD-2.1-480480AF-ASXP

**Selected part:** Newhaven Display `NHD-2.1-480480AF-ASXP`

Why this display:

- 2.1-inch round form factor fits the planned 3 1/8-inch instrument enclosure
- 480 × 480 resolution
- IPS full-view construction
- **1000 nit** documented luminance for bright-cockpit evaluation
- ST7701S controller/driver
- no touch layer
- anti-glare construction
- EMI-shielded FPC
- manufacturer provides a detailed mechanical drawing

Key dimensions and electrical details:

- active area: 53.28 × 53.28 mm
- outline: 58.18 × 60.71 × 2.26 mm
- interface: 18-bit parallel RGB or 1-lane MIPI DSI
- project interface: **18-bit parallel RGB**
- connection: 40-pin, 0.5 mm-pitch FFC
- TFT supply: approximately 3.0 V
- backlight: approximately 6.0 V / 100 mA
- operating temperature: -20 °C to +70 °C

Useful references:

- Newhaven product page: https://newhavendisplay.com/2-1-inch-tft-display-480x480-round-sunlight-readable-ips-rgb-mipi-dsi-interface/
- Newhaven specification PDF: https://newhavendisplay.com/content/specs/NHD-2.1-480480AF-ASXP.pdf

Newhaven lists distributors including DigiKey, Mouser and RS. Electromaker also surfaced this exact part during the September 2026 sourcing check. Recheck stock immediately before purchasing.

## 3. Consequence of using a 5 V USB-C input

The selected display is not a self-contained 5 V display module. The instrument's 5 V USB-C input therefore needs supporting circuitry for the bare panel:

1. LCD logic supply at the voltage required by the panel/carrier.
2. A 40-pin 0.5 mm FFC connector or carrier board.
3. A boost/constant-current LED driver for the approximately 6 V / 100 mA high-brightness backlight.
4. PWM or analogue dimming control from the ESP32-S3.

The backlight must not be connected directly to an ESP32 GPIO or the 3.3 V rail.

## 4. Remaining parts to select

Before finalising the wiring loom or CAD enclosure, freeze:

- exact ESP32-S3 N8R8 development board
- 40-pin FFC connector/carrier arrangement
- 5 V-input LED boost/current driver
- rotary encoder and shaft dimensions
- aircraft-panel cutout and mounting-hole pattern

Once those are frozen, the project can move to a complete GPIO assignment, first firmware build and parametric enclosure CAD.
