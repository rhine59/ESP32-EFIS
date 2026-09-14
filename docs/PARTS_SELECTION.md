# Reference Parts Selection and Sourcing

Checked: 14 September 2026.

This document records the reference hardware selected for the ESP32 artificial-horizon prototype. Availability and prices are time-sensitive and should be rechecked before ordering.

## Purchase links — UK

Use the **manufacturer part number** as the authoritative identifier before ordering; retailer descriptions and photographs can be ambiguous.

| Part | Preferred purchase link | Status when checked |
|---|---|---|
| Bosch BMI088 Shuttle Board 3.0 | [DigiKey UK — SHUTTLE BOARD 3.0 BMI088](https://www.digikey.co.uk/en/products/detail/bosch-sensortec/SHUTTLE-BOARD-3-0-BMI088/14617528) | In stock when checked |
| Newhaven NHD-2.1-480480AF-ASXP | [DigiKey UK — NHD-2.1-480480AF-ASXP](https://www.digikey.co.uk/en/products/detail/newhaven-display-intl/NHD-2-1-480480AF-ASXP/25724289) | Listed; stock should be rechecked before ordering |
| Newhaven NHD-FFC40 adapter | [RS UK — NHD-FFC40](https://uk.rs-online.com/web/p/display-interface-kits/0723891) | Listed; availability should be checked at order time |
| Adafruit TPS61169 PID 6354 | [Pimoroni UK — TPS61169 constant-current boost converter](https://shop.pimoroni.com/products/adafruit-tps61169-constant-current-boost-converter-for-leds) | UK product listing |
| Microchip MCP23008-E/P | [DigiKey UK — MCP23008-E/P](https://www.digikey.co.uk/en/products/detail/microchip-technology/MCP23008-E-P/735951) | In stock when checked |
| ESP32-S3-DevKitC-1-N8R2 | [DigiKey UK — ESP32-S3-DevKitC-1-N8R2](https://www.digikey.co.uk/en/products/detail/espressif-systems/ESP32-S3-DEVKITC-1-N8R2/15199627) | **Do not order blindly:** exact N8R2 DevKit is marked obsolete by major distributors |
| Optical front window | [Diamond Coatings — hard-coated AR polycarbonate](https://diamondcoatings.co.uk/product/hard-coated-polycarbonate-anti-reflective-coating-on-both-sides-and-afp-coating-one-side/) | Preferred final window source; custom sizes/CNC available by enquiry |
| Compact rotary encoder | [Bourns PEC09 family](https://www.bourns.com/products/encoders/product-detail/contacting-encoders/pec09) | Reference family selected; exact `PEC09-2320F-T0015` should be availability-checked before purchase |

## Optical window specification

The front protective window is specified as **2.0 mm optical clear polycarbonate with a scratch-resistant hard coat and anti-reflective coating on both sides**. An anti-fingerprint coating on the cockpit-facing surface is preferred if available.

The CAD now freezes the prototype disc at **62.0 mm diameter**. Preferred source is Diamond Coatings Ltd, with Itotek as a second source.

- Diamond Coatings hard-coated polycarbonate, AR both sides, AFP one side: https://diamondcoatings.co.uk/product/hard-coated-polycarbonate-anti-reflective-coating-on-both-sides-and-afp-coating-one-side/
- Sunlight-readable hard-coated/AR polycarbonate: https://diamondcoatings.co.uk/product/sunlight-readable-polycarbonate/
- Itotek AR-coated acrylic/polycarbonate display windows: https://www.itotek.co.uk/ar-coated-acrylic-polycarbonate-sheet

## Important ESP32 purchasing note

The electrical design currently targets `ESP32-S3-DevKitC-1-N8R2` because Quad PSRAM leaves GPIO35–37 available. However, the exact Espressif N8R2 DevKitC-1 is shown as obsolete by major distributors. Do **not** substitute an N8R8/OCTAL-PSRAM board without revisiting the GPIO map, because GPIO35–37 are used internally by Octal PSRAM variants.

Before buying the MCU board, confirm either genuine remaining stock of `ESP32-S3-DevKitC-1-N8R2`, or another ESP32-S3 development board/module using Quad PSRAM and exposing the required GPIOs.

The generic [Pi Hut ESP32-S3-DevKitC-1 listing](https://thepihut.com/collections/espressif/products/esp32-s3-devkitc-1-development-board) is useful for UK sourcing, but the exact fitted module/PSRAM variant must be confirmed before purchase.

## 1. MCU — Espressif ESP32-S3-DevKitC-1-N8R2

**Selected reference:** Espressif `ESP32-S3-DevKitC-1-N8R2`.

The current mechanical carrier is designed around the DevKitC-1 board envelope rather than relying on undocumented mounting holes. This keeps the carrier adaptable if the final Quad-PSRAM board changes.

Useful reference: [Espressif DevKitC-1 user guide](https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32s3/esp32-s3-devkitc-1/).

## 2. IMU — Bosch Sensortec SHUTTLE BOARD 3.0 BMI088

**Selected part:** Bosch Sensortec `SHUTTLE BOARD 3.0 BMI088`.

The rigid IMU cradle is based on the documented approximately 22 mm × 14 mm external PCB envelope and deliberately avoids assuming an unverified mounting-hole pattern.

References: [Bosch BMI088](https://www.bosch-sensortec.com/en/products/motion-sensors/imus/bmi088/) and [Bosch Shuttle Board flyer](https://www.bosch-sensortec.com/media/boschsensortec/downloads/shuttle_board_flyer/application_board_3_1/bst-bmi088-sf000.pdf).

## 3. Display — Newhaven NHD-2.1-480480AF-ASXP

**Selected part:** Newhaven Display `NHD-2.1-480480AF-ASXP`.

Key characteristics:

- 2.1-inch round IPS
- 480 × 480 pixels
- 1000 nit typical luminance
- ST7701S controller
- active area 53.28 × 53.28 mm
- outline 58.18 × 60.71 × 2.26 mm
- 40-pin 0.5 mm FFC
- VDD 2.5–3.3 V
- backlight approximately 6.0 V / 100 mA

The project uses **16-bit RGB565** and 9-bit SPI for controller initialization.

## 4. Display adapter

**Prototype adapter:** Newhaven `NHD-FFC40`.

For the final compact PCB, Newhaven's current datasheet names **Molex 54104-4031** as the example 40-pin 0.5 mm FFC connector.

## 5. Backlight driver — Adafruit TPS61169 breakout, PID 6354

Selected for the prototype because it accepts the 5 V instrument rail, regulates LED current and supports PWM dimming.

Adafruit specifies the board at approximately **25.2 × 19.0 × 10.1 mm**. The new electronics carrier provides a generic tie-slot mounting zone for this board rather than guessing its mounting-hole pattern.

## 6. GPIO expander — Microchip MCP23008-E/P

An 8-bit I²C GPIO expander is used for low-speed controls and LCD reset/chip-select handling. The electronics carrier includes a separate generic small-prototype-board zone so the MCP23008 can initially be assembled on a compact carrier/perfboard before a custom PCB is designed.

## 7. Rotary encoder — Bourns PEC09 reference

The front control has now been designed around the compact **Bourns PEC09** 9 mm incremental encoder family, with push switch.

Reference prototype part: **`PEC09-2320F-T0015`**.

Reasons for this family:

- compact 9 mm class body
- metal shaft
- mechanical detents
- quadrature A/B output
- integrated push switch
- M7 × 0.75 threaded bushing on the T-style hardware version
- Bourns drawing uses a nominal **7.2 mm panel hole**

The enclosure uses a small front-side control pod so the encoder body sits on the cockpit side of the aircraft panel. This avoids requiring a second cutout beside the standard 3 1/8-inch instrument hole.

Reference: [Bourns PEC09 datasheet](https://www.bourns.com/docs/Product-Datasheets/PEC09.pdf).

Before ordering, verify the exact suffix, shaft length, switch travel and current stock. If the exact part changes, update the parametric pod dimensions before printing.

## 8. Rear electronics carrier and USB-C strain relief

The rear-service assembly now provides:

- removable electronics carrier on four M2.5 standoffs
- ESP32 edge-location rails with the USB end kept open
- TPS61169 tie-slot mounting zone
- MCP23008/prototype-board tie-slot mounting zone
- four additional harness tie points
- right-angle USB-C service slot
- separate two-screw cable-jacket strain-relief clamp

The strain-relief clamp is intentionally sized parametrically; `usb_cable_d` must be adjusted to the actual cable jacket before the final print.

## 9. 5 V USB-C architecture

```text
5 V USB-C
   |
   +--> ESP32-S3-DevKitC-1 reference board
   |       +--> 3.3 V BMI088
   |       +--> 3.3 V LCD VDD
   |       +--> RGB565 + timing
   |       +--> shared SPI for LCD init + BMI088
   |       +--> I2C to MCP23008
   |
   +--> TPS61169
           +--> Newhaven backlight (~100 mA)
```

## 10. Remaining mechanical choices

- confirm the exact ESP32-S3 replacement/stocked board before freezing rail dimensions
- physically measure the chosen PEC09 encoder before final print
- select the exact right-angle USB-C cable and set the strain-relief groove diameter
- replace prototype MCP23008 wiring with a compact custom carrier PCB after bench proof-of-concept
- verify the actual aircraft panel spacing around the new front control pod
