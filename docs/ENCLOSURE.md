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
- planned **scratch-resistant, anti-reflective optical front window** over the LCD

## Optical bezel/window cover

The LCD should not be the exposed front surface. The preferred arrangement is a separate optical window retained by the front bezel, with a controlled air gap or thin compliant perimeter gasket so bezel loads are not transferred into the LCD glass.

### Frozen optical requirement

The protective window must be both **scratch resistant** and **anti-reflective/non-glare**. Plain polycarbonate is no longer the preferred final material because, although very impact resistant, its uncoated surface scratches too easily and can create strong cockpit reflections.

The current preferred specification is:

| Feature | Preferred specification |
|---|---|
| Substrate | Optical clear polycarbonate |
| Surface treatment | Hard-coated for abrasion/scratch resistance |
| Optical coating | Anti-reflective coating on both sides |
| Optional outer treatment | Anti-fingerprint / oleophobic coating |
| Preferred thickness | 2.0 mm |
| Target visible transmission | Approximately 98% |
| Target reflection | Less than 0.5% in the central visible band where supplier coating supports it |
| Nominal disc diameter | 60–64 mm, to be frozen with bezel CAD |
| Edge | CNC-machined / smooth finished |
| Mounting | Captured by removable bezel, not drilled through |
| LCD contact | None; retain a small air gap or thin compliant perimeter gasket |

### Preferred UK source — Diamond Coatings

The preferred source is **Diamond Coatings Ltd, West Midlands, UK**.

Their current **hard-coated polycarbonate with anti-reflective coating on both sides** is specifically intended for display/optical applications. Diamond Coatings states that its DIAMOX AR treatment on hard-coated polycarbonate can provide approximately **98% transmission and less than 0.5% reflection between 500–600 nm**. An anti-fingerprint coating is also available. They offer multiple thicknesses and state that specific sizes/CNC profiles can be supplied.

Useful links:

- Sunlight-readable hard-coated and anti-reflective polycarbonate: https://diamondcoatings.co.uk/product/sunlight-readable-polycarbonate/
- Hard-coated polycarbonate, AR both sides, AFP one side: https://diamondcoatings.co.uk/product/hard-coated-polycarbonate-anti-reflective-coating-on-both-sides-and-afp-coating-one-side/
- General hard-coated polycarbonate/acrylic capability: https://diamondcoatings.co.uk/hard-coated-polycarbonate-acrylic/

Recommended enquiry specification:

> Optical clear polycarbonate, 2.0 mm thick, hard-coated for abrasion resistance, anti-reflective coated both sides, anti-fingerprint coating on cockpit-facing side if available, CNC cut to a circular disc approximately 60–64 mm diameter. Final diameter to be confirmed after bezel CAD is frozen.

### Alternative UK source — Itotek

**Itotek** also supplies AR-coated acrylic and polycarbonate for flat-screen display applications. Itotek states that its two-sided AR treatment reduces reflectivity from about 8% to **less than 0.5%**, with a hard sub-coat and anti-smudge top layer. Standard thicknesses from 1.0 to 3.0 mm are listed, and CNC machining to customer drawings is available.

- https://www.itotek.co.uk/ar-coated-acrylic-polycarbonate-sheet

This is a strong second-source option if Diamond Coatings cannot provide a small custom circular part economically.

### Why coated polycarbonate rather than ordinary glass

For this supplementary instrument the preferred balance is:

- much higher impact tolerance than mineral glass
- no hazardous glass fragments if damaged
- lower mass
- sufficient optical quality for the 480×480 display
- hard coating to address polycarbonate's normal scratch weakness
- AR treatment to minimise canopy/cockpit reflections

A true AR-coated glass disc may still be considered later if optical testing shows a meaningful advantage, but it would need a safety-conscious edge finish and mounting arrangement and offers less impact tolerance.

### Bezel retention design

The next CAD revision should add:

1. an annular front recess sized to the purchased optical window diameter and measured thickness;
2. approximately 0.2–0.3 mm radial assembly clearance, adjusted after a test print;
3. continuous perimeter support only, with no pressure on the LCD active glass;
4. a removable front retaining bezel/ring rather than adhesive as the sole retention method;
5. a thin black silicone or EPDM perimeter gasket if required for rattle control, dust exclusion and differential expansion;
6. a matte-black internal bezel surface to suppress stray reflections;
7. orientation/handling instructions so the coated surfaces are not scratched during assembly.

Do not clean the coated window with abrasive cloths or aggressive solvents. Cleaning method should follow the coating supplier's instructions.

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

The next CAD revision should provide positive retention for the ESP32-S3 board, Bosch BMI088 Shuttle Board on a rigid axis-defined carrier, TPS61169 backlight board, MCP23008 hardware, display/FFC arrangement, rotary encoder, USB-C strain relief and internal wiring/tie points. It should also incorporate the dedicated 2.0 mm optical-window seat and removable bezel described above.

No flight-development article should contain loose modules, unsupported connectors or Dupont wiring.

## Flight-development verification

Before aircraft use, verify actual panel geometry; M5 insert fit, pull-out and torque behaviour; display/FFC retention; optical-window retention; direct-sunlight reflections and readability; scratch resistance after realistic cleaning; window thermal expansion; no window/LCD contact; rigid IMU alignment; maximum-brightness thermal soak; powered vibration testing; cable strain relief; control clearance; and unmistakable `ATTITUDE INVALID` behaviour on sensor/AHRS failure.

This remains a **supplementary/non-primary artificial horizon under flight development**, not the aircraft's primary attitude instrument.
