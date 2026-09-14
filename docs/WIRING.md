# Wiring Plan

This document records the prototype electrical architecture and the first frozen GPIO allocation.

## Power

```text
regulated 5 V source
      |
      +-- USB-C --> ESP32-S3-DevKitC-1-N8R2
      |                |
      |                +-- 3.3 V --> BMI088
      |                +-- 3.3 V --> LCD VDD
      |                +-- 3.3 V --> MCP23008
      |
      +-- TPS61169 constant-current boost driver
                         |
                         +-- LED_A / LED_K --> LCD backlight (~6 V / 100 mA)
```

Raw aircraft 12 V is deliberately kept outside the prototype instrument.

## Why N8R2 instead of N8R8

The N8R8 DevKitC-1 uses GPIO35–37 internally for Octal PSRAM. The N8R2 uses Quad PSRAM and leaves GPIO35–37 available externally, which is essential for this pin-heavy design.

## Display electrical mode

Selected panel: **Newhaven NHD-2.1-480480AF-ASXP**.

Prototype adapter: **Newhaven NHD-FFC40**.

The panel is operated as:

- 480 × 480
- 16-bit RGB565 pixel bus
- DE mode
- 18 MHz starting pixel clock target from the Newhaven recommended timing table
- 9-bit SPI only for ST7701S initialization

### FFC corrections and mode straps

Current Newhaven pinout:

- pin 5 = DN0 (MIPI data negative), unused in RGB mode
- pin 6 = DP0, unused in RGB mode
- pins 11/12/13/14 = VS/HS/PCLK/DE
- pins 15–20 = B0–B5
- pins 21–26 = G0–G5
- pins 27–32 = R0–R5
- pin 33 = RESETX
- pin 34 = CSX
- pin 35 = SCL
- pin 36 = DCX
- pin 37 = SDA
- pins 38/39/40 = IM0/IM1/IM2

For **RGB + 9-bit SPI**:

- IM0 = 0
- IM1 = 1
- IM2 = 0

DCX is not needed by the 3-wire/9-bit SPI protocol because the command/data state is carried in the ninth serial bit.

### RGB565 connection

The panel supports 16-bit/pixel mode. Connect:

- ESP D0..D4 -> panel B1..B5
- ESP D5..D10 -> panel G0..G5
- ESP D11..D15 -> panel R1..R5
- panel B0 -> GND
- panel R0 -> GND

The ST7701S initialization must set the interface pixel format to 16-bit.

## Frozen direct ESP32 GPIO map

| Function | GPIO | Notes |
|---|---:|---|
| RGB D0 / B1 | 4 | RGB565 bit 0 |
| RGB D1 / B2 | 5 | |
| RGB D2 / B3 | 6 | |
| RGB D3 / B4 | 7 | |
| RGB D4 / B5 | 8 | |
| RGB D5 / G0 | 9 | |
| RGB D6 / G1 | 10 | |
| RGB D7 / G2 | 11 | |
| RGB D8 / G3 | 12 | |
| RGB D9 / G4 | 13 | |
| RGB D10 / G5 | 14 | |
| RGB D11 / R1 | 15 | |
| RGB D12 / R2 | 16 | |
| RGB D13 / R3 | 17 | |
| RGB D14 / R4 | 18 | |
| RGB D15 / R5 | 21 | |
| LCD PCLK | 1 | RGB pixel clock |
| LCD DE | 2 | Data enable |
| LCD HSYNC | 38 | Horizontal sync |
| LCD VSYNC | 39 | Vertical sync |
| Shared SPI MOSI | 35 | LCD SDA during init; BMI088 MOSI afterwards |
| Shared SPI SCLK | 36 | LCD SCL during init; BMI088 SCLK afterwards |
| BMI088 MISO | 37 | LCD does not require MISO |
| BMI088 ACC CS | 40 | Accelerometer chip select |
| BMI088 GYRO CS | 41 | Gyro chip select |
| Backlight PWM | 42 | TPS61169 PWM/control |
| MCP23008 SDA | 47 | I²C |
| MCP23008 SCL | 48 | I²C; onboard RGB LED input is a benign extra load on relevant board revisions |
| MCP23008 INT | 43 | Interrupt-on-change for encoder |
| Spare / debug | 44 | Keep free initially |

## Reserved ESP32 pins

| GPIO | Reason |
|---:|---|
| 19 | Native USB D- |
| 20 | Native USB D+ |
| 0 | Boot strapping / BOOT button |
| 3 | Strapping pin |
| 45 | Strapping pin |
| 46 | Strapping pin |

This keeps the USB interface usable and avoids relying on external loads attached to boot-strapping pins.

## MCP23008 allocation

Prototype I²C address: default `0x20` with A0/A1/A2 tied low.

| MCP23008 pin | Function |
|---|---|
| GP0 | LCD CSX |
| GP1 | LCD RESETX |
| GP2 | Encoder A |
| GP3 | Encoder B |
| GP4 | Encoder push |
| GP5 | Spare |
| GP6 | Spare |
| GP7 | Spare |

Use MCP23008 interrupt-on-change for GP2–GP4 so encoder movement does not depend on slow polling.

## Shared SPI behaviour

The LCD configuration interface and BMI088 share SCLK/MOSI. They are not active simultaneously:

1. Hold BMI088 ACC CS and GYRO CS high.
2. Drive LCD CSX low through MCP23008.
3. Perform ST7701S 9-bit initialization.
4. Drive LCD CSX high.
5. Thereafter use the SPI bus for BMI088 acquisition.

LCD pixel data is always sent over the RGB bus, not SPI.

## LCD supply level

Run LCD VDD at **3.3 V**. Newhaven specifies VDD from 2.5 to 3.3 V; using 3.3 V keeps the ESP32's 3.3 V outputs within the panel's input-high specification.

## Recommended starting RGB timings

From the Newhaven datasheet:

- PCLK: 18 MHz
- horizontal front porch: 40 clocks
- horizontal back porch: 60 clocks
- HS pulse: 20 clocks
- vertical front porch: 10 lines
- vertical back porch: 10 lines
- VS pulse: 6 lines

These are starting values for bench validation and should be verified on the actual panel.

## Prototype wiring rule

The NHD-FFC40 is suitable for bench development and probing. The 18 MHz RGB bus should not be routed over long loose Dupont leads in the final flight-development build. Move the display interconnect to a short carrier PCB after initial proof-of-life.
