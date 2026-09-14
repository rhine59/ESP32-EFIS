# Reference Parts Selection and Sourcing

Checked: 14 September 2026.

This document records the exact reference hardware selected for the ESP32 artificial-horizon prototype. Availability and prices are time-sensitive and should be rechecked before ordering.

## 1. MCU — Espressif ESP32-S3-DevKitC-1-N8R8

**Selected part:** Espressif `ESP32-S3-DevKitC-1-N8R8`

Why this board:

- official Espressif development board
- ESP32-S3-WROOM-1-N8R8 module
- 8 MB flash
- 8 MB Octal PSRAM, useful for 480×480 frame buffers and graphics work
- 3.3 V logic
- most GPIOs broken out to headers
- reproducible schematic, dimensions and pinout from the MCU manufacturer
- avoids clone-board ambiguity during GPIO and enclosure design

Useful references:

- Espressif DevKit overview: https://www.espressif.com/en/products/devkits
- DevKitC-1 user guide: https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32s3/esp32-s3-devkitc-1/user_guide_v1.1.html

Revision note: Espressif states that initial and v1.1 boards differ mainly in the onboard RGB LED GPIO assignment. Firmware should therefore avoid depending on the onboard RGB LED for any critical function.

## 2. IMU — Bosch Sensortec SHUTTLE BOARD 3.0 BMI088

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

Useful references:

- Bosch BMI088 product page: https://www.bosch-sensortec.com/en/products/motion-sensors/imus/bmi088/
- Bosch Shuttle Board 3.0 flyer: https://www.bosch-sensortec.com/media/boschsensortec/downloads/shuttle_board_flyer/application_board_3_1/bst-bmi088-sf000.pdf
- DigiKey UK part page: https://www.digikey.co.uk/en/products/detail/bosch-sensortec/SHUTTLE-BOARD-3-0-BMI088/14617528

### SPI implementation note

The BMI088 accelerometer and gyro are separate logical devices and require separate chip-select handling. The accelerometer powers up in I²C mode and must be explicitly transitioned into SPI mode using the sequence documented by Bosch. Firmware must implement this intentionally rather than assume both halves of the sensor behave identically.

## 3. Display — Newhaven Display NHD-2.1-480480AF-ASXP

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

## 4. Backlight driver — Adafruit TPS61169 breakout, PID 6354

**Selected prototype part:** Adafruit `TPS61169 Constant Current Boost Converter for LEDs`, Product ID `6354`.

Why this board:

- based on the Texas Instruments TPS61169 boost WLED driver
- accepts 3–5 V input, therefore works from the instrument's 5 V USB-C rail
- constant-current operation suits an LCD LED backlight better than a simple fixed-voltage boost module
- PWM input allows software brightness control
- onboard DIP switches allow current selection
- assembled breakout avoids designing a tiny SC70 boost converter circuit before the first display tests

Prototype configuration:

- input: 5 V rail
- maximum selected LED current: **100 mA**
- output: display backlight anode/cathode as required by the Newhaven pinout
- PWM/CTRL: driven from a non-critical ESP32 GPIO

Adafruit states that the breakout can source up to 400 mA depending on voltage/power limits and that the selectable current increments allow a 100 mA setting. Board dimensions are approximately 25.2 × 19.0 × 10.1 mm.

Useful references:

- Adafruit breakout: https://www.adafruit.com/product/6354
- TI TPS61169: https://www.ti.com/product/TPS61169

For a later custom PCB, the same TPS61169 IC or an equivalent automotive/industrial-grade LED driver may replace the breakout.

## 5. 5 V USB-C power architecture

The first prototype remains a **regulated 5 V USB-C instrument**.

```text
5 V USB-C
   |
   +--> ESP32-S3-DevKitC-1-N8R8
   |       +--> 3.3 V logic / BMI088 as appropriate
   |       +--> RGB + control signals to display carrier
   |       +--> PWM brightness control
   |
   +--> TPS61169 breakout
           +--> constant-current boosted output
                   +--> Newhaven 1000-nit backlight (~6 V / 100 mA)
```

The display backlight is not powered through an ESP32 GPIO or the ESP32's 3.3 V regulator.

The final 5 V source must have adequate current margin for the MCU, display logic and backlight. Bench testing should measure worst-case current with Wi-Fi/Bluetooth disabled and enabled, maximum backlight brightness, and high graphics load before specifying the aircraft-side 5 V USB supply.

## 6. Remaining parts to select

Before the complete GPIO map and enclosure CAD are frozen, select:

- exact 40-pin FFC connector/carrier arrangement
- rotary encoder and shaft dimensions
- rear USB-C cable/connector and strain-relief geometry
- actual aircraft-panel cutout and mounting-hole pattern

Once the FFC carrier is defined, the 18-bit RGB bus can be mapped to ESP32 GPIOs without guesswork and the first firmware build can begin.
