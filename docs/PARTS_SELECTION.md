# Reference Parts Selection and Sourcing

Checked: 14 September 2026.

This document records the exact reference hardware selected for the ESP32 artificial-horizon prototype. Availability and prices are time-sensitive and should be rechecked before ordering.

## Purchase links — UK

Use the **manufacturer part number** as the authoritative identifier before ordering; retailer descriptions and photographs can be ambiguous.

| Part | Preferred purchase link | Status when checked |
|---|---|---|
| Bosch BMI088 Shuttle Board 3.0 | [DigiKey UK — SHUTTLE BOARD 3.0 BMI088](https://www.digikey.co.uk/en/products/detail/bosch-sensortec/SHUTTLE-BOARD-3-0-BMI088/14617528) | In stock when checked |
| Newhaven NHD-2.1-480480AF-ASXP | [DigiKey UK — NHD-2.1-480480AF-ASXP](https://www.digikey.co.uk/en/products/detail/newhaven-display-intl/NHD-2-1-480480AF-ASXP/25724289) | Listed, but no immediate stock when checked; use stock notification/back-order |
| Newhaven NHD-FFC40 adapter | [RS UK — NHD-FFC40](https://uk.rs-online.com/web/p/display-interface-kits/0723891) | Listed; availability should be checked at order time |
| Adafruit TPS61169 PID 6354 | [Pimoroni UK — TPS61169 constant-current boost converter](https://shop.pimoroni.com/products/adafruit-tps61169-constant-current-boost-converter-for-leds) | UK product listing |
| Microchip MCP23008-E/P | [DigiKey UK — MCP23008-E/P](https://www.digikey.co.uk/en/products/detail/microchip-technology/MCP23008-E-P/735951) | In stock when checked |
| ESP32-S3-DevKitC-1-N8R2 | [DigiKey UK — ESP32-S3-DevKitC-1-N8R2](https://www.digikey.co.uk/en/products/detail/espressif-systems/ESP32-S3-DEVKITC-1-N8R2/15199627) | **Do not order blindly:** DigiKey currently marks this exact N8R2 DevKit as obsolete. See note below. |

### Important ESP32 purchasing note

The electrical design currently targets `ESP32-S3-DevKitC-1-N8R2` because Quad PSRAM leaves GPIO35–37 available. However, the exact Espressif N8R2 DevKitC-1 is now shown as obsolete by major distributors. Do **not** substitute an N8R8/OCTAL-PSRAM board without revisiting the GPIO map, because GPIO35–37 are used internally by Octal PSRAM variants.

Before buying the MCU board, confirm either:

1. genuine remaining stock of `ESP32-S3-DevKitC-1-N8R2`, or
2. another ESP32-S3 development board/module using Quad PSRAM and exposing the required GPIOs.

The generic [Pi Hut ESP32-S3-DevKitC-1 listing](https://thepihut.com/collections/espressif/products/esp32-s3-devkitc-1-development-board) is useful for UK sourcing, but the exact fitted module/PSRAM variant must be confirmed before purchase.

## Selected-parts gallery

The photographs below are manufacturer/distributor-hosted reference images. They are included here so the exact physical parts can be recognised during purchasing and assembly. Product specifications and part numbers, rather than appearance alone, remain authoritative.

### ESP32-S3-DevKitC-1-N8R2

<img src="https://cdn-shop.adafruit.com/970x728/5310-04.jpg" alt="Espressif ESP32-S3-DevKitC-1-N8R2" width="420">

### Bosch BMI088 Shuttle Board 3.0

<img src="https://www.bosch-sensortec.com/media/boschsensortec/downloads/shuttle_board_flyer/application_board_3_1/bst-bmi088-sf000.pdf" alt="Bosch BMI088 Shuttle Board 3.0 — see Bosch product flyer" width="420">

> GitHub cannot render the Bosch PDF itself as an inline photograph in all clients. The Bosch flyer linked above contains the official product photograph and mechanical drawing.

### Newhaven NHD-2.1-480480AF-ASXP 2.1-inch round display

<img src="https://cdn11.bigcommerce.com/s-ybeckn7x79/images/stencil/1280x1280/products/690/3468/LCD-TFT-21-Round-IPS-display-BACK__18610.1725658911.jpg?c=1" alt="Newhaven NHD-2.1-480480AF-ASXP round LCD" width="420">

### Newhaven NHD-FFC40 prototype FFC adapter

<img src="https://mm.digikey.com/Volume0/opasdata/d220001/medias/images/1821/NHD-FFC40.jpg" alt="Newhaven NHD-FFC40 FFC adapter" width="420">

### Adafruit TPS61169 constant-current backlight driver — PID 6354

<img src="https://cdn-shop.adafruit.com/970x728/6354-00.jpg" alt="Adafruit TPS61169 constant-current boost converter PID 6354" width="420">

### Microchip MCP23008 GPIO expander — prototype DIP package

<img src="https://cdn-shop.adafruit.com/970x728/593-01.jpg" alt="Microchip MCP23008 I2C GPIO expander" width="420">

---

## 1. MCU — Espressif ESP32-S3-DevKitC-1-N8R2

**Selected part:** Espressif `ESP32-S3-DevKitC-1-N8R2`

Why this board:

- official Espressif development board
- ESP32-S3-WROOM-1-N8R2 module
- 8 MB Quad flash
- 2 MB Quad PSRAM
- 3.3 V logic
- GPIO35, GPIO36 and GPIO37 remain available externally
- published schematic, pinout and mechanical documentation

This replaces the earlier N8R8 choice. Octal PSRAM variants use GPIO35–37 internally, making those pins unavailable. The N8R2 avoids that restriction and still has enough PSRAM for two full 480×480 RGB565 frame buffers (~922 kB total).

Useful reference: [Espressif DevKitC-1 user guide](https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32s3/esp32-s3-devkitc-1/).

## 2. IMU — Bosch Sensortec SHUTTLE BOARD 3.0 BMI088

**Selected part:** Bosch Sensortec `SHUTTLE BOARD 3.0 BMI088`

Why this board:

- official Bosch evaluation hardware
- genuine BMI088 mounted and documented by the sensor manufacturer
- supports SPI
- compact 22 mm × 14 mm board envelope
- avoids uncertainty around regulator, decoupling and axis marking on third-party modules

References: [Bosch BMI088](https://www.bosch-sensortec.com/en/products/motion-sensors/imus/bmi088/) and [Bosch Shuttle Board flyer](https://www.bosch-sensortec.com/media/boschsensortec/downloads/shuttle_board_flyer/application_board_3_1/bst-bmi088-sf000.pdf).

The BMI088 accelerometer and gyro are separate logical devices and require separate chip-select handling. Firmware must explicitly switch the accelerometer into SPI mode after reset.

## 3. Display — Newhaven NHD-2.1-480480AF-ASXP

**Selected part:** Newhaven Display `NHD-2.1-480480AF-ASXP`

Key characteristics:

- 2.1-inch round IPS
- 480 × 480 pixels
- 1000 nit typical luminance
- ST7701S controller
- no touch layer
- active area: 53.28 × 53.28 mm
- outline: 58.18 × 60.71 × 2.26 mm
- 40-pin 0.5 mm FFC
- VDD range 2.5–3.3 V
- backlight approximately 6.0 V / 100 mA

### Project interface choice: RGB565

The panel supports 16-bit/pixel mode as well as 18-bit. The project will use **16-bit RGB565** to reduce ESP32 GPIO consumption:

- B1–B5 used; B0 tied low
- G0–G5 used
- R1–R5 used; R0 tied low

The display remains 480×480; only colour depth is reduced to 65,536 colours, which is more than adequate for sky/ground shading, pitch ladders, symbols and warnings.

The panel requires PCLK, HS, VS and DE in DE mode, so those four timing signals remain connected.

### ST7701S configuration mode

The panel will use **RGB + 9-bit SPI** for controller initialization. Hardware strap levels:

- IM0 = 0
- IM1 = 1
- IM2 = 0

The 9th SPI bit carries command/data state, eliminating a dedicated DC GPIO. SPI is used only to initialize/configure the ST7701S; pixel data then travels over the RGB bus.

References: [Newhaven product page](https://newhavendisplay.com/2-1-inch-tft-display-480x480-round-sunlight-readable-ips-rgb-mipi-dsi-interface/) and [datasheet](https://newhavendisplay.com/content/specs/NHD-2.1-480480AF-ASXP.pdf).

## 4. Display adapter

**Prototype adapter:** Newhaven `NHD-FFC40`.

For the final compact PCB, Newhaven's current datasheet names **Molex 54104-4031** as the example 40-pin 0.5 mm FFC connector. Verify stock and mechanical compatibility again before PCB manufacture.

## 5. Backlight driver — Adafruit TPS61169 breakout, PID 6354

Selected for the prototype because it accepts the 5 V instrument rail, regulates LED current and supports PWM dimming.

Prototype setup:

- input: 5 V
- LED current: 100 mA setting
- output: LED_A / LED_K
- PWM: direct ESP32 GPIO

## 6. GPIO expander — Microchip MCP23008-E/P

An 8-bit I²C GPIO expander is added to avoid using ESP32 strapping pins for low-speed controls.

Prototype allocation:

- GP0 — LCD CSX
- GP1 — LCD RESETX
- GP2 — rotary encoder A
- GP3 — rotary encoder B
- GP4 — rotary encoder push
- GP5–GP7 — spare

The MCP23008 interrupt output connects to a direct ESP32 GPIO so encoder changes can be serviced promptly.

Reference: [Microchip MCP23008](https://www.microchip.com/en-us/product/MCP23008).

## 7. 5 V USB-C architecture

```text
5 V USB-C
   |
   +--> ESP32-S3-DevKitC-1-N8R2
   |       +--> 3.3 V BMI088
   |       +--> 3.3 V LCD VDD
   |       +--> RGB565 + timing
   |       +--> shared SPI for LCD init + BMI088
   |       +--> I2C to MCP23008
   |
   +--> TPS61169
           +--> Newhaven backlight (~100 mA)
```

The display may be powered at **3.3 V**, which is within its specified 2.5–3.3 V VDD range and avoids a logic-level mismatch with the ESP32's 3.3 V outputs.

## 8. Remaining mechanical choices

- exact rotary encoder model and shaft dimensions
- USB-C cable/strain relief
- actual aircraft panel cutout and mounting-hole pattern
- final compact carrier PCB arrangement
