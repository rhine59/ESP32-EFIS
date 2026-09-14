# Bill of Materials

This BOM records the current reference hardware for the ESP32 artificial-horizon prototype.

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | 1 | 16 MB flash, 2 MB Quad PSRAM; active module; preserves GPIO35–37 for this pin-heavy RGB design |
| MCU carrier PCB | **Project custom carrier PCB** | 1 | Provides 5 V input, 3.3 V regulation, native USB-C, EN/BOOT, decoupling and project connectors; replaces the bulky DevKit in the final prototype |
| IMU | **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** | 1 | Official BMI088 evaluation board; project uses SPI |
| Display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 2.1-inch round, 480×480, IPS, 1000 nit, ST7701S, non-touch |
| Display prototype adapter | **Newhaven NHD-FFC40** | 1 | 40-pin 0.5 mm FFC to dual-row 2.54 mm through-hole; bench development adapter |
| Final display connector | **Molex 54104-4031** or verified compatible | 1 | 40-position, 0.5 mm pitch connector named in current Newhaven datasheet |
| Backlight driver | **Adafruit TPS61169 Constant Current Boost Converter (PID 6354)** | 1 | 5 V input; configure for ~100 mA; PWM dimming |
| GPIO expander | **Microchip MCP23008-E/P** | 1 | 8-bit I²C GPIO expander; prototype PDIP version; handles encoder + LCD CS/reset |
| Control | **Bourns PEC09-class rotary encoder with push switch** | 1 | Encoder A/B and push handled through MCP23008 |
| Power lead | USB-C cable | 1 | Instrument input is regulated 5 V through USB-C |
| 5 V supply | Regulated 5 V source | 1 | External to instrument during development |
| Wiring | Prototype wiring | as needed | Bench only; no Dupont wiring in flight-development assembly |
| Fasteners | M2/M2.5/M3/M5 hardware and threaded inserts | as needed | Enclosure mounting |
| Enclosure | 3D-printed nominal 3 1/8-inch instrument case | 1 | ASA/ABS or suitable engineering filament preferred |

## Optimised MCU choice

The project now uses **ESP32-S3-WROOM-1-N16R2** as the reference processor module rather than building the final instrument around a DevKitC board.

Reasons:

- 16 MB Quad flash gives ample firmware, graphics-asset, diagnostics and update headroom.
- 2 MB Quad PSRAM is sufficient for two complete 480×480 RGB565 frame buffers.
- Quad PSRAM avoids the GPIO35–37 loss associated with Octal PSRAM configurations.
- the bare module is substantially smaller and mechanically cleaner than a development board;
- native ESP32-S3 USB can be brought directly to the instrument USB-C connector;
- the final carrier PCB can place power, display, IMU and control connectors exactly where needed.

Framebuffer requirement:

- one RGB565 frame buffer: 480 × 480 × 2 = 460,800 bytes
- two frame buffers: 921,600 bytes

Two frame buffers therefore use about 0.92 MB, leaving useful PSRAM headroom for graphics working memory while AHRS state remains small.

The earlier `ESP32-S3-DevKitC-1-N8R2` remains acceptable as a **bench-development substitute** if one is already available, because it uses the same ESP32-S3 architecture and Quad PSRAM arrangement. It is no longer the reference final hardware because that exact DevKit variant is obsolete at major distributors.

Do **not** substitute an `N8R8`/Octal-PSRAM module without redesigning the GPIO map. Espressif documents GPIO35, GPIO36 and GPIO37 as part of the Octal memory interface, which conflicts with the current display/IMU allocation.

## Custom MCU carrier requirements

The final carrier PCB should include:

- ESP32-S3-WROOM-1-N16R2
- 5 V USB-C input
- correctly sized low-noise 3.3 V regulator with adequate transient current
- local bulk and high-frequency decoupling
- native USB D-/D+ routing to GPIO19/GPIO20
- EN reset network
- BOOT access to GPIO0
- programming/test pads
- display RGB/timing connector
- shared LCD-init/BMI088 SPI connector
- I²C connector for MCP23008
- PWM output to TPS61169
- defined ground plane and short return paths

Wi-Fi and Bluetooth are not required for normal attitude display operation and should be disabled in the normal flight firmware unless a specific maintenance function requires them.

## Display bus decision

The Newhaven panel supports 16-bit/pixel RGB operation. The project uses **RGB565** rather than all 18 panel data inputs. This reduces the ESP32 data-bus requirement from 18 GPIOs to 16 without materially affecting an artificial-horizon display.

Wiring convention:

- panel B0 tied low; B1–B5 carry the five blue bits
- panel G0–G5 carry all six green bits
- panel R0 tied low; R1–R5 carry the five red bits

The ST7701S is configured for 16-bit pixel format during initialization.

## GPIO expander decision

A **Microchip MCP23008** keeps low-speed controls off the ESP32's scarce direct GPIOs. It handles LCD configuration chip select, LCD hardware reset, rotary encoder A/B and encoder push switch. Its interrupt output uses one ESP32 GPIO.

## Remaining hardware choices

- exact production carrier PCB layout
- final USB-C cable jacket diameter for the strain-relief clamp
- exact M5 and M2/M2.5 insert types
- physical verification of the actual aircraft panel geometry

## Future optional items

- GNSS receiver for aided attitude development
- independent watchdog/power supervisor
- ambient-light sensor for automatic dimming
- external temperature sensor for enclosure/thermal testing
