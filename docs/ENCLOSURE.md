# Flight-development enclosure

This document records the current 3D-printable enclosure design for the ESP32 artificial-horizon project.

> **Status:** flight-development prototype only. This enclosure is not certified, approved or qualified as a primary flight-instrument housing. The geometry, materials, fasteners, vibration resistance, thermal performance and aircraft installation must all be verified before any flight use.

![Flight-development enclosure dimensional preview](../enclosure/images/flight-development-case-preview.svg)

## Purpose

The enclosure is intended to move the electronics, display, IMU, wiring and controls beyond an open bench prototype and into a mechanically restrained 3 1/8-inch instrument-format test article.

The current design prioritises:

- compatibility with the conventional 3 1/8-inch round instrument format
- a rigid front flange
- four-point panel attachment
- a close-fitting cylindrical locating body
- a protected display pocket
- a removable rear cover
- rear-cover screw bosses rather than a friction-fit lid
- a rear cable/USB exit with strain-relief allowance
- 3 mm nominal wall thickness
- parametric OpenSCAD source so the design can be revised after measuring the actual Skyranger panel

## Corrected panel-fit geometry

A key correction from the first sample is that a nominal 3 1/8-inch instrument should not be modelled around a literal 79.375 mm panel opening. Real installation guidance uses a slightly oversized opening so the instrument can be inserted without interference.

The current CAD therefore uses **80.30 mm as the reference panel opening** and a **79.60 mm locating-body diameter**, giving approximately **0.70 mm diametral clearance** before allowing for printer tolerance, finish and paint. The actual aircraft panel must still be measured before treating this value as final.

| Feature | Current value | Notes |
|---|---:|---|
| Reference aircraft panel opening | 80.30 mm | Practical 3 1/8-inch class cutout target; verify actual panel |
| Enclosure locating-body diameter | 79.60 mm | Approx. 0.70 mm diametral clearance in 80.30 mm opening |
| Front flange | 88 × 88 mm | Rounded-square flange |
| Front flange thickness | 4.0 mm | Structural face plate |
| Main body depth | 58.0 mm | From panel face to rear of body |
| Nominal wall thickness | 3.0 mm | Development print target |
| Display opening | 53.6 mm diameter | Slightly larger than 53.28 mm active area |
| Display pocket | 58.6 × 61.2 mm | Clearance around selected Newhaven panel outline |
| Panel mounting-hole pattern | 62.9 × 62.9 mm square | Conventional four-hole 3 1/8-inch pattern used for this prototype |
| Panel mounting holes | 4.4 mm diameter | #6 mounting-hole/template class clearance |
| Rear-cover screw circle | 66 mm diameter | Four positions at 45/135/225/315 degrees |
| Rear-cover holes | 3.2 mm diameter | M3 clearance |
| Rear-cover boss pilot | 2.5 mm diameter | Allows later insert/tapping decision |
| Rear cable slot | 13 × 7 mm nominal | USB-C/cable and strain-relief development allowance |

## Standard panel mounting pattern

The model includes the conventional four-hole arrangement used by many traditional 3 1/8-inch round aircraft instruments.

For this prototype the four panel screw centres are on a **62.9 mm × 62.9 mm square** around the instrument centre. The holes are **4.4 mm diameter**, intentionally in the normal #6 mounting-hole/template class rather than tightly dimensioned around the screw shank.

Current aviation suppliers continue to sell drill jigs and panel-layout templates specifically for standard 3 1/8-inch instruments, and current 3 1/8-inch electronic instruments such as the uAvionix AV-30 use four #6-32 mounting screws.

References:

- Aircraft Spruce instrument panel layout template: https://www.aircraftspruce.com/catalog/inpages/panel_layout.php
- Aircraft Spruce instrument mounting-hole drill jig: https://www.aircraftspruce.com/catalog/topages/instrumentmounting.php
- uAvionix AV-30 3 1/8-inch mounting example: https://www.aircraftspruce.com/catalog/inpages/uavionix_11-17556.php
- EAA panel fabrication guidance: https://www.eaa.org/eaa/aircraft-building/builderresources/while-youre-building/building-articles/instruments-and-avionics/making-your-instrument-panel

These references support the general 3 1/8-inch mounting class; the actual Skyranger panel remains the controlling geometry for this project.

## CAD, preview and generated STL files

Parametric source:

- `enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad`

Repository-hosted preview image:

- `enclosure/images/flight-development-case-preview.svg`

Generated printable files:

- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Body.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl`

The STL files are regenerated automatically by GitHub Actions whenever the OpenSCAD source changes. This keeps the checked-in printable geometry tied to the parametric source rather than maintaining unrelated hand-edited STL files.

The OpenSCAD source has a simple selector:

```text
part = "BODY";
part = "COVER";
```

## Improvements over the original sample

The original model was only a proportions/printability exercise. The present flight-development model adds or improves:

1. practical clearance for a 3 1/8-inch class panel opening
2. the conventional four-point mounting pattern
3. realistic #6 mounting-hole clearance
4. an 88 mm structural front flange
5. display-specific aperture and rear pocket
6. 3 mm nominal structural walls
7. four rear-cover bosses
8. a removable spigoted rear cover
9. a rear USB/cable opening
10. a top orientation/index feature
11. repository-hosted dimensional artwork
12. automatic STL regeneration from version-controlled CAD

## Printing recommendation

For cockpit development, ordinary PLA is not recommended because cockpit solar heating can produce temperatures high enough to cause softening or creep.

Suitable materials to evaluate include:

- ASA
- ABS
- a suitable engineering-grade filament supported by the printer

Suggested starting development settings:

- 0.2 mm layer height or finer
- at least 4 perimeters/walls
- at least 5 top and bottom layers
- 35–50% infill as an initial target
- print the front flange flat when practical for best mounting-face accuracy
- inspect every screw boss for voids, cracking or layer separation
- reject any visibly warped or damaged print

These are development settings, not structural qualification limits.

## Panel attachment

Use proper machine screws and locking hardware appropriate to the aircraft panel construction. Do not rely on self-tapping screws in printed plastic for the primary panel attachment.

The CAD currently provides four through-holes in the front flange; the panel or rear mounting hardware should provide the retained thread. The final hardware arrangement should be chosen to match the actual aircraft panel construction and installation approval route.

## Rear-cover attachment

The rear cover uses four M3 clearance holes with matching internal bosses. The present bosses intentionally have pilot holes rather than assuming one fastening technology.

Preferred development options are:

- correctly specified brass heat-set inserts
- captive nuts
- nut plates

Repeatedly driving screws directly into printed polymer is not preferred for a serviceable flight-development instrument.

## Display retention

The front opening is 53.6 mm diameter and the internal rectangular pocket is based on the selected Newhaven `NHD-2.1-480480AF-ASXP` display outline.

The final retention scheme should only be frozen with the physical display and FFC in hand. Do not clamp the LCD glass hard between printed surfaces. Use controlled support points or a suitable thin compliant gasket that does not load the active glass area.

## IMU mounting

The BMI088 remains the most mechanically critical internal part. A dedicated rigid IMU carrier still needs to be added after the Bosch Shuttle Board is physically measured in the intended installation.

The final IMU mount must:

- define aircraft X/Y/Z axes unambiguously
- prevent sensor movement under vibration
- allow repeatable removal and reinstallation
- avoid soft foam suspension that can introduce phase lag
- keep the sensor clear of high-current backlight wiring where practical

## ESP32 and power-module retention

The next mechanical revision should add positive retention for:

- ESP32-S3 board
- BMI088 carrier
- TPS61169 backlight driver
- MCP23008 carrier if separately mounted
- display FFC adapter during prototype development

No flight-development article should contain loose modules, loose Dupont leads or unsupported connectors.

## USB-C and wiring

The rear cover currently uses a generous slot rather than a connector-specific cutout. This allows bench development with different right-angle USB-C leads.

Before flight-development use:

- select the actual USB-C lead or panel connector
- add positive strain relief
- prevent cable loads reaching the ESP32 connector
- prevent chafing at the rear-cover opening
- secure all internal wiring

## Flight-development readiness checklist

Before mounting this enclosure in the aircraft, complete at least the following:

- [ ] measure the actual panel opening diameter at several axes
- [ ] measure all four mounting-hole centres
- [ ] measure panel thickness
- [ ] print a thin front-ring test coupon before committing to the full case
- [ ] confirm the 79.60 mm body slides freely without excessive play
- [ ] verify #6 mounting screws pass cleanly through the flange holes
- [ ] confirm at least 58 mm rear depth plus cable/connector clearance
- [ ] check full stick/control-column travel
- [ ] check nearby cables, hoses and wiring
- [ ] confirm no interference with adjacent instruments
- [ ] confirm the display and FFC bend fit without stress
- [ ] secure every electronic module mechanically
- [ ] secure all wiring against vibration and chafing
- [ ] perform a maximum-brightness thermal soak
- [ ] measure internal enclosure temperature
- [ ] perform powered vibration testing
- [ ] inspect the print and fasteners after vibration testing
- [ ] verify IMU alignment remains unchanged
- [ ] verify display failure and sensor failure produce an unmistakable invalid indication
- [ ] determine the required aircraft installation/approval route before operational use

## Material and environmental limitations

A 3D-printed enclosure is not automatically suitable for an aircraft cockpit. Solar loading can raise instrument-panel temperatures well above ambient. Material creep, glass-transition temperature, UV ageing, vibration fatigue, fastener relaxation and thermal expansion all need consideration.

The selected LCD has its own environmental limits, but those limits do not qualify the complete instrument. The ESP32 board, sensor, connectors, printed polymer, wiring, backlight driver, fasteners and installation must be assessed as one system.

## What remains before this can be called final

- actual Skyranger panel measurements
- physical test print and panel-fit result
- exact rotary encoder selection and location
- exact USB-C connector/lead geometry
- rigid BMI088 carrier
- ESP32 retention features
- TPS61169 retention and insulation
- MCP23008 retention
- display retaining method
- internal cable-routing and tie points
- final insert/nut-plate selection
- thermal test results
- vibration test results
- final aircraft installation/approval decision

Until those items are complete, this is the **best current flight-development enclosure**, not a production, certified or approved primary flight-instrument housing.
