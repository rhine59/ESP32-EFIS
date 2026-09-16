# Reference Parts Selection and Sourcing

Checked: 16 September 2026.

This document records the reference hardware selected for the ESP32 artificial-horizon prototype. Availability and prices are time-sensitive and should be rechecked before ordering.

## Purchase links — UK

Use the **manufacturer part number** as the authoritative identifier before ordering.

| Part | Preferred purchase link | Procurement status |
|---|---|---|
| ESP32 module | DigiKey UK — ESP32-S3-WROOM-1-N16R2 | **Ordered — 2 units, 14 Sep 2026** |
| Bosch BMI088 Shuttle Board 3.0 | DigiKey UK — SHUTTLE BOARD 3.0 BMI088 | **Ordered — 14 Sep 2026** |
| Newhaven NHD-2.1-480480AF-ASXP | Mouser — MFG P/N NHD-2.1-480480AF-ASXP | **Ordered and shipped — 1 unit; ordered 14 Sep, shipped 15 Sep 2026** |
| Newhaven NHD-FFC40 adapter | RS UK — NHD-FFC40 | **Ordered** |
| Adafruit TPS61169 PID 6354 | DigiKey order | **Ordered — 14 Sep 2026** |
| Microchip MCP23008-E/P | DigiKey order | **Ordered — 14 Sep 2026** |
| Optical front window | Diamond Coatings — hard-coated AR polycarbonate | Preferred final window source; not recorded as ordered |
| Compact rotary encoder | Bourns PEC09-2320F-T0015 | **Ordered — 14 Sep 2026** |

## Procurement evidence — display

Mouser invoice 92509947 records one `NHD-2.1-480480AF-ASXP`, quantity ordered 1, shipped 1, pending 0. Order date was 14 September 2026 and ship date 15 September 2026. The merchandise price was £18.37 before freight/VAT. This confirms the selected display is already in transit and must not be treated as an outstanding purchase.

## MCU — Espressif ESP32-S3-WROOM-1-N16R2

**Frozen reference choice:** `ESP32-S3-WROOM-1-N16R2`.

Why this is preferred over the earlier DevKitC approach:

- **16 MB Quad flash** gives generous firmware and graphics headroom;
- **2 MB Quad PSRAM** is enough for two complete 480×480 RGB565 frame buffers;
- Quad PSRAM preserves GPIO35–37, unlike Octal-PSRAM configurations that consume those signals;
- the bare module is active and widely stocked;
- the final instrument can use a compact project-specific carrier PCB rather than carrying unused development-board hardware;
- native ESP32-S3 USB can be routed directly to the rear USB-C connector.

Two 480×480 RGB565 frame buffers consume approximately **921,600 bytes**, leaving useful PSRAM headroom.

### Why not N8R8 / Octal PSRAM

The extra PSRAM would be attractive in isolation, but the current instrument is **GPIO-constrained rather than memory-constrained**. The 16-bit RGB display, timing signals, BMI088 SPI, PWM and control functions make GPIO availability more valuable than an additional 6 MB of PSRAM.

Espressif documents GPIO35, GPIO36 and GPIO37 as part of the Octal memory interface. The current project uses those GPIOs for the shared LCD-configuration/BMI088 SPI path, so Octal-PSRAM variants are a poor fit without a wider GPIO redesign.

### Bench-development option

If an `ESP32-S3-DevKitC-1-N8R2` is already on hand, it remains a useful **bench-only development board** because it has the same ESP32-S3 core and 2 MB Quad PSRAM. It is no longer the preferred final hardware because the exact DevKit variant is obsolete at major distributors.

## Custom processor carrier PCB

The final PCB should mount the N16R2 module directly and provide:

- 5 V USB-C input
- low-noise 3.3 V regulation
- bulk and local decoupling
- native USB D-/D+ on GPIO19/GPIO20
- EN/reset circuit
- BOOT access on GPIO0
- test/programming pads
- display RGB/timing connector
- shared LCD-init/BMI088 SPI connector
- I²C connector for MCP23008
- TPS61169 PWM connection
- short high-speed traces and continuous ground reference

The current 3D-printed electronics carrier should therefore be treated as a development holder. Its edge rails will be revised around the final custom PCB dimensions once the PCB outline is frozen.

## Optical window specification

The front protective window is specified as **2.0 mm optical clear polycarbonate with a scratch-resistant hard coat and anti-reflective coating on both sides**. The CAD freezes the prototype disc at **62.0 mm diameter**.

Preferred sources:

- Diamond Coatings hard-coated polycarbonate, AR both sides, AFP one side
- Itotek AR-coated acrylic/polycarbonate display windows

## IMU — Bosch Sensortec SHUTTLE BOARD 3.0 BMI088

**Selected part:** Bosch Sensortec `SHUTTLE BOARD 3.0 BMI088`.

The rigid IMU cradle is based on the approximately 22 × 14 mm external PCB envelope and avoids assuming an unverified mounting-hole pattern.

## Display — Newhaven NHD-2.1-480480AF-ASXP

**Procurement:** one display is ordered and shipped from Mouser.

Key characteristics:

- 2.1-inch round IPS
- 480 × 480
- 1000 nit typical luminance
- ST7701S
- active area 53.28 × 53.28 mm
- outline 58.18 × 60.71 × 2.26 mm
- 40-pin 0.5 mm FFC
- VDD 2.5–3.3 V
- backlight approximately 6.0 V / 100 mA

The project uses **16-bit RGB565** for pixels and 9-bit serial initialization for the ST7701S.

## Display adapter

**Prototype adapter:** Newhaven `NHD-FFC40` — ordered.

For the final compact PCB, Newhaven's datasheet names **Molex 54104-4031** as the example 40-pin 0.5 mm FFC connector.

## Backlight driver — Adafruit TPS61169 PID 6354

Selected for the prototype because it accepts the 5 V rail, regulates LED current and supports PWM dimming. **Ordered 14 September 2026.**

## GPIO expander — Microchip MCP23008-E/P

An 8-bit I²C GPIO expander is used for low-speed controls and LCD reset/chip-select handling. **Ordered 14 September 2026.**

## Rotary encoder — Bourns PEC09 reference

Reference family: **Bourns PEC09**, incremental encoder with push switch.

Reference prototype part: `PEC09-2320F-T0015` — **ordered 14 September 2026.**

The front control pod is sized around the compact 9 mm class body and 7.2 mm mounting-hole requirement. Exact physical dimensions should be confirmed when the ordered part arrives before final printing.

## Rear electronics carrier and USB-C strain relief

The rear-service assembly provides a removable electronics carrier, generic support zones, harness tie points, rear USB-C service slot and cable-jacket strain-relief clamp.

The processor carrier geometry will be revised around the final **custom N16R2 PCB**, not around a DevKit board.

## 5 V USB-C architecture

```text
5 V USB-C
   |
   +--> custom processor carrier
   |       +--> ESP32-S3-WROOM-1-N16R2
   |       +--> 3.3 V BMI088
   |       +--> 3.3 V LCD logic
   |       +--> RGB565 + timing
   |       +--> shared SPI for LCD init + BMI088
   |       +--> I2C to MCP23008
   |
   +--> TPS61169
           +--> Newhaven backlight (~100 mA)
```

## Still required / not recorded as ordered

- Adafruit BMP585 Ported breakout, PID 6413, for the first static-pressure prototype
- PNI RM3100-CB P/N 14754 remote magnetometer (can follow the initial display/attitude/altitude bench bring-up)
- a practical temporary carrier/breakout for the bare ESP32-S3-WROOM-1-N16R2, unless a suitable board is already available
- prototype interconnect materials as required: headers/sockets, short harness leads/perfboard and suitable connectors
- 5 V USB-C bench supply/cable if not already available
- optical front window can wait for enclosure/optical evaluation

## Remaining hardware choices

- freeze the custom MCU carrier PCB outline and connector placement
- physically measure the chosen PEC09 encoder when received before final print
- select the exact USB-C cable and set the strain-relief groove diameter
- replace prototype MCP23008 wiring with the compact project carrier PCB
- verify actual aircraft-panel spacing around the front control pod
