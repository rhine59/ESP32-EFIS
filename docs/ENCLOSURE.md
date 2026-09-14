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
- **direct mounting for the 68 mm custom carrier PCB on a 60 mm PCD**
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

The front bezel incorporates a compact control pod for a physical rotary encoder with push switch.

Reference family: **Bourns PEC09**, prototype reference `PEC09-2320F-T0015`.

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

The pod is on the **cockpit side of the panel**, so the encoder body does not require a second cutout beside the 3 1/8-inch instrument opening.

## Display retention carrier

The display has a removable printed carrier immediately behind the LCD.

| Feature | Value |
|---|---:|
| Carrier outside diameter | 67.0 mm |
| Central opening | 49.0 mm |
| Carrier thickness | 2.5 mm |
| Mounting screw PCD | 64.0 mm |
| Fastener clearance | 2.7 mm, M2.5 class |
| FFC escape opening | 16 mm nominal width |

The carrier supports the LCD perimeter only and leaves a large rear opening for thermal clearance and FFC routing.

## BMI088 rigid carrier

The Bosch BMI088 Shuttle Board 3.0 remains on a dedicated rigid removable cradle.

Reference envelope used by the CAD:

- 22.0 × 14.0 mm PCB
- approximately 1.6 mm PCB thickness
- approximately 6.7 mm overall connector/component height

Current cradle geometry:

| Feature | Value |
|---|---:|
| Tray size | 28.0 × 20.0 mm |
| Tray thickness | 2.5 mm |
| Board pocket | 22.4 × 14.4 mm |
| Pocket depth | 1.8 mm |
| Body mounting-hole spacing | 32.0 mm |
| Fastener clearance | 2.7 mm |
| Nominal cradle position | 30 mm aft of instrument front face |

The carrier must be permanently marked `FWD`, `UP`, and with the aircraft lateral-axis direction. Firmware axis mapping must match the physical installation exactly.

## Custom carrier PCB mounting

The previous printed DevKit electronics carrier has been **retired**.

The optimized architecture uses a purpose-built PCB containing the ESP32-S3-WROOM-1-N16R2, USB-C, 3.3 V regulator, MCP23008 and final display/IMU/control connectors. That PCB mounts directly to four rear-cover standoffs.

### Revision-A board target

| Feature | Value |
|---|---:|
| PCB diameter | 68.0 mm |
| PCB thickness | 1.6 mm starting point |
| Mounting PCD | 60.0 mm |
| Mounting-hole diameter | 2.7 mm |
| Rear-cover standoff OD | 6.0 mm |
| Rear-cover standoff height | 10.0 mm |

The ESP32-S3-WROOM-1 module is placed near the 12-o'clock PCB edge with its integrated antenna facing outward. The PCB must provide the antenna keepout/cutout required by Espressif guidance.

At the 6-o'clock edge, the USB-C connector aligns with the rear-cover service slot.

### PCB fit gauge

The enclosure CAD now generates a printable **PCB fit gauge** instead of the obsolete DevKit carrier:

`enclosure/stl/ESP32_Artificial_Horizon_Custom_PCB_Fit_Gauge.stl`

The gauge represents:

- 68 mm board diameter
- 60 mm mounting PCD
- M2.5-class mounting holes
- 12-o'clock antenna keepout/cutout region
- 6-o'clock USB alignment notch

Print the gauge before ordering PCBs and verify it clears the body, rear cover, BMI088 cradle and wiring paths.

## USB-C service opening and strain relief

The rear cover retains the 13 × 7 mm service slot for a compact USB-C connector/cable arrangement.

A separate two-screw strain-relief clamp grips the cable jacket so vibration and cable movement are not transferred into the PCB-mounted USB-C receptacle.

| Feature | Value |
|---|---:|
| Clamp body | 22 × 12 × 4 mm |
| Fastener spacing | 16.0 mm |
| Fastener clearance | 3.2 mm |
| Cable groove | 5.0 mm starting value |

The cable-groove diameter must be adjusted to the actual cable jacket.

## M5 brass threaded insert mounting

The enclosure provides reinforced bosses and rear brass-insert recesses at the four standard panel mounting positions.

| Feature | Value |
|---|---:|
| M5 boss OD | 12.0 mm |
| M5 boss depth | 10.0 mm |
| Insert recess diameter | 7.2 mm starting value |
| Insert recess depth | 8.0 mm |
| M5 screw clearance | 5.5 mm |

Adjust these to the actual purchased insert manufacturer's recommendations.

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

The actual Skyranger panel dimensions and adjacent-instrument clearance remain controlling.

## CAD source and generated files

Parametric sources:

- `enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad`
- `enclosure/source/ESP32_Artificial_Horizon_Electronics_and_Controls.scad`

Generated STL targets:

- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Body.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Front_Bezel.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Display_Carrier.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_IMU_Carrier.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Custom_PCB_Fit_Gauge.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_USB_Strain_Relief_Clamp.stl`

The former `Flight_Development_Electronics_Carrier.stl` is obsolete and is removed by the STL-generation workflow.

## Assembly order

Current assembly concept from front to rear:

1. front bezel with compact encoder pod
2. PEC09-class rotary encoder and knob
3. 2.0 mm hard-coated AR window
4. optional very thin perimeter gasket
5. enclosure front/window seat
6. Newhaven round LCD
7. removable display carrier
8. rigid BMI088 cradle
9. custom 68 mm carrier PCB on rear-cover standoffs
10. locking harnesses to BMI088, encoder and plug-in TPS61169
11. restrained internal wiring
12. rear cover
13. external USB cable-jacket strain-relief clamp

## Verification before PCB fabrication

Before ordering the custom board:

- print and install the PCB fit gauge
- confirm the 68 mm outline clears the enclosure body
- confirm all four 60 mm PCD holes align with rear standoffs
- confirm the 12-o'clock antenna zone has adequate non-metallic clearance
- confirm the 6-o'clock USB location aligns with the rear-cover slot
- confirm PCB does not collide with the BMI088 cradle or display FFC
- confirm enough clearance remains for locking harness connectors

## Verification before aircraft use

At minimum:

- verify display carrier does not load the LCD active area
- verify FFC bend radius and abrasion protection
- permanently mark and measure BMI088 `FWD`/`UP` alignment
- verify the custom PCB and all connectors remain secure under vibration
- verify no harness relies on an electrical connector as its mechanical anchor
- verify USB strain relief prevents cable load reaching the USB-C receptacle
- perform thermal-soak and powered-vibration testing
- verify optical readability in direct cockpit sunlight
- verify unmistakable `ATTITUDE INVALID` behavior after sensor/AHRS failure

No flight-development article should contain loose modules, unsupported connectors or Dupont wiring.

This remains a **supplementary/non-primary artificial horizon under flight development**, not the aircraft's primary attitude instrument.
