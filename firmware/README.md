# ESP-IDF Firmware

Target: **ESP32-S3-WROOM-1-N16R2**, framework baseline **ESP-IDF v5.4.4**.

The firmware is now structured as a **multi-panel supplementary flight instrument**. The Newhaven 480×480 RGB565 display and double PSRAM framebuffer architecture are unchanged, but the front-panel Bourns `PEC09-2320F-T0015` now controls three screens:

1. Artificial Horizon
2. Classic Altimeter
3. Compass

A short encoder press advances to the next panel. A long press of about 0.8 seconds enters/leaves the current panel's settings. Rotation changes that panel's setting: Horizon brightness, Altimeter QNH, or Compass heading bug.

Per-panel operating documentation is in [`../docs/user-guides/`](../docs/user-guides/README.md).

## Important current limitation

The new screen framework is implemented before all live sensors are available. The firmware therefore marks flight data **invalid** rather than inventing plausible values:

- Horizon: BMI088 communication exists, but live quaternion AHRS is not yet connected.
- Altimeter: a barometric/static-pressure sensor is not yet part of the hardware.
- Compass: BMI088 has no magnetometer and cannot provide stable absolute heading by itself.

This is intentional fail-obvious behaviour for a supplementary/non-primary instrument.

## Source layout

```text
main/
├── app_main.c              display/sensor startup and UI loop
├── instrument_ui.c/.h      PEC09 short/long press and rotary settings
├── instrument_screens.c/.h three-panel renderer and data-validity contract
├── horizon_renderer.c/.h   horizon graphics
├── bmi088.c/.h             BMI088 SPI bring-up
├── mcp23008.c/.h           LCD control plus encoder input I/O
└── st7701s.c/.h            panel controller initialization
```

## Display configuration

- Newhaven `NHD-2.1-480480AF-ASXP`
- ST7701S
- 480×480 RGB565, 16-bit RGB bus
- 30 MHz pixel clock
- HFP/HBP/HS = 50/50/4
- VFP/VBP/VS = 50/50/2
- two 460,800-byte framebuffers in 2 MB Quad PSRAM

The ST7701S is configured first over 3-wire/9-bit serial; the same GPIOs are then reused for BMI088 SPI. The project adapts Newhaven's panel sequence from 18-bit to the ST7701S 16-bit `VIPF=101` mode; physical-panel verification remains required.

## Control implementation

MCP23008 GP2/GP3 read encoder A/B and GP4 reads the active-low push switch, all with pull-ups. `instrument_ui_poll()` runs approximately every 10 ms. A short released press cycles panels; holding for about 800 ms toggles settings. Encoder rotation is ignored outside settings to avoid accidental in-flight value changes.

Settings are currently RAM-only. NVS persistence will be added once the settings/data-source design is frozen. Brightness is represented in the UI but still needs to be connected to TPS61169 PWM rather than the current simple on/off backlight output.

## Data-source contract

`instrument_data_t` separates each value from its validity flag. A renderer must not treat a stale or absent value as valid. The future sensor tasks will update pitch/roll, altitude and heading independently with freshness/health checks.

## Next implementation stages

The attitude path remains first: configure BMI088 ranges/ODR, acquire at ~200 Hz, timestamp samples, calibrate gyro bias, apply aircraft-axis transform, run quaternion AHRS and acceleration-confidence logic, then feed live pitch/roll to the Horizon panel.

The Altimeter additionally needs selection/integration of a suitable static-pressure sensor and pressure-to-altitude/QNH processing. The Compass needs a deliberate absolute-heading architecture; gyro yaw alone is not acceptable as a compass. A magnetometer or other aiding source must be evaluated for the aircraft installation.

## Build/deploy

See [DEPLOYMENT.md](DEPLOYMENT.md). Normal local build:

```bash
source ~/.espressif/tools/activate_idf_v5.4.4.sh
cd firmware
idf.py build
```

GitHub Actions builds the same ESP32-S3 firmware automatically.

## Safety behaviour

No panel may leave a plausible frozen flight indication after its source becomes stale or invalid. The final UI will use explicit textual invalid annunciations; the current screen framework uses a prominent invalid overlay until the font/annunciation renderer is added.

This project remains a **supplementary/non-primary flight-development instrument**.
