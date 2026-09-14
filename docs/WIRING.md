# Wiring Plan

This document records the prototype electrical architecture and frozen GPIO allocation for the custom ESP32-S3 carrier PCB.

## Power

```text
regulated 5 V source / USB-C VBUS
      |
      +--> TPS62162-Q1 3.3 V buck
      |         |
      |         +--> ESP32-S3-WROOM-1-N16R2
      |         +--> BMI088
      |         +--> LCD VDD
      |         +--> MCP23008
      |
      +--> TPS61169 constant-current backlight driver
                |
                +--> LED_A / LED_K --> LCD backlight (~6 V / 100 mA)
```

Raw aircraft 12 V is deliberately kept outside the prototype instrument during this phase.

## Processor module

Selected module: **ESP32-S3-WROOM-1-N16R2**.

Reasons:

- 16 MB Quad flash
- 2 MB Quad PSRAM
- enough PSRAM for two 480×480 RGB565 framebuffers
- GPIO35–37 remain available
- integrated PCB antenna
- active production module rather than an obsolete DevKit

The custom carrier replaces the previous DevKit and therefore includes native USB-C, 3.3 V regulation, EN/RESET, BOOT, display connector and low-speed GPIO hardware.

## USB-C

Native USB is connected directly to the ESP32-S3:

- GPIO19 = USB D-
- GPIO20 = USB D+
- 22 Ω starting series resistors on D- and D+
- 5.1 kΩ sink resistors from CC1 and CC2 to GND
- low-capacitance USB ESD protection near the connector

Keep D+/D- short, parallel and away from LCD PCLK and switching nodes.

## 3.3 V regulator

Reference regulator: **TI TPS62162-Q1**, fixed 3.3 V, 1 A.

Starting external network:

- 10 µF input ceramic plus 100 nF bypass
- 2.2 µH inductor, at least ~1.5 A preferred current rating
- 22 µF output ceramic plus local decoupling
- power-good test point

The regulator/inductor switching loop must be kept away from the BMI088 and its SPI traces.

## Display electrical mode

Selected panel: **Newhaven NHD-2.1-480480AF-ASXP**.

Final connector: **Molex 54104-4031** or verified equivalent 40-pin 0.5 mm FFC connector.

The panel is operated as:

- 480 × 480
- 16-bit RGB565 pixel bus
- DE mode
- **30 MHz** RGB pixel clock starting point
- 9-bit SPI only for ST7701S initialization

### RGB + serial mode straps

- IM0 = 0
- IM1 = 1
- IM2 = 0

DCX is not required by the selected 3-wire 9-bit serial protocol because command/data state is carried in the ninth bit.

### RGB565 connection

- D0..D4 -> panel B1..B5
- D5..D10 -> panel G0..G5
- D11..D15 -> panel R1..R5
- panel B0 -> GND
- panel R0 -> GND

The ST7701S initialization configures the RGB interface for 16-bit/pixel mode (`VIPF=101`).

## Frozen ESP32 GPIO map

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
| LCD PCLK | 1 | 30 MHz RGB starting point |
| LCD DE | 2 | Data enable |
| LCD HSYNC | 38 | Horizontal sync |
| LCD VSYNC | 39 | Vertical sync |
| Shared SPI MOSI | 35 | LCD SDA during init; BMI088 MOSI afterwards |
| Shared SPI SCLK | 36 | LCD SCL during init; BMI088 SCLK afterwards |
| BMI088 MISO | 37 | LCD does not require MISO |
| BMI088 ACC CS | 40 | Accelerometer chip select |
| BMI088 GYRO CS | 41 | Gyro chip select |
| Backlight PWM | 42 | TPS61169 control |
| MCP23008 SDA | 47 | I²C |
| MCP23008 SCL | 48 | I²C |
| MCP23008 INT | 43 | Encoder interrupt-on-change |
| Spare / debug | 44 | Test pad |
| Native USB D- | 19 | USB |
| Native USB D+ | 20 | USB |

## Reserved ESP32 pins

| GPIO | Reason |
|---:|---|
| 0 | BOOT strap and button only |
| 3 | Strapping pin |
| 45 | Strapping pin |
| 46 | Strapping pin |

No operational loads should be attached to those strapping pins.

## MCP23008 allocation

Address: `0x20`, A0/A1/A2 tied low.

- GP0 -> LCD CSX
- GP1 -> LCD RESETX
- GP2 -> encoder A
- GP3 -> encoder B
- GP4 -> encoder push
- GP5–GP7 -> spare/test pads

Use interrupt-on-change for encoder inputs.

## Shared SPI behaviour

1. Hold BMI088 ACC CS and GYRO CS high.
2. Drive LCD CSX low through MCP23008.
3. Perform ST7701S 9-bit initialization using GPIO35/36.
4. Drive LCD CSX high.
5. Thereafter use the same SCLK/MOSI pair for BMI088 acquisition.

LCD pixel data is always sent over the RGB bus, not SPI.

## LCD supply

LCD VDD runs from **+3V3_SYS**. Newhaven specifies 2.5–3.3 V.

## Starting RGB timings

The current Newhaven datasheet gives the following **RGB** timing values:

- PCLK: **30 MHz**
- HFP: **50** clocks
- HBP: **50** clocks
- HS pulse: **4** clocks
- VFP: **50** lines
- VBP: **50** lines
- VS pulse: **2** lines

The earlier 18 MHz / 40 / 60 / 20 / 10 / 10 / 6 values were Newhaven's **MIPI** timing table and must not be used as the baseline RGB timing.

These RGB values remain subject to bench verification on the actual panel and carrier PCB.

## PCB implementation rule

The first custom PCB is approximately **68 mm diameter** on the existing **60 mm mounting PCD**. It mounts directly to the rear-cover standoffs and replaces the former printed DevKit carrier.

The ESP32-S3-WROOM-1 antenna sits at the PCB edge. Follow Espressif antenna keepout guidance: no copper, traces, fasteners or metal in the antenna zone, and use a board-edge cutout/keepout as required.

A printed PCB fit gauge is generated from the enclosure CAD to verify the mechanical envelope before fabrication.

## Authoritative schematic files

- `hardware/schematics/CARRIER_PCB_SCHEMATIC.md`
- `hardware/schematics/carrier-netlist.csv`
