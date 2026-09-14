# Flight-development enclosure

This document records the current 3D-printable enclosure design for the ESP32 artificial-horizon project.

> **Intended role:** supplementary/non-primary artificial horizon. This is a flight-development prototype, not the aircraft's primary attitude reference. Geometry, materials, fasteners, vibration resistance, thermal performance and aircraft installation must still be verified before flight use.

![Flight-development enclosure dimensional preview](../enclosure/images/flight-development-case-preview.svg)

## Current mechanical configuration

The enclosure targets the conventional 3 1/8-inch aircraft-instrument format and currently provides:

- 80.30 mm reference panel opening
- 79.60 mm cylindrical locating body
- 88 × 88 mm rounded front flange
- 58 mm body depth
- 3 mm nominal structural wall
- 53.6 mm display aperture and Newhaven-specific display pocket
- four-hole 62.9 × 62.9 mm standard instrument mounting pattern
- 4.4 mm front panel mounting holes
- removable spigoted rear cover
- internal rear-cover screw bosses
- rear USB/cable opening
- four reinforced rear recesses for M5 brass threaded inserts
- planned transparent protective bezel window over the LCD

## Transparent bezel/window cover

The LCD should not be left as the exposed front surface. The preferred development arrangement is a separate transparent circular window retained by the front bezel, with a small controlled air gap or compliant gasket between the window and LCD so that mounting loads are not transferred into the LCD glass.

### Recommended material: hard-coated / optical polycarbonate

Although this part is commonly called the instrument **glass**, the preferred material for this supplementary instrument is **clear polycarbonate rather than ordinary window glass**. Polycarbonate has substantially better impact resistance and is less likely to create sharp fragments if damaged. It is also straightforward to obtain as a custom circular disc in the UK.

The first prototype should use approximately:

| Feature | Starting specification |
|---|---:|
| Material | Clear polycarbonate |
| Preferred finish | Optical/clear; hard-coated and anti-reflective if obtainable |
| Development thickness | 2.0 mm |
| Nominal disc diameter | 60–64 mm, to be frozen after bezel redesign |
| Edge | Smooth/machined |
| Mounting | Captured circumferentially by bezel, not drilled through |
| LCD contact | None; retain a small air gap or thin compliant perimeter gasket |

A 2 mm window is a useful starting point because the exposed aperture is only about 54 mm. The final disc diameter should be larger than the visible opening so the bezel captures the perimeter positively. The CAD must be updated with a dedicated annular seat and retaining lip once the exact disc is selected.

### Anti-reflection and scratch resistance

Bare polycarbonate is tough but scratches more easily than mineral glass. For the final development article, preference should therefore be given to **hard-coated polycarbonate**, ideally with an anti-reflective treatment suitable for displays. If a suitable coated polycarbonate disc cannot be sourced economically, a replaceable plain polycarbonate development window is preferable to exposing the LCD while the optical design is evaluated.

Do not use a heavily tinted window: the selected Newhaven display is bright, but reducing transmission unnecessarily works against sunlight readability. Any anti-glare or anti-reflective surface should be evaluated in direct cockpit sunlight before freezing the material.

### UK sources

Current practical sources include:

- Displaypro — custom clear polycarbonate circles/discs cut to size: https://displaypro.co.uk/products/clear-polycarbonate-circles-displaypro
- Simply Plastics — clear polycarbonate discs/cut-to-size products: https://www.simplyplastics.com/
- Cut Plastic Sheeting — anti-reflective clear acrylic discs are available if an optical acrylic alternative is required: https://www.cutplasticsheeting.co.uk/

Displaypro specifically offers clear polycarbonate circles in different sizes/thicknesses and describes the material as having excellent impact strength and higher heat resistance than acrylic. This makes it a good first UK source for the development window.

### True glass alternative

If a genuine glass face is desired for superior scratch resistance and optical feel, use a **professionally cut and edge-finished safety-glass disc**, not a hand-cut piece of ordinary picture/window glass. UK suppliers that accept circular made-to-measure glass orders include:

- Glasstops UK circular cut-to-size glass: https://www.glasstops.co.uk/order-online/circle-to-size.php
- Prad Glass made-to-measure clear toughened glass: https://pradglass.co.uk/made-to-measure/clear-glass

Prad currently lists clear toughened glass with polished edges and circular/oval CNC shapes, but its online offering starts at 4 mm thickness. That is unnecessarily thick and heavy for this small instrument unless a thinner specialist disc can be supplied. For that reason **2 mm polycarbonate remains the preferred prototype choice**.

### Bezel retention design

The next enclosure CAD revision should add:

1. an annular front recess sized to the selected window diameter and actual measured thickness;
2. approximately 0.2–0.3 mm radial assembly clearance around a plastic disc, adjusted after a test print;
3. a continuous rear shoulder supporting only the perimeter of the window;
4. a removable front retaining bezel/ring rather than adhesive as the sole retention method;
5. a thin black silicone/EPDM perimeter gasket if needed for rattle control, dust exclusion and differential thermal expansion;
6. no hard point contact between the protective window and LCD active glass;
7. a matte-black internal bezel surface to minimise reflections.

Do not permanently bond the cover until sunlight, reflection and thermal testing are complete. A replaceable front window is desirable because scratches can otherwise require replacement of the entire enclosure.

## M5 brass threaded insert mounting

The CAD provides reinforced bosses and brass-insert recesses at the four standard mounting positions on the back of the enclosure. These accept brass threaded inserts with an M5 internal thread so M5 cap-head screws engage a retained metal thread rather than printed polymer.

Current parametric starting dimensions are 12.0 mm boss OD, 10.0 mm boss depth, 7.2 mm insert recess diameter, 8.0 mm recess depth and 5.5 mm M5 screw clearance. The recess diameter and depth must be changed to the dimensions recommended for the exact insert purchased.

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

Preview:

- `enclosure/images/flight-development-case-preview.svg`

Generated STL targets:

- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Body.stl`
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl`

## Material recommendation

Do not use ordinary PLA for cockpit development. Evaluate ASA, ABS or a suitable engineering filament supported by the printer. A useful initial print setup is 0.2 mm layers or finer, at least four perimeters, at least five top/bottom layers and approximately 35–50% infill, followed by inspection and mechanical testing.

## Internal hardware still to be added

The next CAD revision should provide positive retention for the ESP32-S3 board, Bosch BMI088 Shuttle Board on a rigid axis-defined carrier, TPS61169 backlight board, MCP23008 hardware, display/FFC arrangement, rotary encoder, USB-C strain relief and internal wiring/tie points. It should also incorporate the dedicated protective-window seat and removable bezel described above.

No flight-development article should contain loose modules, unsupported connectors or Dupont wiring.

## Flight-development verification

Before aircraft use, verify actual panel geometry; M5 insert fit, pull-out and torque behaviour; display/FFC retention; protective-window retention; direct-sunlight reflections and readability; window thermal expansion; no window/LCD contact; rigid IMU alignment; maximum-brightness thermal soak; powered vibration testing; cable strain relief; control clearance; and unmistakable `ATTITUDE INVALID` behaviour on sensor/AHRS failure.

This remains a **supplementary/non-primary artificial horizon under flight development**, not the aircraft's primary attitude instrument.
