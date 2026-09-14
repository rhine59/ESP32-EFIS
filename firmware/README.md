# ESP-IDF Firmware

Target hardware: **ESP32-S3-WROOM-1-N16R2** on the project custom carrier PCB.

Framework baseline: **ESP-IDF v5.4.2**.

This directory is now a buildable ESP-IDF project rather than a placeholder. The current milestone is a **display proof-of-life build**: initialize the low-speed control hardware, run the Newhaven/ST7701S startup sequence, create a 480×480 RGB565 panel with two PSRAM framebuffers, draw a static artificial horizon, and only then enable the LCD backlight.

The BMI088/AHRS path is intentionally the next milestone rather than being mixed into the first display bring-up.

## Build

With ESP-IDF installed:

```bash
cd firmware
idf.py set-target esp32s3
idf.py build
```

To flash and monitor over native USB once the carrier is connected:

```bash
idf.py -p /dev/cu.usbmodemXXXX flash monitor
```

Use the actual device name reported by macOS rather than copying the example literally.

GitHub Actions also builds the project automatically through `.github/workflows/build-firmware.yml` using Espressif's official ESP-IDF CI action.

## Current source layout

```text
firmware/
├── CMakeLists.txt
├── sdkconfig.defaults
├── include/
│   └── pins.h
└── main/
    ├── CMakeLists.txt
    ├── app_main.c
    ├── mcp23008.c
    ├── mcp23008.h
    ├── st7701s.c
    ├── st7701s.h
    ├── horizon_renderer.c
    └── horizon_renderer.h
```

## Display mode

- panel: Newhaven `NHD-2.1-480480AF-ASXP`
- controller: ST7701S
- resolution: 480 × 480
- project pixel format: RGB565
- ESP32 RGB bus width: 16 bits
- RGB pixel clock baseline: **30 MHz**
- HFP: **50**
- HBP: **50**
- HS pulse width: **4**
- VFP: **50**
- VBP: **50**
- VS pulse width: **2**
- ST7701S setup: 3-wire / 9-bit serial control, then parallel RGB pixel streaming
- panel mode straps: IM0=0, IM1=1, IM2=0

The older 18 MHz timing values previously recorded in this repository belong to Newhaven's MIPI timing table. The current firmware now uses the manufacturer's current **RGB timing table**.

## RGB565 controller setting

Newhaven's published example initialization uses an 18-bit `COLMOD` setting. The ST7701S documentation defines `VIPF=101` as the 16-bit RGB mode. The firmware therefore changes that one pixel-format field to the 16-bit setting while retaining Newhaven's panel-specific power/gamma sequence.

This must be confirmed on the physical panel during bench bring-up. If colour ordering or pixel alignment is wrong, do not compensate in the AHRS renderer; first verify the controller pixel-format setting and FFC data mapping.

## Framebuffers

One RGB565 frame buffer is:

```text
480 × 480 × 2 = 460,800 bytes
```

Two complete buffers require 921,600 bytes. The N16R2 module's 2 MB Quad PSRAM is therefore sufficient for double buffering with useful remaining headroom.

ESP-IDF's native RGB LCD driver allocates both buffers in PSRAM.

## Initialization order implemented now

1. configure BMI088 chip-select pins high
2. force backlight off
3. initialize MCP23008 over I²C
4. configure the ST7701S 3-wire serial GPIOs
5. hardware-reset the LCD through MCP23008
6. run the Newhaven-derived ST7701S initialization sequence in RGB565 mode
7. create the ESP-IDF RGB LCD peripheral at 480×480 / 16 bit / 30 MHz
8. obtain two PSRAM-backed framebuffers
9. draw the static test horizon into both buffers
10. select the prepared frame
11. enable the backlight

The backlight is deliberately enabled last so an uninitialized or random framebuffer is not presented as a valid-looking attitude display.

## Current proof-of-life screen

The renderer displays:

- blue sky
- brown ground
- white horizon
- symmetric pitch-ladder test marks
- fixed yellow aircraft symbol
- centre datum

This is a test pattern, not yet an attitude solution. Its purpose is to expose timing, pixel-format, colour-order and framebuffer problems immediately.

## Next firmware milestone

The next implementation stage is:

1. initialize BMI088 accelerometer and gyro on the shared SPI bus
2. verify chip IDs and communication health
3. perform the accelerometer's required post-reset SPI transition
4. put the accelerometer into active/normal mode
5. acquire gyro + accelerometer at ~200 Hz
6. estimate stationary gyro bias
7. add quaternion AHRS
8. replace the static renderer inputs with live pitch/roll
9. add sensor-freshness and AHRS-confidence monitoring
10. replace the horizon with an unmistakable `ATTITUDE INVALID` state whenever attitude validity is lost

## Safety behaviour

The finished renderer must never leave a plausible frozen horizon after sensor or AHRS failure. Stale data, failed sensor communication, implausible timing or failed validity checks must obscure the normal attitude display.

The intended failure indication remains:

```text
ATTITUDE
 INVALID
```

This project remains a **supplementary/non-primary flight-development instrument**.
