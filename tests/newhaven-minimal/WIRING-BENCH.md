# RedOne EFIS — working Newhaven 2.1-inch AMOLED bench wiring

**Hardware:** ESP32-S3-WROOM-1-N16R8 development board, Newhaven 480×480 ST7701S RGB AMOLED with 40-pin FFC breakout, external TPS61169 LED driver. **Status:** display colour cycle, static blue/brown horizon, and optimized static yellow aircraft reference were individually observed stable on the physical bench (November 2026). This is a **bench prototype, not flight-qualified**.

This document describes the **current working display test** (`tests/newhaven-minimal/main/main.c`), **not** the proposed carrier PCB pin allocation in `firmware/include/pins.h`. The latter allocates GPIO40/41 to BMI088 and routes LCD CS/reset via an MCP23008; those allocations are **not used in this bench setup**.

## ESP32 → Newhaven FFC40 breakout

| ESP32-S3 | Signal | Display FFC pin | Display signal |
|---|---|---:|---|
| GPIO1 | RGB clock | 13 | PCLK |
| GPIO2 | Data enable | 14 | DE |
| GPIO38 | Horizontal sync | 12 | HSYNC |
| GPIO39 | Vertical sync | 11 | VSYNC |
| GPIO4 | RGB D0 | 16 | B1 |
| GPIO5 | RGB D1 | 17 | B2 |
| GPIO6 | RGB D2 | 18 | B3 |
| GPIO7 | RGB D3 | 19 | B4 |
| GPIO8 | RGB D4 | 20 | B5 |
| GPIO9 | RGB D5 | 21 | G0 |
| GPIO10 | RGB D6 | 22 | G1 |
| GPIO11 | RGB D7 | 23 | G2 |
| GPIO12 | RGB D8 | 24 | G3 |
| GPIO13 | RGB D9 | 25 | G4 |
| GPIO14 | RGB D10 | 26 | G5 |
| GPIO15 | RGB D11 | 28 | R1 |
| GPIO16 | RGB D12 | 29 | R2 |
| GPIO17 | RGB D13 | 30 | R3 |
| GPIO18 | RGB D14 | 31 | R4 |
| GPIO21 | RGB D15 | 32 | R5 |
| GPIO40 | 3-wire control chip select | 34 | CSX |
| GPIO41 | Display reset | 33 | RESETX |
| GPIO35 | 3-wire control data | 37 | SDA |
| GPIO36 | 3-wire control clock | 35 | SCL |
| GND | Fixed low RGB bits | 15, 27 | B0, R0 |
| GND | Interface mode | 38, 40 | IM0, IM2 |
| 3.3 V | Interface mode | 39 | IM1 |
| 3.3 V regulated | Display logic power | 3 | VDD |
| Common GND | Display ground | 4, 7, 10 | GND |

**DCX (FFC pin 36):** not driven in the configured 9-bit 3-wire serial mode. **FFC pins 5, 6, 8 and 9:** do not assume a connection; verify their functions against the exact display datasheet. Check FFC connector contact orientation and numbering before reconnecting or altering wiring.

## Backlight driver wiring

| Connection | Destination |
|---|---|
| Regulated 5 V | TPS61169 driver Vin |
| Common GND | TPS61169 driver G |
| ESP32 GPIO42 | TPS61169 PWM (10 kHz, 50% initial duty) |
| TPS61169 L+ | Newhaven FFC pin 2, LED_A |
| TPS61169 LED− | Newhaven FFC pin 1, LED_K |

**Do not connect LED_K directly to GND**: it must return to the LED driver's LED− terminal. The recorded bench switch configuration is default 25 mA + switch 1 (25 mA) + switch 2 (50 mA) = 100 mA; switches 3 and 4 OFF. Confirm against the exact driver board and display rating before powering. Never enable the driver without its LED load connected. All supplies require a common ground.

## Functional overview (not a substitute for the numbered table)

```text
ESP32-S3 N16R8                     Newhaven 480x480 / FFC40
GPIO1  -------------------------> PCLK  (13)
GPIO2  -------------------------> DE    (14)
GPIO38 -------------------------> HSYNC (12)
GPIO39 -------------------------> VSYNC (11)
GPIO4..18, GPIO21 --------------> RGB565 data (see table)
GPIO40 -------------------------> CSX   (34)
GPIO41 -------------------------> RESETX (33)
GPIO35 -------------------------> SDA   (37)
GPIO36 -------------------------> SCL   (35)
3.3V / GND ---------------------> VDD / GND and IM straps
GPIO42 --> TPS61169 PWM
5V ------> TPS61169 Vin
GND -----> TPS61169 G
           TPS61169 L+ ----------> LED_A (2)
           TPS61169 LED- --------> LED_K (1)
```

## Software, recovery and test findings

- ESP-IDF 5.4.4; pixel clock 18 MHz; HSYNC 20/60/40 and VSYNC 6/10/10; 16-bit RGB565; PSRAM disabled following failed octal-PSRAM tests at 80 and 40 MHz.
- Display uses internal DMA bounce buffers, 10 lines each, with `.flags.no_fb=true`. The original complex per-pixel callback triggered `Interrupt wdt timeout on CPU0` and visible black-screen resets.
- Verified stable in sequence: solid blue/brown fields, white horizontal horizon, then optimized yellow aircraft symbol. The successful symbol code fills each scanline and overlays only the relevant symbol segments; it avoids costly per-pixel modulo/geometry tests.
- **Verified physical test (2026-11-20):** the static pitch ladder with four white marks (rows 180, 210, 270 and 300) remained stable with the horizon and yellow aircraft symbol. The user confirmed all four marks visible without black-screen resets. Animated pitch/bank are not yet tested.
- Partition layout: recovery `0x20000` (1 MiB); A/`ota_0` `0x120000` (3 MiB); B/`ota_1` `0x420000` (3 MiB). For this bench test write **only the application binary to `0x420000`**, preserving bootloader, partition table, recovery and A. A raw write does not change OTA selection.
- Bench download mode: hold BOOT, press/release RESET, release BOOT; after a verified flash, press RESET alone. Holding BOOT for 2 seconds **after** application startup requests a return to A.

The display is a bench test only: no IMU, magnetometer, pressure sensor or aircraft integration is validated by these display results.

## Verified simulated pitch test (2026-11-20)

The user observed smooth simulated vertical motion of the horizon and all four pitch marks, with the yellow aircraft reference fixed. No flicker or black-screen resets were observed. The task updates a single `pitch_offset_px` integer every 100 ms, sweeping between -30 and +30 pixels; the ISR reads that value while filling scanlines. **Bank motion and actual sensor data remain untested.**

### Verified simulated bank-angle diagnostic — 20 November 2026

- **Hardware PASS (user observed):** slow simulated bank sweep from −15° to +15°; correct blue/brown sloping horizon; fixed yellow aircraft reference; smooth motion without visible flicker or black flashes.
- ESP-IDF build succeeded; app-only image (244,352 bytes) flashed to `ota_1` at `0x420000`; esptool reported `Hash of data verified`. Recovery and `ota_0` were not written.
- Uses precomputed per-row horizon split spans, double-buffered bank tables, and lightweight DMA bounce-buffer callback; PSRAM disabled. Pitch fixed at zero and pitch marks deliberately omitted for this isolated bank test.
- Previous pitch sweep and this bank sweep were each tested independently. **Combined pitch + bank is not yet implemented or hardware-validated.**

### Verified combined pitch and bank diagnostic — 20 November 2026

- **Hardware PASS (user observed):** simultaneous smooth pitch sweep ±30 pixels and bank sweep ±15°; all four white pitch markings follow the moving/rotating horizon correctly; yellow aircraft reference stays fixed; no visible flicker or black flashes.
- ESP-IDF build completed successfully; 244,784-byte application flashed only to partition B (`ota_1`) at `0x420000`; esptool reported `Hash of data verified`. Recovery and partition A were preserved.
- Geometry and pitch ladder spans are precomputed in task context and double-buffered for the DMA bounce callback. No PSRAM or full framebuffer required.
- This validates **simulated display rendering only**, not sensor-driven attitude estimation or flight suitability.
