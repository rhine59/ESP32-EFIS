# Bill of Materials

This BOM records the current reference hardware for the ESP32 artificial-horizon prototype.

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | 1 | 16 MB flash, 2 MB Quad PSRAM; preserves GPIO35–37 |
| MCU carrier PCB | **Project custom 68 mm Revision-A carrier PCB** | 1 | 4-layer preferred, 60 mm mounting PCD, native USB-C, display/IMU/control interfaces |
| 3.3 V regulator | **TI TPS62162-Q1** | 1 | Fixed 3.3 V, 1 A synchronous buck, 3–17 V input, AEC-Q100 automotive-qualified |
| Regulator inductor | **2.2 µH, ≥1.5 A preferred** | 1 | Select low-DCR shielded part; verify against TI layout/design guidance |
| Regulator input capacitor | **10 µF X7R/X5R + 100 nF** | 1 each | Close to TPS62162-Q1 VIN/GND |
| Regulator output capacitor | **22 µF X7R/X5R** | 1 | Close to inductor/regulator output loop |
| USB-C receptacle | **USB 2.0 Type-C receptacle** | 1 | Sink/device use; exact footprint to be frozen in KiCad |
| USB CC resistors | **5.1 kΩ** | 2 | CC1/CC2 to GND |
| USB series resistors | **22 Ω starting value** | 2 | D- and D+ close to ESP32 as recommended by Espressif |
| USB ESD protection | **Low-capacitance USB ESD array** | 1 | Place adjacent to USB-C connector |
| IMU | **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** | 1 | Official BMI088 evaluation board; project uses SPI |
| Display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 2.1-inch round, 480×480, IPS, 1000 nit, ST7701S |
| Display prototype adapter | **Newhaven NHD-FFC40** | 1 | Bench only |
| Final display connector | **Molex 54104-4031** or verified compatible | 1 | 40-position, 0.5 mm FFC |
| Backlight driver | **Adafruit TPS61169 PID 6354** | 1 | Plug-in Revision-A module; ~100 mA LED current, PWM dimming |
| GPIO expander | **Microchip MCP23008, SMD package** | 1 | I²C, address 0x20; encoder + LCD CS/reset |
| I²C pull-ups | **4.7 kΩ starting value** | 2 | SDA/SCL to 3.3 V |
| Control | **Bourns PEC09-class rotary encoder with push switch** | 1 | Front pod; exact suffix to be physically verified |
| Power lead | USB-C cable | 1 | 5 V development input |
| 5 V supply | Regulated 5 V source | 1 | External to instrument during development |
| Fasteners | M2/M2.5/M3/M5 hardware and inserts | as needed | Enclosure/PCB mounting |
| Enclosure | 3D-printed nominal 3 1/8-inch instrument case | 1 | ASA/ABS or suitable engineering filament preferred |

## Optimised MCU choice

The project uses **ESP32-S3-WROOM-1-N16R2** rather than a DevKit in the final prototype.

Reasons:

- 16 MB Quad flash provides substantial firmware/asset/update headroom.
- 2 MB Quad PSRAM is sufficient for two 480×480 RGB565 framebuffers.
- Quad PSRAM keeps GPIO35–37 available.
- the module is much smaller than a development board.
- native USB is routed directly to the instrument USB-C connector.
- the carrier PCB can place power and connectors exactly around the instrument geometry.

Framebuffer requirement:

- one RGB565 frame buffer: 460,800 bytes
- two frame buffers: 921,600 bytes

Do **not** substitute an R8/R16 Octal-PSRAM variant without redesigning the GPIO map; those configurations consume GPIO33–37.

## Revision-A custom carrier

The first PCB integrates:

- ESP32-S3-WROOM-1-N16R2
- USB-C power/programming
- TPS62162-Q1 3.3 V regulator
- EN/RESET and GPIO0/BOOT controls
- MCP23008 in SMD form
- Newhaven 40-pin FFC connector
- BMI088 harness/carrier connector
- rotary-encoder harness connector
- plug-in TPS61169 interface
- test pads and power-good access

The board target is approximately **68 mm diameter**, **1.6 mm thick**, with four **2.7 mm holes on a 60 mm PCD**. A printed PCB fit gauge is generated before board fabrication.

Authoritative design documents:

- `hardware/schematics/CARRIER_PCB_SCHEMATIC.md`
- `hardware/schematics/carrier-netlist.csv`
- `hardware/pcb/README.md`

## Display bus decision

The Newhaven panel is used in **16-bit RGB565** mode:

- B0 tied low; B1–B5 carry blue
- G0–G5 carry green
- R0 tied low; R1–R5 carry red

ST7701S setup uses the shared 9-bit serial interface before RGB output starts.

## Flight-development configuration

Wi-Fi and Bluetooth are not required for normal attitude display operation and should remain disabled in normal flight firmware unless deliberately enabled for a maintenance/test function.

No loose Dupont wiring should remain in the assembled instrument.

## Future optional items

- integrate bare TPS61169 on a later PCB revision
- integrate an independent watchdog/power supervisor
- GNSS aiding
- ambient-light sensor
- enclosure temperature sensor
