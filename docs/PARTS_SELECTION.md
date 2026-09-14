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
| ESP32-S3-DevKitC-1-N8R2 | [DigiKey UK — ESP32-S3-DevKitC-1-N8R2](https://www.digikey.co.uk/en/products/detail/espressif-systems/ESP32-S3-DEVKITC-1-N8R2/15199627) | **Do not order blindly:** exact N8R2 DevKit is marked obsolete by major distributors. |
| Optical front window | [Diamond Coatings — hard-coated AR polycarbonate](https://diamondcoatings.co.uk/product/hard-coated-polycarbonate-anti-reflective-coating-on-both-sides-and-afp-coating-one-side/) | Preferred final window source; custom sizes/CNC available by enquiry |

### Optical window specification

The front protective window should be **2.0 mm optical clear polycarbonate with a scratch-resistant hard coat and anti-reflective coating on both sides**. An anti-fingerprint coating on the cockpit-facing surface is preferred if available.

Diamond Coatings states that its DIAMOX AR coating on hard-coated polycarbonate can provide around **98% transmission and less than 0.5% reflection from 500–600 nm**. Specific sizes and CNC profiles are available by request.

Preferred source:

- Diamond Coatings hard-coated polycarbonate, AR both sides, AFP one side: https://diamondcoatings.co.uk/product/hard-coated-polycarbonate-anti-reflective-coating-on-both-sides-and-afp-coating-one-side/
- Sunlight-readable hard-coated/AR polycarbonate: https://diamondcoatings.co.uk/product/sunlight-readable-polycarbonate/

Alternative UK source:

- Itotek AR-coated acrylic/polycarbonate display windows: https://www.itotek.co.uk/ar-coated-acrylic-polycarbonate-sheet

The final circular diameter is currently expected to be approximately **60–64 mm** and will be frozen when the removable bezel/window seat is added to the enclosure CAD.

### Important ESP32 purchasing note

The electrical design currently targets `ESP32-S3-DevKitC-1-N8R2` because Quad PSRAM leaves GPIO35–37 available. However, the exact Espressif N8R2 DevKitC-1 is now shown as obsolete by major distributors. Do **not** substitute an N8R8/OCTAL-PSRAM board without revisiting the GPIO map, because GPIO35–37 are used internally by Octal PSRAM variants.

Before buying the MCU board, confirm either:

1. genuine remaining stock of `ESP32-S3-DevKitC-1-N8R2`, or
2. another ESP32-S3 development board/module using Quad PSRAM and exposing the required GPIOs.

The generic [Pi Hut ESP32-S3-DevKitC-1 listing](https://thepihut.com/collections/espressif/products/esp32-s3-devkitc-1-development-board) is useful for UK sourcing, but the exact fitted module/PSRAM variant must be confirmed before purchase.

## Selected-parts gallery

The photographs below are manufacturer/distributor-hosted reference images. Product specifications and part numbers, rather than appearance alone, remain authoritative.

### ESP32-S3-DevKitC-1-N8R2

<img src="https://cdn-shop.adafruit.com/970x728/5310-04.jpg" alt="Espressif ESP32-S3-DevKitC-1-N8R2" width="420">

### Bosch BMI088 Shuttle Board 3.0

<img src="https://www.bosch-sensortec.com/media/boschsensortec/downloads/shuttle_board_flyer/application_board_3_1/bst-bmi088-sf000.pdf" alt="Bosch BMI088 Shuttle Board 3.0 — see Bosch product flyer" width="420">

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

The project uses **16-bit RGB565** to reduce ESP32 GPIO consumption. The panel uses RGB plus 9-bit SPI for controller initialization.

References: [Newhaven product page](https://newhavendisplay.com/2-1-inch-tft-display-480x480-round-sunlight-readable-ips-rgb-mipi-dsi-interface/) and [datasheet](https://newhavendisplay.com/content/specs/NHD-2.1-480480AF-ASXP.pdf).

## 4. Display adapter

**Prototype adapter:** Newhaven `NHD-FFC40`.

For the final compact PCB, Newhaven's current datasheet names **Molex 54104-4031** as the example 40-pin 0.5 mm FFC connector.

## 5. Backlight driver — Adafruit TPS61169 breakout, PID 6354

Selected for the prototype because it accepts the 5 V instrument rail, regulates LED current and supports PWM dimming.

## 6. GPIO expander — Microchip MCP23008-E/P

An 8-bit I²C GPIO expander is used for low-speed controls and LCD reset/chip-select handling.

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

## 8. Remaining mechanical choices

- exact rotary encoder model and shaft dimensions
- USB-C cable/strain relief
- actual aircraft panel cutout and mounting-hole pattern
- final compact carrier PCB arrangement
- final optical-window diameter and bezel retention geometry
