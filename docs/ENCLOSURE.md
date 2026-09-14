# Flight-development enclosure

This document records the current 3D-printable enclosure design for the ESP32 artificial-horizon project.

> **Intended role:** supplementary/non-primary artificial horizon. This is a flight-development prototype, not the aircraft's primary attitude reference. Geometry, materials, fasteners, vibration resistance, thermal performance and aircraft installation must still be verified before flight use.

![Flight-development enclosure dimensional preview](../enclosure/images/flight-development-case-preview.svg)

## Current mechanical configuration

The enclosure targets the conventional 3 1/8-inch aircraft-instrument format and now provides:

- 80.30 mm reference panel opening
- 79.60 mm cylindrical locating body
- 88 × 88 mm rounded front flange
- 58 mm body depth
- 3 mm nominal structural wall
- Newhaven-specific display pocket
- four-hole 62.9 × 62.9 mm standard instrument mounting pattern
- 4.4 mm front panel mounting holes
- 2.0 mm hard-coated anti-reflective optical window
- removable optical-window retaining bezel
- removable display retention carrier
- separate rigid BMI088 Shuttle Board cradle
- rear-service electronics carrier
- ESP32 edge-location rails
- TPS61169 mounting zone
- MCP23008/prototype-board mounting zone
- front-side compact rotary-encoder control pod
- rear USB-C service slot
- separate cable-jacket strain-relief clamp
- removable spigoted rear cover
- four reinforced rear recesses for M5 brass threaded inserts

## Optical front window and bezel

The CAD targets a **62.0 mm diameter × 2.0 mm** hard-coated anti-reflective optical polycarbonate disc. The window seat is 62.5 mm diameter and 2.25 mm deep, with a 55.0 mm visible opening.

Preferred optical stack from front to rear:

1. removable front bezel/control assembly
2. hard-coated AR optical window
3. very thin compliant perimeter gasket only if required
4. annular support seat
5. controlled air gap
6. Newhaven LCD
7. removable display retention carrier

No hard mounting load should be transmitted through the protective window into the LCD active glass.

## Front rotary-encoder control pod

The revised front bezel incorporates a compact control pod for a physical rotary encoder with push switch.

The reference part is the **Bourns PEC09 9 mm incremental encoder family**, with prototype part `PEC09-2320F-T0015`. Bourns specifies the T-style hardware with an M7 × 0.75 threaded bushing and nominal 7.2 mm panel hole.

Current pod geometry:

| Feature | Value |
|---|---:|
| Pod width | 14.0 mm |
| Pod height | 14.0 mm |
| Pod depth | 9.0 mm |
| Pod centre | 37.0 mm below display centre |
| Encoder panel/bushing hole | 7.2 mm |
| Internal encoder body allowance | 11.5 × 11.5 mm |
| Internal body depth allowance | 6.5 mm |

The pod is positioned on the **cockpit side of the panel**. This is deliberate: the encoder body does not require a second hole or rectangular notch in the aircraft panel next to the 3 1/8-inch instrument cutout.

The pod sits outside the 55 mm optical opening, so it does not obscure the active display area. The exact encoder must still be physically measured before the production print.

## Display retention carrier

The display has its own removable printed carrier immediately behind the LCD.

Current geometry:

| Feature | Value |
|---|---:|
| Carrier outside diameter | 67.0 mm |
| Central opening | 49.0 mm |
| Carrier thickness | 2.5 mm |
| Mounting screw PCD | 64.0 mm |
| Fastener clearance | 2.7 mm, for M2.5 hardware |
| Body boss OD | 6.0 mm |
| Body boss height | 7.0 mm |
| FFC escape opening | 16 mm nominal width |

The carrier supports the LCD perimeter only, while retaining a large rear opening and a dedicated FFC escape so the flex tail is not forced into a tight bend.

## BMI088 rigid carrier

The Bosch BMI088 Shuttle Board 3.0 is mounted on a dedicated rigid removable cradle rather than foam, adhesive tape or the display carrier.

Reference board envelope used by the CAD:

- 22.0 mm × 14.0 mm PCB
- approximately 1.6 mm PCB thickness
- approximately 6.7 mm overall connector/component height

Current cradle geometry:

| Feature | Value |
|---|---:|
| Tray size | 28.0 × 20.0 mm |
| Tray thickness | 2.5 mm |
| Board pocket | 22.4 × 14.4 mm |
| Pocket depth | 1.8 mm |
| Edge rail width | 2.0 mm |
| Edge rail height | 3.0 mm |
| Body mounting-hole spacing | 32.0 mm |
| Fastener clearance | 2.7 mm, for M2.5 hardware |
| Nominal cradle position | 30 mm aft of instrument front face |

The final carrier must be permanently marked `FWD`, `UP`, and with the aircraft lateral-axis direction. Firmware axis mapping must match the physical installation exactly.

## Rear-service electronics architecture

A separate rear electronics carrier is now part of the CAD. The aim is to make the processor and support electronics serviceable without disturbing the optical stack or BMI088 alignment.

The revised rear cover contains four internal standoffs on a **60 mm PCD**. The removable electronics plate mounts to these standoffs with M2.5-class hardware.

### Electronics carrier

| Feature | Value |
|---|---:|
| Carrier diameter | 70.0 mm |
| Carrier thickness | 2.5 mm |
| Mounting PCD | 60.0 mm |
| Mounting-hole diameter | 2.7 mm |
| Standoff OD | 6.0 mm |
| Standoff height | 10.0 mm |

### ESP32 mounting

The carrier uses **edge-location rails and a shallow locating pocket**, rather than assuming a particular DevKit mounting-hole pattern. The current reference envelope is approximately 25.8 × 62.8 mm and is oriented with the USB end toward the rear-cover cable slot.

This is intentional because the selected `ESP32-S3-DevKitC-1-N8R2` is now obsolete at major distributors. If a replacement Quad-PSRAM ESP32-S3 board is selected, the rail dimensions can be adjusted without redesigning the main enclosure.

The USB end remains open so the connector is not trapped by a printed rail.

### TPS61169 zone

The Adafruit TPS61169 PID 6354 is approximately **25.2 × 19.0 × 10.1 mm**. The electronics carrier provides tie-slot retention around this envelope instead of guessed PCB mounting holes.

The backlight board should be mounted on the face opposite the ESP32 where practical, with wire clearance maintained around the LED output and PWM/power connections.

### MCP23008 / small-carrier zone

A second generic mounting zone is reserved for an MCP23008 prototype board or compact carrier PCB. This uses tie slots rather than hard-coded hole positions because the final custom carrier PCB has not yet been laid out.

### Harness restraint

Additional tie slots are included around the electronics carrier so internal wires can be restrained independently of their connectors. No connector should act as a cable anchor under vibration.

## USB-C service opening and strain relief

The rear cover retains the existing 13 × 7 mm service slot for a compact/right-angle USB-C lead.

The revision adds a **separate two-screw strain-relief clamp**. Its purpose is to grip the cable jacket so vibration and cable movement are not transmitted into the ESP32 USB-C receptacle.

Current starting geometry:

| Feature | Value |
|---|---:|
| Clamp body | 22 × 12 × 4 mm |
| Fastener spacing | 16.0 mm |
| Fastener clearance | 3.2 mm, for M3 hardware |
| Cable groove | 5.0 mm diameter starting value |

The cable-groove diameter is deliberately parametric. It **must be changed to suit the actual selected USB-C cable jacket**. The clamp should retain the cable securely without crushing the insulation.

## M5 brass threaded insert mounting

The enclosure provides reinforced bosses and rear brass-insert recesses at the four standard mounting positions.

Current parametric starting dimensions are:

| Feature | Value |
|---|---:|
| M5 boss OD | 12.0 mm |
| M5 boss depth | 10.0 mm |
| Insert recess diameter | 7.2 mm |
| Insert recess depth | 8.0 mm |
| M5 screw clearance | 5.5 mm |

These dimensions must be adjusted to the actual purchased insert manufacturer's recommendations before the final print.

## Standard panel geometry

| Feature | Current value |
|---|---:|
| Reference panel opening | 80.30 mm |
| Enclosure locating-body diameter | 79.60 mm |
| Front flange | 88 × 88 mm |
| Front flange thickness | 4.0 mm |
| Main body depth | 58.0 mm |
| Panel mounting-hole pattern | 62.9 × 62.9 mm square |
| Front mounting holes | 4.4 mm diameter |
| Nominal wall thickness | 3.0 mm |

The actual Skyranger panel dimensions and spacing around adjacent instruments remain controlling. The new encoder pod must be checked against the real panel before installation.

## CAD source and generated files

Parametric sources:

- `enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad`
- `enclosure/source/ESP32_Artificial_Horizon_Electronics_and_Controls.scad`

Generated STL targets:

- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Body.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Front_Bezel.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Display_Carrier.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_IMU_Carrier.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Electronics_Carrier.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_USB_Strain_Relief_Clamp.stl`

GitHub Actions regenerates the STL set whenever the enclosure OpenSCAD source or build workflow changes.

## Assembly order

Current mechanical assembly concept from front to rear:

1. front bezel with compact encoder pod
2. Bourns PEC09-class rotary encoder and knob
3. 2.0 mm hard-coated AR window
4. optional very thin perimeter gasket
5. enclosure front/window seat
6. Newhaven round LCD
7. removable display carrier
8. rigid BMI088 cradle on dedicated body bosses
9. rear-service electronics carrier
10. ESP32 board on edge-location rails
11. TPS61169 and MCP23008/prototype hardware on carrier mounting zones
12. restrained internal harness
13. service rear cover
14. external USB cable-jacket strain-relief clamp

## Printing recommendation

Do not use ordinary PLA for cockpit development. Evaluate ASA, ABS or a suitable engineering filament supported by the printer.

Suggested starting settings:

- 0.2 mm layers or finer
- at least four perimeters
- at least five top/bottom layers
- approximately 35–50% infill
- matte-black visible bezel surfaces
- inspect every M2/M2.5/M3/M5 boss closely for voids, cracking or delamination

## Verification before aircraft use

At minimum:

- physically measure the Newhaven display, BMI088, ESP32 board and chosen encoder against the CAD
- verify the front encoder pod clears the actual aircraft panel and neighboring instruments
- verify the encoder cannot contact or load the optical window
- verify the display carrier does not load the LCD active area
- verify FFC routing and bend radius
- permanently mark and measure BMI088 `FWD` / `UP` alignment
- verify ESP32 cannot slide out of its carrier rails under vibration
- verify TPS61169 and MCP23008 hardware cannot shift or chafe wiring
- confirm every harness is restrained independently of electrical connectors
- select the final USB-C cable and tune the strain-relief groove to its jacket
- verify the USB connector sees no meaningful cable load after clamping
- conduct thermal-soak and powered-vibration testing
- verify fasteners and inserts remain secure afterward
- verify the optical window remains scratch-free and readable in direct cockpit sunlight
- verify unmistakable `ATTITUDE INVALID` behavior after sensor/AHRS failure

## Remaining mechanical work

The main enclosure architecture is now substantially defined. Remaining mechanical work is primarily **physical-fit validation and refinement**, not another wholesale enclosure redesign:

- measure purchased parts and tune parametric clearances
- select the exact ESP32-S3 Quad-PSRAM board
- select the exact PEC09 suffix/shaft length and knob
- select the exact USB-C lead and set clamp diameter
- replace the temporary MCP23008 prototype arrangement with a compact custom carrier PCB
- perform test prints, vibration checks and thermal checks

No flight-development article should contain loose modules, unsupported connectors or Dupont wiring.

This remains a **supplementary/non-primary artificial horizon under flight development**, not the aircraft's primary attitude instrument.
