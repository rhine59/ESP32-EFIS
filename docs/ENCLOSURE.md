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
- dedicated seat for a **2.0 mm hard-coated anti-reflective optical window**
- separate removable front retaining bezel
- four M2 bezel-retaining screw positions

## Optical front window and bezel

The protective optical window is now incorporated into the CAD rather than being only a documented future requirement.

### Window geometry

The current CAD targets:

| Feature | Current CAD value |
|---|---:|
| Optical window material | Hard-coated AR optical polycarbonate |
| Nominal window diameter | 62.0 mm |
| Nominal thickness | 2.0 mm |
| Radial assembly clearance | 0.25 mm per side |
| Window seat diameter | 62.5 mm |
| Window seat depth | 2.25 mm |
| Visible optical opening | 55.0 mm |
| LCD active area | 53.28 mm |

The 55 mm clear opening leaves a small margin around the LCD active area while the 62 mm disc provides enough captured perimeter for reliable retention.

The 2.25 mm seat depth intentionally leaves a small allowance above the 2.0 mm optical window for tolerance and a very thin compliant perimeter gasket if required. The window must not be clamped hard against the LCD.

### Removable front bezel

A separate front bezel is now generated as its own printable part:

- outside diameter: **70.0 mm**
- clear opening: **55.0 mm**
- main ring thickness: **2.5 mm**
- locating spigot depth: **1.5 mm**
- four M2 retaining screws at 0/90/180/270 degrees
- screw circle: **67.0 mm diameter**

The bezel is designed to capture the optical disc circumferentially while keeping the visible display area unobstructed. It should be printed with a matte-black finish on its inner visible surfaces to suppress stray reflections.

The front body has matching bosses with pilot holes for an M2 insert/tapped-thread decision. For repeated servicing, small brass threaded inserts are preferred over repeatedly threading directly into printed polymer.

### Optical material requirement

The window must remain both **scratch resistant** and **anti-reflective**. Plain polycarbonate is not the preferred final material.

Preferred specification:

- optical clear polycarbonate
- hard abrasion-resistant coating
- anti-reflective coating both sides
- anti-fingerprint/oleophobic cockpit-facing surface if available
- approximately 2.0 mm thickness
- target transmission around 98%
- target reflection below about 0.5% in the supplier's optimized visible band

Preferred UK source: **Diamond Coatings Ltd**.

- https://diamondcoatings.co.uk/product/sunlight-readable-polycarbonate/
- https://diamondcoatings.co.uk/product/hard-coated-polycarbonate-anti-reflective-coating-on-both-sides-and-afp-coating-one-side/

Second source: **Itotek**.

- https://www.itotek.co.uk/ar-coated-acrylic-polycarbonate-sheet

Recommended purchase enquiry now becomes:

> Optical clear polycarbonate, 2.0 mm thick, hard-coated for abrasion resistance, anti-reflective coating both sides, anti-fingerprint treatment on cockpit-facing side if available, CNC cut to a 62.0 mm circular disc with clean finished edge.

Before ordering a production quantity, confirm the actual supplied thickness tolerance and coating handling instructions.

## Window installation

Recommended stack from front to rear:

1. removable printed front bezel
2. hard-coated AR optical window
3. very thin black silicone/EPDM perimeter gasket only if required
4. annular printed support seat
5. controlled air gap
6. Newhaven LCD

Important rules:

- no adhesive across the optical aperture
- no direct hard contact between the protective window and LCD active glass
- no excessive screw torque on the bezel
- tighten bezel screws evenly in a cross pattern
- retain a replaceable optical window so scratches do not require enclosure replacement
- use only coating-compatible cleaning materials

## M5 brass threaded insert mounting

The CAD provides reinforced bosses and rear brass-insert recesses at the four standard mounting positions. These accept M5 threaded brass inserts so M5 cap-head screws engage a retained metal thread rather than printed polymer.

Current parametric starting dimensions are:

| Feature | Value |
|---|---:|
| M5 boss OD | 12.0 mm |
| M5 boss depth | 10.0 mm |
| Insert recess diameter | 7.2 mm |
| Insert recess depth | 8.0 mm |
| M5 screw clearance | 5.5 mm |

The insert recess must be adjusted to the purchased insert manufacturer's recommended hole dimensions before the final print.

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
- `enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl`

The GitHub Actions workflow now generates all three parts whenever the OpenSCAD source changes.

## Printing recommendation

Do not use ordinary PLA for cockpit development. Evaluate ASA, ABS or a suitable engineering filament supported by the printer.

Suggested starting settings:

- 0.2 mm layers or finer
- at least four perimeters
- at least five top/bottom layers
- approximately 35–50% infill
- matte-black bezel inner surfaces
- inspect all small M2 and M5 bosses closely for voids or delamination

## Verification specific to the optical window

Before aircraft use:

- verify purchased window thickness against the 2.25 mm seat depth
- confirm the 62.0 mm disc fits with no force
- verify bezel retains the window under vibration without distorting it
- verify there is no window/LCD contact
- test readability in direct cockpit sunlight
- check reflections from canopy, pilot clothing and side windows
- test realistic cleaning for scratching/hazing
- verify coatings do not craze after thermal cycling
- confirm bezel screws remain secure after vibration
- verify the window can be replaced without damaging the LCD

## Remaining internal mechanical work

The next enclosure revision should add positive retention for the ESP32-S3 board, Bosch BMI088 Shuttle Board on a rigid axis-defined carrier, TPS61169 backlight board, MCP23008 hardware, display/FFC arrangement, rotary encoder, USB-C strain relief and internal wiring/tie points.

No flight-development article should contain loose modules, unsupported connectors or Dupont wiring.

This remains a **supplementary/non-primary artificial horizon under flight development**, not the aircraft's primary attitude instrument.
