# Flight-development enclosure

This document records the current 3D-printable enclosure design for the ESP32 supplementary multifunction flight instrument.

> The instrument is supplementary/non-primary. Geometry, materials, fasteners, vibration resistance, thermal performance, pressure plumbing and aircraft installation require physical verification.

## Front-panel geometry — unchanged

Adding Altimeter and Compass pages does **not** require a larger instrument face. The current design target remains:

- conventional 3 1/8-inch format
- 80.30 mm reference panel opening
- 79.60 mm cylindrical locating body
- 88 × 88 mm rounded front flange
- 58 mm body-depth target
- 62.9 × 62.9 mm four-hole panel pattern
- 4.4 mm front mounting holes
- 55 mm optical clear aperture
- Newhaven 2.1-inch round LCD
- PEC09 front rotary/push control

The front bezel, display carrier, optical window and encoder pod therefore remain valid for the multifunction concept.

## New rear/internal requirements

The additional functions change the **rear/internal interfaces**, not the face:

1. **Altimeter:** provide a protected route for static-pressure tubing or a bulkhead fitting to the pressure sensor. Avoid sharp tube bends, heat sources and loads on a PCB-mounted pressure port.
2. **Compass:** preferably mount the magnetometer remotely from the display electronics, power wiring, steel fasteners and aircraft magnetic sources. The enclosure therefore needs a locking cable connector/pass-through and strain relief rather than assuming the magnetometer belongs inside the instrument case.
3. **Carrier PCB:** reserve connector and clearance zones for the pressure and heading-source interfaces before PCB layout resumes.

No STL dimensional change is being frozen yet because the exact sensor packages, pneumatic fitting and connector families have not been selected. Changing the STL now would manufacture guesses. The parametric CAD must be updated immediately after those physical interfaces are frozen.

## Existing internal stack

Front to rear remains:

1. bezel and PEC09 control
2. 62 × 2 mm hard-coated AR optical window
3. Newhaven LCD
4. removable display carrier
5. rigid BMI088 cradle, permanently marked FWD/UP/lateral axis
6. 68 mm custom carrier PCB on 60 mm PCD rear standoffs
7. locking internal harnesses
8. removable rear cover
9. USB service opening and cable strain relief

The current custom PCB fit gauge remains useful because the nominal 68 mm PCB outline and mounting PCD have not changed.

## Planned rear-cover revision

When the pressure sensor and magnetometer connector are selected, the rear-cover SCAD/STL revision should add:

- configurable static-line entry/bulkhead location
- minimum bend-radius/clearance volume for the pressure tube
- remote-magnetometer cable connector opening
- cable-jacket strain relief
- labels for STATIC and HDG/MAG interfaces
- optional blanking features for bench builds

The 58 mm depth remains the target; increase it only if a physical interference check demonstrates a need.

## Existing optical/display/PCB details

- window: 62.0 mm diameter × 2.0 mm; 62.5 mm seat; 55.0 mm visible opening
- display carrier: 67 mm OD, 49 mm opening, 2.5 mm thick, 64 mm mounting PCD
- BMI088 cradle reference: 28 × 20 mm tray for 22 × 14 mm Shuttle Board
- custom PCB: 68 mm diameter, 1.6 mm starting thickness, 60 mm mounting PCD
- ESP32 antenna remains near 12 o'clock with required keepout
- USB-C remains near 6 o'clock with 13 × 7 mm service-slot target
- PCB fit gauge remains `enclosure/stl/ESP32_Artificial_Horizon_Custom_PCB_Fit_Gauge.stl`

## Current STL status

Existing generated targets remain current for the **front/display/IMU/PCB mechanical envelope**:

- `ESP32_Artificial_Horizon_Flight_Development_Body.stl`
- `ESP32_Artificial_Horizon_Flight_Development_Front_Bezel.stl`
- `ESP32_Artificial_Horizon_Flight_Development_Display_Carrier.stl`
- `ESP32_Artificial_Horizon_Flight_Development_IMU_Carrier.stl`
- `ESP32_Artificial_Horizon_Custom_PCB_Fit_Gauge.stl`
- `ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl`
- `ESP32_Artificial_Horizon_Flight_Development_USB_Strain_Relief_Clamp.stl`

**Rear cover is now revision-pending** for static and remote-heading interfaces. Do not print a final flight-development rear cover until those parts are frozen. A bench rear cover can still be printed.

## Verification before PCB/CAD freeze

In addition to the existing display/IMU/USB fit checks:

- select and measure the pressure sensor and its pneumatic port/fitting
- decide whether pressure sensor is PCB-mounted or remotely connected
- select the magnetometer and remote connector
- survey magnetometer mounting location for magnetic interference
- verify pressure tube cannot kink or rub
- verify new harnesses cannot load sensor connectors
- confirm 68 mm PCB still clears all connector bodies and bend radii
- update SCAD, regenerate STLs, then print a revised fit article before PCB fabrication

## Flight-development verification

Perform powered vibration and thermal testing, optical sunlight testing, static-system leak/response checks, heading-source interference/calibration checks, and explicit stale/failed-sensor tests. No loose modules, unsupported connectors or Dupont wiring should remain.
