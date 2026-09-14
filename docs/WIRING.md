# Wiring Plan

This document records the intended electrical architecture. Exact GPIO assignments will be added after the specific ESP32-S3 board, BMI088 breakout and display module are frozen.

## Power

```text
regulated 5 V source
      │
      └── USB-C ──> ESP32-S3 board
                       │
                       ├── 3.3 V logic/sensor rail as required
                       ├── BMI088
                       └── display/control interfaces
```

The prototype deliberately avoids bringing raw aircraft 12 V into the instrument enclosure.

## BMI088

Preferred interface: SPI.

The BMI088 contains separate accelerometer and gyroscope devices and typically requires separate chip-select handling. The final pin table will identify:

- SCLK
- MOSI
- MISO
- accelerometer CS
- gyroscope CS
- accelerometer interrupt, if used
- gyroscope interrupt, if used
- 3.3 V
- GND

The breakout must be checked carefully for onboard regulators or level shifting before connection.

## Display

The intended display is an ST7701S-class 480×480 RGB panel. Exact signals depend on the chosen module, but may include:

- SPI/config clock/data/chip select
- RGB data bus
- pixel clock
- HSYNC/VSYNC/DE or equivalent timing signals
- reset
- backlight enable/PWM
- power and ground

Because the RGB bus consumes many GPIOs, the exact ESP32-S3 board pinout must be checked before committing the wiring.

## Rotary encoder

Expected signals:

- encoder A
- encoder B
- push button
- ground

Internal or external pull-ups will be chosen to suit the selected encoder and board.

## Grounding

All prototype modules must share a common ground. Wiring should be kept short, especially for SPI and high-speed display signals.

## Final installation considerations

Bench jumper wires are not suitable for a vibrating aircraft environment. The later flight-development build should use:

- locking or positively retained connectors
- proper crimped or soldered terminations
- cable support and strain relief
- secured wiring looms
- separation from noisy ignition or high-current wiring where practical

## GPIO table

To be completed once exact modules are selected.

| Function | ESP32-S3 GPIO | Notes |
|---|---:|---|
| BMI088 SCLK | TBD | |
| BMI088 MOSI | TBD | |
| BMI088 MISO | TBD | |
| BMI088 ACC CS | TBD | |
| BMI088 GYRO CS | TBD | |
| Display interface | TBD | RGB bus/timing |
| Display backlight PWM | TBD | |
| Encoder A | TBD | |
| Encoder B | TBD | |
| Encoder push | TBD | |
