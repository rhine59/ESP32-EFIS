# Display Design

## Selected reference panel

Reference display: **Newhaven Display NHD-2.1-480480AF-ASXP**.

Manufacturer characteristics:

- 2.1-inch round IPS TFT
- 480 × 480 pixels
- 1000 cd/m² luminance
- ST7701S controller/driver
- no touch layer
- 40-pin, 0.5 mm-pitch FFC
- active area: 53.28 × 53.28 mm
- outline: 58.18 × 60.71 × 2.26 mm
- TFT supply: 2.5–3.3 V, project uses 3.3 V
- backlight: approximately 6.0 V / 100 mA
- operating temperature: -20 °C to +70 °C
- EMI-shielded FPC
- anti-glare construction

The panel is marketed as an 18-bit parallel RGB / 1-lane MIPI DSI display. The ST7701S itself supports 16-bit RGB input mode, which this project uses to reduce ESP32-S3 GPIO demand.

## Project interface

The project uses:

- **16-bit RGB565** pixel bus
- DE-mode parallel RGB
- PCLK + HSYNC + VSYNC + DE
- 3-wire / 9-bit serial control for ST7701S startup
- physical mode straps IM0=0, IM1=1, IM2=0

The RGB565 mapping is:

- ESP D0..D4 -> panel B1..B5
- ESP D5..D10 -> panel G0..G5
- ESP D11..D15 -> panel R1..R5
- panel B0 -> GND
- panel R0 -> GND

The ST7701S `COLMOD` RGB pixel-format field is set to `VIPF=101` for 16-bit/pixel mode.

## Current RGB timing baseline

The current Newhaven datasheet gives these recommended **RGB** values:

- pixel clock: **30 MHz**
- HFP: **50** clocks
- HBP: **50** clocks
- HS pulse width: **4** clocks
- VFP: **50** lines
- VBP: **50** lines
- VS pulse width: **2** lines

An earlier project note used 18 MHz with 40/60/20 and 10/10/6 porches/sync widths. Those values belong to Newhaven's **MIPI timing table**, not the RGB table, and are no longer the firmware baseline.

## ESP-IDF integration

The firmware uses Espressif's native RGB LCD driver:

- `esp_lcd_new_rgb_panel()`
- `data_width = 16`
- two full framebuffers
- framebuffers allocated in PSRAM

Two 480×480 RGB565 framebuffers consume 921,600 bytes, which fits comfortably in the N16R2 module's 2 MB Quad PSRAM.

## ST7701S startup

The firmware retains Newhaven's published panel-specific power/gamma initialization sequence and changes the example's RGB pixel-format setting from 18-bit to the ST7701S-defined 16-bit RGB value.

This is a bench-validation item. The first hardware test must verify:

- colour order
- line/column alignment
- no horizontal or vertical tearing
- stable 30 MHz pixel clock operation
- correct HSYNC/VSYNC/DE polarity
- correct RGB565 mapping

If any of those fail, the display electrical configuration must be corrected before AHRS rendering is introduced.

## Backlight

The 5 V instrument rail feeds the dedicated TPS61169 constant-current boost driver. The ESP32-S3 controls brightness through the driver control/PWM input.

The proof-of-life firmware keeps the backlight off throughout panel initialization and framebuffer preparation, then enables it only after a complete static horizon image exists.

## Graphics concept

The artificial horizon will use:

- blue sky
- brown ground
- white horizon line
- bank-angle scale
- pitch ladder
- fixed aircraft reference symbol
- prominent invalid-attitude overlay

The current firmware contains a static version of this scene purely for display bring-up.

## Failure display

A failed or stale attitude solution must never leave a believable frozen horizon. The eventual live renderer must replace or obscure the attitude image with:

```text
ATTITUDE
 INVALID
```

This requirement applies regardless of whether the fault originates in the BMI088, SPI link, AHRS timing or validity logic.
