# Firmware Baseline

Target hardware: **ESP32-S3-DevKitC-1-N8R2**.

Recommended framework: **ESP-IDF** using the native `esp_lcd` RGB panel driver and PSRAM-backed frame buffers.

## Display mode

- resolution: 480 × 480
- pixel format: RGB565
- data width: 16 bits
- initial pixel clock: 18 MHz
- HS front porch: 40
- HS back porch: 60
- HS pulse width: 20
- VS front porch: 10
- VS back porch: 10
- VS pulse width: 6
- ST7701S setup: 9-bit SPI, then RGB pixel streaming
- panel mode straps: IM0=0, IM1=1, IM2=0

The Newhaven panel must be configured for 16-bit pixel format before enabling normal RGB output.

## Frame buffers

One RGB565 frame buffer is 460,800 bytes. Two are 921,600 bytes, so the N8R2 board's 2 MB PSRAM is sufficient for double buffering with substantial remaining headroom.

Use PSRAM-backed double buffering for smooth bank/pitch animation and to reduce tearing.

## Initialization order

1. initialize logging and watchdogs
2. initialize MCP23008 on I²C
3. hold LCD reset low
4. ensure BMI088 chip selects are high
5. release LCD reset
6. select LCD through MCP23008
7. perform ST7701S 9-bit SPI initialization, including 16-bit pixel format
8. deselect LCD
9. initialize the ESP32 RGB LCD peripheral
10. initialize BMI088 accelerometer and gyro over SPI
11. calibrate stationary gyro bias
12. start sensor acquisition / AHRS task
13. start renderer
14. enable backlight only after a valid display image is being generated

## Task-rate starting points

- BMI088 acquisition: 200 Hz starting target
- AHRS update: 200 Hz
- display render: 50–60 Hz target
- validity/watchdog checks: every AHRS cycle

These are development targets, not fixed flight-qualified values.

## Safety behaviour

The renderer must never leave a plausible frozen horizon after sensor or AHRS failure. On stale data, impossible timing, sensor communication failure or failed validity checks, obscure the normal display with an unmistakable `ATTITUDE INVALID` annunciation.

## Pin definitions

See `include/pins.h` and `../../docs/WIRING.md`.
