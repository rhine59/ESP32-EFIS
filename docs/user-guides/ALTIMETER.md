# Altimeter panel — user guide

## Purpose
The Altimeter page deliberately resembles a classic round aircraft altimeter: black face, high-contrast white circumference scale and three analogue hands. It remains supplementary/non-primary and does not replace the aircraft's required altimeter.

## Presentation
The revised renderer uses 50 circumference divisions with stronger major divisions and three hands: a long **100-ft** hand, medium **1,000-ft** hand and short **10,000-ft** hand. A lower Kollsman/QNH setting window is reserved on the face. The electronic implementation may later add a small digital altitude confirmation without displacing the classic analogue presentation.

## Controls
- **Short press:** Compass.
- **Long press (~0.8 s):** enter/leave BARO/QNH setting.
- **Rotate:** change QNH by 1 hPa per detent, currently 950–1050 hPa.
- **Short press in settings:** accept/leave settings.

QNH defaults to 1013 hPa on a fresh instrument. QNH and the last selected panel are now stored in ESP32 NVS and restored after power cycling.

## Pressure source required
The current hardware specification still has no static/barometric pressure sensor. BMI088 cannot measure pressure. Consequently the altimeter remains explicitly invalid until a suitable pressure sensor and static installation are integrated.

The future pressure implementation must define sensor range, resolution, temperature compensation, filtering, startup validity, stale-data timeout and static-pressure plumbing. QNH must be applied to the measured static pressure rather than used to manufacture an altitude without pressure data.

## Failure behaviour
Missing, stale or invalid pressure data invalidates the indication. The instrument must never freeze the last plausible altitude.

## Bench checks
Compare against a trusted pressure reference over multiple pressures/altitudes, exercise all three hands through their wrap points, test QNH adjustment and NVS persistence, rapid pressure changes, power cycles and disconnected/stale pressure data.
