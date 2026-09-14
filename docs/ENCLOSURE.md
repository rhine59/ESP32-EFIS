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
- removable spigoted rear cover
- rear USB/cable opening
- four reinforced rear recesses for M5 brass threaded inserts
- dedicated seat for a 2.0 mm hard-coated anti-reflective optical window
- separate removable front retaining bezel
- **removable display retention carrier**
- **separate rigid BMI088 Shuttle Board cradle**

## Optical front window and bezel

The current CAD targets a 62.0 mm diameter, 2.0 mm hard-coated anti-reflective optical polycarbonate disc. The window seat is 62.5 mm diameter and 2.25 mm deep, with a 55.0 mm visible opening. The removable bezel is 70.0 mm OD with a 55.0 mm opening, 2.5 mm main thickness and four M2 fasteners on a 67.0 mm PCD.

Preferred optical material remains hard-coated AR polycarbonate, ideally AR coated both sides with anti-fingerprint treatment on the cockpit-facing surface. Preferred UK source is Diamond Coatings Ltd, with Itotek as a second source.

Recommended optical stack from front to rear:

1. removable front bezel
2. hard-coated AR optical window
3. very thin compliant perimeter gasket only if required
4. annular support seat
5. controlled air gap
6. Newhaven LCD
7. removable display retention carrier

No hard mounting load should be transmitted through the protective window into the LCD active glass.

## Display retention carrier

The display now has its own removable printed carrier immediately behind the LCD. This is deliberately separate from the main enclosure so the LCD can be serviced without replacing the body.

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

The carrier is annular so it supports only the LCD perimeter and leaves a large central opening for airflow, rear display clearance and FFC routing. A lower-edge FFC escape slot prevents the flex tail from being forced into a tight bend.

The carrier should use a thin compliant perimeter pad or gasket only where needed to prevent rattling. It must not bow the LCD or press on the active glass.

## BMI088 rigid carrier

The Bosch BMI088 Shuttle Board 3.0 is now mounted on a dedicated removable cradle rather than on foam, adhesive tape or the display carrier.

The Bosch board envelope used by the CAD is approximately:

- 22.0 mm × 14.0 mm PCB
- approximately 1.6 mm board thickness
- approximately 6.7 mm overall connector/component height

The cradle uses a shallow locating pocket and edge rails instead of assuming an unverified mounting-hole pattern. This is intentional: the board is mechanically located by its documented external envelope, while the physical board can still be measured before the final print.

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

The cradle is fixed to two dedicated body bosses to provide a repeatable rigid datum. It must be installed with the IMU axes explicitly marked and recorded relative to the aircraft.

### IMU axis requirement

Before flight-development use, the final cradle must carry permanent markings for at least:

- `FWD`
- `UP`
- aircraft lateral axis direction

Firmware axis mapping must match the physical installation exactly. Removing and reinstalling the cradle should return the sensor to the same orientation without needing an arbitrary software correction.

Soft foam suspension is not preferred because it can introduce dynamic phase lag. If any compliant material is used, it should be limited to very thin anti-rattle/contact pads rather than acting as the primary structural mount.

## M5 brass threaded insert mounting

The CAD provides reinforced bosses and rear brass-insert recesses at the four standard mounting positions. These accept M5 threaded brass inserts so M5 cap-head screws engage a retained metal thread rather than printed polymer.

Current parametric starting dimensions are 12.0 mm boss OD, 10.0 mm boss depth, 7.2 mm insert recess diameter, 8.0 mm insert recess depth and 5.5 mm M5 screw clearance. The insert recess must be adjusted to the purchased insert manufacturer's dimensions before the final print.

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

The actual Skyranger panel dimensions remain controlling.

## CAD and generated files

Parametric source:

- `enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad`

Generated STL targets:

- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Body.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Front_Bezel.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Display_Carrier.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_IMU_Carrier.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl`

GitHub Actions regenerates all five STL files when the OpenSCAD source or workflow changes.

## Assembly order

Current mechanical assembly concept from front to rear:

1. front bezel
2. 2.0 mm hard-coated AR window
3. optional thin perimeter gasket
4. enclosure front/window seat
5. Newhaven round LCD
6. removable display carrier
7. internal electronics volume
8. rigid BMI088 cradle on its dedicated body bosses
9. ESP32/backlight/GPIO hardware — next CAD stage
10. rear cover

## Printing recommendation

Do not use ordinary PLA for cockpit development. Evaluate ASA, ABS or a suitable engineering filament supported by the printer.

Suggested starting settings:

- 0.2 mm layers or finer
- at least four perimeters
- at least five top/bottom layers
- approximately 35–50% infill
- matte-black bezel inner surfaces
- inspect all small M2/M2.5/M5 bosses closely for voids or delamination

## Verification of new carriers

Before aircraft use:

- physically measure the Newhaven display and BMI088 Shuttle Board against the CAD
- confirm display carrier does not load the LCD active area
- confirm FFC routing does not exceed the cable's bend tolerance or rub on printed edges
- verify display cannot move under vibration
- verify BMI088 board is fully seated and cannot shift within the cradle
- verify no cradle rail contacts sensitive components or connector solder joints
- permanently mark the IMU carrier `FWD` and `UP`
- measure the installed sensor-axis alignment relative to the instrument body
- remove/reinstall the IMU carrier and confirm repeatable alignment
- verify carrier screws remain secure after thermal and vibration testing
- confirm there is no mechanical interference between the IMU carrier and future ESP32/electronics supports

## Remaining internal mechanical work

The next enclosure revision should add positive retention for:

- ESP32-S3 board
- TPS61169 backlight board
- MCP23008 hardware
- rotary encoder
- USB-C strain relief
- internal harness/tie points

The ESP32 selection itself should also be rechecked before finalising its exact mounting pattern because the originally selected ESP32-S3-DevKitC-1-N8R2 is now obsolete at major distributors.

No flight-development article should contain loose modules, unsupported connectors or Dupont wiring.

This remains a **supplementary/non-primary artificial horizon under flight development**, not the aircraft's primary attitude instrument.
