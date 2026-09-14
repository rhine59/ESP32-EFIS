# Wiring Plan

This document records the electrical architecture using the selected ESP32-S3, BMI088 and Newhaven 1000-nit display.

## Power

```text
regulated 5 V source
      |
      +-- USB-C --> ESP32-S3-DevKitC-1-N8R8
      |                |
      |                +-- 3.3 V logic/sensor rail --> BMI088
      |                +-- display logic/interface
      |
      +-- TPS61169 constant-current boost driver
                         |
                         +-- LED_A / LED_K --> display backlight (~6 V / 100 mA)
```

Raw aircraft 12 V is deliberately kept outside the prototype instrument.

## Display connection

Selected panel: **Newhaven NHD-2.1-480480AF-ASXP**.

Prototype adapter: **Newhaven NHD-FFC40**. This converts a 40-pin 0.5 mm FFC to a dual-row 20 × 2, 2.54 mm-pitch through-hole layout. This makes bench probing and wiring substantially easier than working directly on the panel flex.

Final compact carrier: use **Molex 54104-4096** or a verified compatible 40-position 0.5 mm FFC/FPC connector.

### Newhaven panel FFC signals

| FFC pin | Signal | Purpose |
|---:|---|---|
| 1 | LED_K | Backlight cathode |
| 2 | LED_A | Backlight anode |
| 3 | VDD | TFT supply |
| 4 | GND | Ground |
| 5 | DNP | Do not populate/connect unless manufacturer specifies otherwise |
| 6 | DP0 | MIPI signal; unused in selected RGB mode |
| 7 | GND | Ground |
| 8 | CN | MIPI signal; unused in selected RGB mode |
| 9 | CP | MIPI signal; unused in selected RGB mode |
| 10 | GND | Ground |
| 11 | VS | Vertical sync |
| 12 | HS | Horizontal sync |
| 13 | PCLK | RGB pixel clock |
| 14 | DE | Data enable |
| 15-20 | B0-B5 | Blue RGB data |
| 21-26 | G0-G5 | Green RGB data |
| 27-32 | R0-R5 | Red RGB data |
| 33 | RESETX | Display reset |
| 34 | CSX | ST7701S serial configuration chip select |
| 35 | SCL | ST7701S serial configuration clock |
| 36 | DCX | ST7701S serial command/data control |
| 37 | SDA | ST7701S serial configuration data |
| 38 | IM0 | Interface-mode selection |
| 39 | IM1 | Interface-mode selection |
| 40 | IM2 | Interface-mode selection |

The IM0/IM1/IM2 levels must be set for the selected 18-bit RGB operating mode according to the Newhaven/ST7701S initialization requirements. Do not guess these levels during assembly.

## BMI088

Selected board: **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088**, using SPI.

Required signals are SCLK, MOSI, MISO, accelerometer CS, gyroscope CS, optional accelerometer/gyro data-ready interrupts, 3.3 V and GND. The accelerometer and gyro are separate logical devices. Firmware must perform the Bosch-required accelerometer transition into SPI mode after reset.

## Backlight

Selected development driver: **Adafruit TPS61169 Constant Current Boost Converter, PID 6354**.

The Newhaven backlight is approximately 6 V / 100 mA. Configure the driver for 100 mA and use an ESP32 PWM-capable output for brightness control. LED current must never be sourced directly from an ESP32 GPIO.

## GPIO assignment status

The ESP32-S3-DevKitC-1-N8R8 is now frozen, but the final GPIO map is intentionally not committed until the RGB LCD peripheral requirements, ESP32-S3 boot/strapping pins, USB/JTAG use and PSRAM/flash restrictions have all been cross-checked together. This avoids creating a superficially complete pin table that cannot boot or conflicts with the RGB peripheral.

The final map must allocate:

- 18 RGB data outputs
- PCLK, DE, HS and VS
- RESETX and ST7701S serial configuration signals
- BMI088 SPI clock/data and two chip selects
- BMI088 interrupt(s), if used
- backlight PWM
- rotary encoder A/B/push

## Prototype wiring rule

The NHD-FFC40 is suitable for bench development and measurement. Long Dupont leads are not suitable for the high-speed RGB bus in a flight-development build. Once display timing is proven, move the ESP32/display interconnect to a short dedicated carrier PCB.

## Grounding and installation

All modules share common ground. Keep BMI088 SPI wiring short and keep the IMU away from high-current backlight wiring where practical. Flight-development wiring should use retained connectors, proper strain relief and mechanically secured looms.
