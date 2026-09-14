# Flight-development enclosure

This document records the current 3D-printable enclosure design for the ESP32 artificial-horizon project.

> **Status:** flight-development prototype only. This enclosure is not certified, approved or qualified as a primary flight-instrument housing. The geometry, materials, fasteners, vibration resistance, thermal performance and aircraft installation must all be verified before any flight use.

![Flight-development enclosure dimensional preview](../enclosure/images/flight-development-case-preview.svg)

## Purpose

The enclosure is intended to let the electronics, display, IMU, wiring and human-interface arrangement move beyond an open bench prototype and into a mechanically restrained 3 1/8-inch instrument-format test article.

The current design deliberately prioritises:

- compatibility with the conventional 3 1/8-inch round instrument panel format
- a rigid front flange
- positive panel attachment with four screws
- a close-fitting cylindrical locating body
- a protected display pocket
- a removable rear cover
- rear-cover screw bosses rather than a friction-fit lid
- a rear cable/USB exit with room for strain relief
- enough wall thickness for a robust engineering-filament print
- parametric source so dimensions can be revised after measuring the actual Skyranger panel

## Current geometry

| Feature | Current value | Notes |
|---|---:|---|
| Nominal aircraft panel cutout | 79.375 mm | 3.125 in / 3 1/8 in |
| Enclosure locating-body diameter | 78.60 mm | Approx. 0.78 mm diametral clearance in a nominal 3.125 in opening |
| Front flange | 88 × 88 mm | Rounded-square flange |
| Front flange thickness | 4.0 mm | Structural face plate |
| Main body depth | 58.0 mm | From panel face to rear of body |
| Nominal wall thickness | 3.0 mm | First flight-development print target |
| Display opening | 53.6 mm diameter | Slightly larger than the 53.28 mm active area |
| Display pocket | 58.6 × 61.2 mm | Clearance around the selected Newhaven panel outline |
| Panel mounting-hole pattern | 62.9 × 62.9 mm square | Conventional four-hole 3 1/8-inch pattern used for this prototype |
| Panel mounting holes | 3.8 mm diameter | Clearance for #6 hardware |
| Rear-cover screw circle | 66 mm diameter | Four retained positions at 45/135/225/315 degrees |
| Rear-cover holes | 3.2 mm diameter | M3 clearance |
| Rear-cover boss pilot | 2.5 mm diameter | Allows later choice of tapping or insert strategy |
| Rear cable slot | 13 × 7 mm nominal | Deliberately generous for USB-C lead/strain relief |

## Standard panel mounting pattern

The model now includes the conventional four-hole mounting arrangement used by many traditional 3 1/8-inch round aircraft instruments.

For this prototype the four panel screw centres are placed on a **62.9 mm × 62.9 mm square** around the instrument centre. The holes are **3.8 mm diameter**, providing clearance for #6 hardware.

Current aviation suppliers sell panel-layout templates and drill jigs specifically for standard 3 1/8-inch instruments, and conventional installations commonly use #6-32 mounting screws. Before the aircraft panel is drilled or the enclosure is accepted for installation, the actual Skyranger panel must still be measured and compared against this CAD.

References:

- Aircraft Spruce instrument panel layout template: https://www.aircraftspruce.com/catalog/inpages/panel_layout.php
- Aircraft Spruce instrument mounting-hole drill jig: https://www.aircraftspruce.com/catalog/topages/instrumentmounting.php
- VAL INS 422 installation manual example using a standard 3.125-inch round cutout and four 6-32 mounting screws: https://manualmachine.com/valavionics/ins422/20047395-installation--owners-manual/

## CAD and STL files

The parametric source is:

- `enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad`

Generated printable files are:

- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Body.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl`

The STL files are generated automatically by GitHub Actions whenever the OpenSCAD source changes. This keeps the generated files tied to the version-controlled parametric source.

The OpenSCAD source has a `part` selector:

```text
part = "BODY";
part = "COVER";
```

## Improvements over the first sample

The original sample was only a proportion/printability model. The current flight-development version adds:

1. a true 3.125-inch panel-locating diameter rather than an arbitrary round shell
2. the four conventional panel mounting holes
3. an 88 mm structural front flange
4. a display-specific rectangular pocket behind the circular aperture
5. 3 mm nominal walls
6. four rear-cover bosses
7. a removable spigoted rear cover
8. a rear cable/USB opening
9. a top orientation/index feature
10. automatic STL regeneration from the checked-in CAD source

## Printing recommendation

For cockpit development, use an engineering filament with substantially better temperature resistance than ordinary PLA. Suitable candidates for evaluation include ASA, ABS or an appropriate engineering-grade material supported by the printer.

Suggested starting print settings for a development article:

- 0.2 mm layer height or finer
- at least 4 perimeters/walls
- at least 5 top and bottom layers
- 35–50% infill as a starting point
- print the front flange flat if that gives the best dimensional accuracy on the mounting face
- use appropriate support only where needed
- inspect every screw boss for layer separation or voids
- do not install a visibly warped or cracked print

These are development settings, not structural qualification limits.

## Hardware recommendation

For the panel attachment, use proper aviation-compatible machine screws and locking hardware appropriate to the aircraft panel construction rather than relying on self-tapping screws in printed plastic.

For the removable rear cover, the current bosses can be developed toward one of two options:

- M3 threaded brass heat-set inserts, after choosing and measuring the exact insert
- captive nuts / nut plates on a revised rear structure

The final flight-development design should avoid repeatedly driving screws directly into printed plastic.

## Display retention

The current front opening is 53.6 mm diameter and the rear pocket is sized around the selected Newhaven `NHD-2.1-480480AF-ASXP` outline. The next enclosure revision should add the final retention scheme only after the physical display and FFC bend direction are in hand.

Do not clamp the LCD glass directly between hard printed faces. The final assembly should use a controlled support ledge and, if required, a thin compliant gasket or pads placed only where they do not load the active glass area.

## IMU mounting

The BMI088 remains the most mechanically critical internal component. The enclosure still needs a dedicated rigid IMU carrier tied to the enclosure reference axes.

The final carrier must:

- define the BMI088 X/Y/Z orientation unambiguously
- prevent board movement under vibration
- allow repeatable removal/reinstallation
- avoid soft foam suspension
- keep the sensor clear of the high-current backlight wiring where practical

The IMU carrier is intentionally not guessed into this revision; it should be added from the actual Bosch Shuttle Board and internal carrier measurements.

## USB-C and wiring

The rear cover includes a generous cable opening rather than a tightly modelled connector aperture. This is intentional because the actual right-angle USB-C plug, cable bend radius and strain-relief method have not yet been frozen.

Before flight-development use, the cable must be mechanically supported so connector loads are not transferred to the ESP32 board.

## Flight-development checks before installation

At minimum:

- measure the actual panel cutout diameter
- measure all four existing mounting-hole centres
- check panel thickness
- confirm at least 58 mm clear depth behind the panel plus connector/cable allowance
- check full control-column/stick movement and nearby cables/hoses
- confirm no interference with adjacent instruments
- confirm display FFC bend and connector clearance
- perform a sustained maximum-brightness thermal soak
- measure enclosure internal temperature
- vibration-test the complete powered assembly
- verify all fasteners remain secure
- verify no wiring can chafe on the enclosure
- verify the IMU cannot move relative to the enclosure
- confirm failure indications remain visible and obvious

## Material and environmental limitations

A printed enclosure is not automatically suitable for an aircraft cockpit. Sun loading can raise panel temperatures well above ambient. Material creep, softening, UV ageing and vibration fatigue must be considered.

The selected display itself is specified for an operating range of approximately -20 °C to +70 °C, but that does not qualify the complete instrument. The ESP32 board, connectors, adhesive systems, printed polymer, backlight driver and sensor assembly must be assessed as a complete unit.

## What is still required before calling the enclosure final

- actual Skyranger panel measurements
- exact rotary encoder selection and front-panel location
- exact USB-C plug/cable geometry
- physical fit check with the Newhaven display and NHD-FFC40 prototype adapter
- rigid BMI088 carrier geometry
- ESP32 retention method
- TPS61169 retention and insulation
- internal cable routing and tie points
- final rear-cover insert/nut choice
- thermal test results
- vibration test results
- aircraft installation/approval decision

Until those items are complete, this should be treated as the **best current flight-development enclosure**, not a production or approved flight enclosure.
