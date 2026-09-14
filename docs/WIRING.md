# Wiring Plan

This document records the intended electrical architecture using the now-selected reference IMU and display. Exact ESP32-S3 GPIO numbers will be frozen after the specific ESP32-S3 development board is selected.

## Power

```text
regulated 5 V source
      │
      └── USB-C ──> ESP32-S3 board
                       │
                       ├── 3.3 V logic/sensor rail
                       │      └── Bosch BMI088 shuttle board
                       │
                       ├── display logic supply as required
                       │
                       └── 5 V rail ──> boost / constant-current LED driver
                                          │
                                          └── ~6 V / 100 mA LCD backlight
```

The prototype deliberately avoids bringing raw aircraft 12 V into the instrument enclosure.

## BMI088 reference board

Selected board: **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088**.

Preferred interface: **SPI**.

The BMI088 contains separate accelerometer and gyroscope interfaces. The design will provide:

- SCLK
- MOSI
- MISO
- accelerometer CS
- gyroscope CS
- optional accelerometer data-ready interrupt
- optional gyroscope data-ready interrupt
- 3.3 V
- GND

Important firmware detail: the accelerometer starts in I²C mode after power-up and must be switched into SPI mode by the documented CS transition / initial dummy SPI access sequence. The gyro interface mode is selected separately.

The Bosch Shuttle Board 3.0 uses **1.27 mm-pitch interconnects**, so a suitable adapter/carrier is required. Do not assume 2.54 mm breadboard compatibility.

## Display reference panel

Selected panel: **Newhaven NHD-2.1-480480AF-ASXP**.

The project will use the display's **18-bit parallel RGB** interface.

Signals will include, according to the final timing implementation:

- RGB data bus: 18 bits
- pixel clock
- DE
- HSYNC / VSYNC as required
- ST7701S configuration/control
- reset
- backlight PWM/enable through the LED driver
- display logic power
- ground

The panel uses a **40-pin, 0.5 mm-pitch FFC**. Newhaven recommends Molex 54104-4096 or a compatible connector.

Because the RGB bus consumes many GPIOs, the exact ESP32-S3 board pinout must be checked before committing the wiring.

## Backlight driver

The Newhaven display backlight is specified at approximately **6.0 V / 100 mA**, while the instrument input is **5 V USB-C**.

A dedicated boost/constant-current LED driver is therefore required between the 5 V rail and the panel backlight.

Requirements for the driver:

- 5 V input
- output voltage compliance comfortably above 6 V
- regulated LED current of at least 100 mA as required by the panel
- PWM or analogue dimming input
- safe startup/shutdown behaviour

The exact driver part remains TBD.

## Rotary encoder

Expected signals:

- encoder A
- encoder B
- push button
- ground

Internal or external pull-ups will be chosen to suit the selected encoder and ESP32 board.

## Grounding

All prototype modules must share a common ground. Wiring should be kept short, especially for BMI088 SPI and the high-speed RGB display bus.

The display bus should ideally move to a short controlled-layout carrier PCB rather than long jumper wires once first power-up is complete.

## Final installation considerations

Bench jumper wires are not suitable for a vibrating aircraft environment. The later flight-development build should use:

- locking or positively retained connectors
- proper crimped or soldered terminations
- cable support and strain relief
- secured wiring looms
- separation from noisy ignition or high-current wiring where practical

## GPIO table

To be completed once the exact ESP32-S3 board is selected.

| Function | ESP32-S3 GPIO | Notes |
|---|---:|---|
| BMI088 SCLK | TBD | Shared SPI clock |
| BMI088 MOSI | TBD | Shared SPI MOSI |
| BMI088 MISO | TBD | Shared SPI MISO |
| BMI088 ACC CS | TBD | Separate chip select |
| BMI088 GYRO CS | TBD | Separate chip select |
| BMI088 ACC DRDY | TBD | Optional |
| BMI088 GYRO DRDY | TBD | Optional |
| Display R0–R5 | TBD | 6 red data bits |
| Display G0–G5 | TBD | 6 green data bits |
| Display B0–B5 | TBD | 6 blue data bits |
| Display PCLK | TBD | Pixel clock |
| Display DE | TBD | Data enable |
| Display HSYNC | TBD | If required |
| Display VSYNC | TBD | If required |
| Display reset | TBD | |
| Display init/config | TBD | ST7701S configuration interface |
| Backlight PWM | TBD | Drives LED-driver control input |
| Encoder A | TBD | |
| Encoder B | TBD | |
| Encoder push | TBD | |
