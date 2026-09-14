# ESP32-S3 Carrier PCB — schematic definition

This document is the authoritative electrical definition for the first custom carrier PCB used by the ESP32 Artificial Horizon project.

> **Role:** supplementary/non-primary flight-development instrument. This PCB is not certified avionics hardware. It must be bench-tested, thermally tested, vibration-tested and reviewed before aircraft installation.

## 1. Processor module

**U1 — Espressif ESP32-S3-WROOM-1-N16R2**

- 16 MB Quad SPI flash
- 2 MB Quad SPI PSRAM
- 3.3 V supply
- standard -40 to +85 °C module class
- 18.0 × 25.5 × approximately 3.1 mm
- integrated PCB antenna

This module is used instead of an ESP32-S3 DevKit. The carrier therefore includes its own USB-C, 3.3 V regulator, reset/boot circuitry and connectors.

The N16R2 is deliberately retained because its Quad PSRAM leaves GPIO35–37 available. Octal-PSRAM R8/R16 variants consume GPIO33–37 and are not compatible with the present pin map.

## 2. Board mechanical target

First PCB target:

- approximately **68 mm circular PCB**
- four M2.5 mounting holes on **60 mm PCD**
- 1.6 mm FR-4 starting thickness
- four-layer stack preferred
- module antenna at the 12-o'clock edge
- no copper, traces, ground plane, fasteners or metal directly beneath/in front of the module antenna area
- create an edge cutout/keepout beneath the antenna section if needed to satisfy Espressif antenna guidance while remaining inside the instrument body

Recommended four-layer stack:

1. Top — components and signals
2. Inner 1 — uninterrupted GND plane
3. Inner 2 — power plus limited signals
4. Bottom — limited signals / ground fill

The 18 MHz RGB bus should remain short, referenced to continuous ground and routed away from the BMI088 and antenna region.

## 3. 5 V input and USB-C

**J1 — USB-C receptacle, USB 2.0 device / power sink**

Connections:

- VBUS -> `+5V_USB`
- GND -> `GND`
- D- -> USB protection/series network -> GPIO19
- D+ -> USB protection/series network -> GPIO20
- CC1 -> 5.1 kΩ to GND
- CC2 -> 5.1 kΩ to GND
- shield -> chassis/ground strategy to be finalized after EMI testing; prototype may use direct GND through provisioned 0 Ω / RC footprint

Do not route SuperSpeed pairs; this design is USB 2.0 full-speed only.

### USB signal conditioning

Provision:

- **R_USB_DM = 22 Ω** series between GPIO19 and J1 D-
- **R_USB_DP = 22 Ω** series between GPIO20 and J1 D+
- optional DNP capacitor footprint from each USB data line to GND adjacent to U1, as recommended by Espressif
- low-capacitance USB ESD array adjacent to J1

Keep D+/D- short, parallel, length-matched and away from the RGB clock and switching regulator node.

## 4. 3.3 V regulator

**U2 — TI TPS62162-Q1 fixed 3.3 V synchronous buck**

Reference choice:

- 3–17 V input
- fixed 3.3 V output
- 1 A continuous rating
- AEC-Q100 automotive-qualified component
- 2.25 MHz-class switching architecture
- power-good output available

Prototype power path:

```text
USB-C VBUS (+5V_USB)
       |
       +--> TPS62162-Q1
                 |
                 +--> +3V3_SYS
                       +--> ESP32-S3-WROOM-1-N16R2
                       +--> LCD VDD
                       +--> BMI088
                       +--> MCP23008
```

Starting external components, subject to final TI layout review:

- input ceramic: 10 µF X7R/X5R plus 100 nF high-frequency bypass
- inductor: 2.2 µH, saturation/current rating at least 1.5 A preferred
- output ceramic: 22 µF X7R/X5R plus local 100 nF bypassing at loads
- EN tied high to `+5V_USB` through provisioned resistor; test pad retained
- PG pulled up to `+3V3_SYS` and routed to a test pad; firmware monitoring is optional

Place the regulator, inductor and input/output capacitors as a tight cluster. Keep the SW node very small and physically distant from the BMI088 cradle and SPI sensor traces.

## 5. ESP32 power and reset

### U1 supply

- U1 3V3 -> `+3V3_SYS`
- local decoupling adjacent to module supply entry: 10 µF + 1 µF + 100 nF ceramic provision
- all module grounds and exposed ground pad -> solid GND plane with stitching vias

### EN / reset

`EN` must not float.

Starting reset network:

- 10 kΩ pull-up from EN to `+3V3_SYS`
- 1 µF EN-to-GND capacitor starting value
- momentary **RESET** switch from EN to GND
- EN test pad

Final RC values must remain compatible with Espressif power-up/reset timing guidance.

### BOOT

GPIO0 is reserved for boot mode:

- 10 kΩ pull-up to `+3V3_SYS`
- momentary **BOOT** switch from GPIO0 to GND
- GPIO0 test pad

Do not attach operational loads to GPIO0, GPIO3, GPIO45 or GPIO46.

## 6. Display connector

**J2 — Molex 54104-4031 or verified 40-pin 0.5 mm FFC equivalent**

Panel: Newhaven `NHD-2.1-480480AF-ASXP`.

The final PCB routes the display directly; the NHD-FFC40 adapter is bench-only.

### Power and straps

- pin 1 LED_K -> TPS61169 LED output return
- pin 2 LED_A -> TPS61169 boosted LED output
- pin 3 VDD -> `+3V3_SYS`
- pin 4 GND -> GND
- pins 5/6 DN0/DP0 -> NC in RGB mode
- pin 7 GND -> GND
- pins 8/9 CN/CP -> follow Newhaven RGB-mode recommendation; no unverified use
- pin 10 GND -> GND
- pin 38 IM0 -> GND
- pin 39 IM1 -> `+3V3_SYS`
- pin 40 IM2 -> GND

### RGB/timing

- pin 11 VS <- GPIO39
- pin 12 HS <- GPIO38
- pin 13 PCLK <- GPIO1
- pin 14 DE <- GPIO2
- pin 15 B0 -> GND
- pins 16–20 B1..B5 <- GPIO4..GPIO8
- pins 21–26 G0..G5 <- GPIO9..GPIO14
- pin 27 R0 -> GND
- pins 28–32 R1..R5 <- GPIO15,16,17,18,21

### ST7701S configuration interface

- pin 33 RESETX <- MCP23008 GP1
- pin 34 CSX <- MCP23008 GP0
- pin 35 SCL <- GPIO36
- pin 36 DCX -> DNP/test pad; not required for selected 9-bit 3-wire mode
- pin 37 SDA <- GPIO35

Route RGB data/timing as a compact bus with continuous ground reference. Add optional 22–33 Ω source-series resistor footprints on PCLK and, if signal integrity testing shows need, on other high-edge-rate RGB lines.

## 7. BMI088 interface

**J3 — dedicated BMI088 Shuttle Board connector/carrier interface**

Use SPI and separate chip selects:

- +3V3_SYS
- GND
- SCLK <- GPIO36
- MOSI <- GPIO35
- MISO -> GPIO37
- ACC_CS <- GPIO40
- GYRO_CS <- GPIO41

The LCD ST7701S configuration serial bus shares SCLK/MOSI only. During LCD initialization both BMI088 CS lines remain high.

Provide ground adjacent to the SPI signals on the connector where practical.

Keep the BMI088 connector and traces away from:

- TPS62162 switch node/inductor
- TPS61169 backlight switching node
- LCD PCLK trace
- ESP32 antenna zone

## 8. MCP23008 low-speed GPIO

**U3 — Microchip MCP23008**

Carrier PCB implementation should use an SMD package rather than the prototype PDIP part.

Connections:

- VDD -> +3V3_SYS
- VSS -> GND
- SDA <-> GPIO47
- SCL <- GPIO48
- INT -> GPIO43
- A0/A1/A2 -> GND for address `0x20`
- RESET -> +3V3_SYS through pull-up; provision test/reset pad

Add:

- 4.7 kΩ starting pull-ups from SDA and SCL to +3V3_SYS
- 100 nF local decoupling

GPIO allocation:

- GP0 -> LCD CSX
- GP1 -> LCD RESETX
- GP2 -> encoder A
- GP3 -> encoder B
- GP4 -> encoder push
- GP5–GP7 -> spare/test pads

## 9. Rotary encoder connector

**J4 — Bourns PEC09-class front encoder harness**

Provide:

- +3V3_SYS if required for future illuminated/control variant; otherwise NC/DNP
- GND/common
- ENC_A -> MCP23008 GP2
- ENC_B -> MCP23008 GP3
- ENC_SW -> MCP23008 GP4

Use a locking connector rather than loose Dupont pins for the flight-development article.

Debounce will primarily be firmware-controlled, but optional 1 nF–10 nF capacitor footprints may be provisioned after bench testing.

## 10. Backlight driver

Prototype retains the **Adafruit TPS61169 PID 6354** board as a plug-in module; the first custom ESP32 carrier does not yet absorb the bare TPS61169 IC.

**J5 — backlight-driver interface**

- +5V_USB
- GND
- PWM <- GPIO42
- LED_A to display FFC pin 2
- LED_K to display FFC pin 1 as required by the driver/output topology

The backlight driver must not draw LED current from the ESP32 3.3 V rail.

A later PCB revision may integrate the bare LED-driver circuit once display proof-of-life and thermal testing are complete.

## 11. Programming/debug

Primary programming path: native USB on GPIO19/20.

Also provide compact test pads for:

- 3V3
- GND
- EN
- GPIO0
- TXD0 / GPIO43 only if remapped; current GPIO43 is used by MCP23008 INT, so do not assume UART0 pins remain free
- GPIO44 spare/debug
- regulator PG

For early bring-up, add a small 1×4 or Tag-Connect-style debug footprint if space permits, but keep it DNP in the final assembly.

## 12. Frozen GPIO map

| Function | GPIO |
|---|---:|
| LCD D0..D4 / B1..B5 | 4,5,6,7,8 |
| LCD D5..D10 / G0..G5 | 9,10,11,12,13,14 |
| LCD D11..D15 / R1..R5 | 15,16,17,18,21 |
| LCD PCLK | 1 |
| LCD DE | 2 |
| LCD HSYNC | 38 |
| LCD VSYNC | 39 |
| Shared SPI MOSI | 35 |
| Shared SPI SCLK | 36 |
| BMI088 MISO | 37 |
| BMI088 ACC_CS | 40 |
| BMI088 GYRO_CS | 41 |
| Backlight PWM | 42 |
| MCP23008 SDA | 47 |
| MCP23008 SCL | 48 |
| MCP23008 INT | 43 |
| Spare/debug | 44 |
| Native USB D- | 19 |
| Native USB D+ | 20 |

Reserved strapping pins: GPIO0, GPIO3, GPIO45, GPIO46.

## 13. PCB layout priorities

Priority order:

1. Respect the ESP32 module antenna keepout and board-edge placement.
2. Keep a continuous GND plane under high-speed digital routing except the antenna keepout.
3. Keep the TPS62162 switch node compact and away from the IMU.
4. Keep TPS61169/backlight switching currents away from the IMU and USB.
5. Route USB D+/D- first as a clean differential pair.
6. Route PCLK and RGB bus short and direct to J2.
7. Route BMI088 SPI away from PCLK and power-switching nodes.
8. Stitch ground around board perimeter and noisy zones without violating antenna keepout.
9. Provide accessible test pads without creating long stubs on high-speed nets.

## 14. First-revision build strategy

Revision A should deliberately remain conservative:

- integrate ESP32-S3 module, USB-C, 3.3 V buck, MCP23008, display FFC and connectors
- retain plug-in Adafruit TPS61169 for the backlight
- retain external Bosch BMI088 Shuttle Board in its rigid mechanical cradle
- retain external front encoder via locking harness

This reduces the number of new circuits that must work simultaneously on the first custom PCB.

## 15. Bring-up order

1. Inspect bare board for shorts and correct module orientation.
2. Power from current-limited 5 V supply with U1 unpopulated if using staged assembly.
3. Verify +3V3_SYS = 3.3 V and regulator PG.
4. Populate/verify ESP32 module and native USB enumeration.
5. Verify RESET and BOOT controls.
6. Verify MCP23008 at address 0x20.
7. Verify display logic supply and ST7701S reset/configuration.
8. Enable RGB output and static test pattern.
9. Connect BMI088 and verify both SPI devices independently.
10. Connect backlight driver last and raise brightness gradually while monitoring temperature/current.

## 16. References

Use the latest manufacturer documentation before fabrication:

- Espressif ESP32-S3-WROOM-1 / WROOM-1U datasheet
- Espressif ESP32-S3 Hardware Design Guidelines
- Newhaven NHD-2.1-480480AF-ASXP datasheet
- Bosch BMI088 / Shuttle Board documentation
- TI TPS62162-Q1 datasheet
- Microchip MCP23008 datasheet

Any conflict between this project document and a current manufacturer datasheet must be resolved in favor of the manufacturer datasheet and then reflected back into this repository.
