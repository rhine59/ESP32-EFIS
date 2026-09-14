# Bill of Materials

This BOM records the current reference hardware for the ESP32 artificial-horizon prototype.

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU board | **Espressif ESP32-S3-DevKitC-1-N8R2** | 1 | 8 MB flash, 2 MB Quad PSRAM; selected because GPIO35–37 remain available externally |
| IMU | **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** | 1 | Official BMI088 evaluation board; project uses SPI |
| Display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 2.1-inch round, 480×480, IPS, 1000 nit, ST7701S, non-touch |
| Display prototype adapter | **Newhaven NHD-FFC40** | 1 | 40-pin 0.5 mm FFC to dual-row 2.54 mm through-hole; bench development adapter |
| Final display connector | **Molex 54104-4031** or verified compatible | 1 | 40-position, 0.5 mm pitch connector named in current Newhaven datasheet |
| Backlight driver | **Adafruit TPS61169 Constant Current Boost Converter (PID 6354)** | 1 | 5 V input; configure for ~100 mA; PWM dimming |
| GPIO expander | **Microchip MCP23008-E/P** | 1 | 8-bit I²C GPIO expander; prototype PDIP version; handles encoder + LCD CS/reset |
| Control | Rotary encoder with push switch | 1 | Encoder A/B and push handled through MCP23008 |
| Power lead | USB-C cable | 1 | Instrument input is regulated 5 V through USB-C |
| 5 V supply | Regulated 5 V source | 1 | External to instrument |
| Wiring | Jumper/prototype wiring | as needed | Bench only |
| Fasteners | M2/M2.5 hardware and threaded inserts | as needed | Enclosure mounting |
| Enclosure | 3D-printed nominal 3 1/8-inch instrument case | 1 | ASA/ABS or suitable engineering filament preferred |

## Important MCU correction

The previously selected **N8R8** DevKitC-1 is not suitable for this pin-heavy prototype because its Octal PSRAM uses GPIO35, GPIO36 and GPIO37 internally. Espressif explicitly marks those GPIOs unavailable on Octal flash/PSRAM variants.

The project therefore uses **ESP32-S3-DevKitC-1-N8R2**. Its 2 MB Quad PSRAM is sufficient for two 480×480 RGB565 frame buffers:

- one RGB565 frame buffer: 480 × 480 × 2 = 460,800 bytes
- two frame buffers: 921,600 bytes

That leaves useful PSRAM headroom while restoring GPIO35–37 for the BMI088/display configuration SPI bus.

## Display bus decision

The Newhaven panel supports 16-bit/pixel RGB operation. The project will use **RGB565** rather than all 18 panel data inputs. This reduces the ESP32 data-bus requirement from 18 GPIOs to 16 without materially affecting an artificial-horizon display.

Wiring convention:

- panel B0 tied low; B1–B5 carry the five blue bits
- panel G0–G5 carry all six green bits
- panel R0 tied low; R1–R5 carry the five red bits

The ST7701S will be configured for 16-bit pixel format during initialization.

## GPIO expander decision

A **Microchip MCP23008** is added to keep low-speed controls off the ESP32's scarce direct GPIOs. It handles:

- LCD configuration chip select
- LCD hardware reset
- rotary encoder A
- rotary encoder B
- rotary encoder push switch

Its interrupt output is connected to one ESP32 GPIO so encoder changes can be serviced promptly rather than slowly polled.

## Remaining mechanical choices

- exact rotary encoder model and shaft dimensions
- rear USB-C strain-relief arrangement
- enclosure mounting-hole geometry from the actual aircraft panel
- final compact carrier PCB layout

## Future optional items

- GNSS receiver for aided attitude development
- independent watchdog/power supervisor
- ambient-light sensor for automatic dimming
- external temperature sensor for enclosure/thermal testing
