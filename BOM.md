# Bill of Materials

This BOM records the current reference hardware and UK purchasing plan for the ESP32 artificial-horizon prototype. Prices and stock below were checked on **14 September 2026** and will change; verify before ordering.

## Buy now — UK prototype parts

| Item | Reference choice | Qty to buy | Preferred UK supplier | Price checked (ex VAT) | Stock checked | Notes |
|---|---|---:|---|---:|---:|---|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | 2 | DigiKey UK | £4.93 each | 7,267 | Buy two so the first PCB build has a spare. 16 MB flash + 2 MB Quad PSRAM. |
| IMU | **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** | 1 | DigiKey UK | £11.90 | 473 | Official BMI088 evaluation board; project uses SPI. |
| Display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | Mouser UK | £18.37 | 128 | 2.1-inch round 480×480 IPS, sunlight-readable, ST7701S. Source early. |
| Display prototype adapter | **Newhaven NHD-FFC40** | 1 | RS UK | £9.01 | Back-order / incoming | Bench development only; not intended for final flight-development wiring. |
| Backlight driver | **Adafruit TPS61169 PID 6354** | 1 | DigiKey UK | £3.33 | 32 | Constant-current boost board; configure for display backlight and PWM dimming. |
| Rotary encoder | **Bourns PEC09-2320F-T0015** | 1 | DigiKey UK | £3.14 | 1,701 | 9 mm encoder, 20 mm shaft, push switch, 30 detents / 15 PPR. |
| Prototype GPIO expander | **Microchip MCP23008-E/P** | 1 | DigiKey UK | £1.15 | 5,521 | PDIP version useful for bench testing. Final carrier uses an SMD MCP23008. |

Indicative parts subtotal for the table above, excluding VAT, delivery and the NHD-FFC40 availability issue: approximately **£56.76** using two ESP32 modules.

### Current supplier pages

- ESP32-S3-WROOM-1-N16R2: https://www.digikey.co.uk/en/products/detail/espressif-systems/ESP32-S3-WROOM-1-N16R2/16162644
- BMI088 Shuttle Board 3.0: https://www.digikey.co.uk/en/products/detail/bosch-sensortec/SHUTTLE-BOARD-3-0-BMI088/14617528
- Newhaven NHD-2.1-480480AF-ASXP: https://www.mouser.co.uk/ProductDetail/Newhaven-Display/NHD-2.1-480480AF-ASXP
- Newhaven NHD-FFC40: https://uk.rs-online.com/web/p/display-interface-kits/0723891
- Adafruit TPS61169 PID 6354: https://www.digikey.co.uk/en/products/detail/adafruit-industries-llc/6354/26832923
- Bourns PEC09-2320F-T0015: https://www.digikey.co.uk/en/products/detail/bourns-inc/PEC09-2320F-T0015/3780079
- MCP23008-E/P: https://www.digikey.co.uk/en/products/detail/microchip-technology/MCP23008-E-P/735951

## Do not order yet — custom carrier PCB parts

The following parts belong to the custom Revision-A PCB. **Do not bulk-order these until the parked KiCad schematic and PCB layout are completed and the exact manufacturer part numbers and footprints are frozen.**

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU carrier PCB | **Project custom 68 mm Revision-A carrier PCB** | 1–3 | 4-layer preferred, 60 mm mounting PCD, native USB-C, display/IMU/control interfaces |
| 3.3 V regulator | **TI TPS62162-Q1** | 1 | Fixed 3.3 V, 1 A synchronous buck, 3–17 V input, AEC-Q100 |
| Regulator inductor | **2.2 µH, ≥1.5 A preferred** | 1 | Low-DCR shielded part; exact MPN to be frozen |
| Regulator input capacitors | **10 µF X7R/X5R + 100 nF** | 1 each | Exact package/voltage rating to be frozen |
| Regulator output capacitor | **22 µF X7R/X5R** | 1 | Exact package/voltage rating to be frozen |
| USB-C receptacle | **USB 2.0 Type-C receptacle** | 1 | Exact footprint/MPN to be frozen in KiCad |
| USB CC resistors | **5.1 kΩ** | 2 | CC1/CC2 to GND |
| USB series resistors | **22 Ω starting value** | 2 | D- and D+ close to ESP32 |
| USB ESD protection | **Low-capacitance USB ESD array** | 1 | Exact MPN to be frozen; adjacent to connector |
| Final display connector | **Molex 54104-4031** or verified compatible | 1 | 40-position, 0.5 mm FFC; footprint must be verified |
| GPIO expander | **Microchip MCP23008, SMD package** | 1 | I²C address 0x20; exact SMD package to be frozen |
| I²C pull-ups | **4.7 kΩ starting value** | 2 | SDA/SCL to 3.3 V |
| EN/RESET network | per Espressif design guidance | set | Exact passives/switch to be frozen |
| BOOT control | GPIO0 switch/test pad | 1 | Exact switch/footprint to be frozen |
| BMI088 connector | TBD | 1 | Freeze after physical Shuttle Board/harness decision |
| Encoder connector | TBD | 1 | Freeze with harness choice |
| Backlight connector | TBD | 1 | Interface to TPS61169 breakout |
| Test pads | TBD | set | 5 V, 3.3 V, GND, EN, GPIO0 and useful buses |

## Mechanical / installation items

| Item | Qty | Notes |
|---|---:|---|
| 3D-printed enclosure set | 1 | ASA, ABS or suitable engineering filament; avoid PLA for cockpit article |
| Optical window | 1 | ~62 mm diameter, 2.0 mm optical-clear polycarbonate, hard-coated, AR both sides preferred |
| M5 brass threaded inserts | 4 | Final OD/length must match the CAD recess before purchase |
| M5 cap-head screws | 4 | Final length only after measuring actual aircraft panel/installation stack |
| M2/M2.5 inserts and screws | as needed | Display, IMU and PCB retention; freeze exact sizes during physical fit check |
| M3 hardware | as needed | Rear cover / USB strain-relief hardware as defined by CAD |
| Thin black silicone/EPDM gasket | small quantity | Optical-window perimeter only; do not load LCD active glass |
| Short USB-C data/power cable | 1 | Must support data for programming, not charge-only |
| Regulated 5 V bench supply | 1 | Use for development and current measurements |
| Wire / crimp / heat-shrink / lacing or ties | as needed | No loose Dupont wiring in flight-development article |

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
- test pads and power access

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
