# Altimeter panel — user guide

## Purpose
The Altimeter page deliberately resembles a classic round aircraft altimeter: black face, high-contrast white circumference scale and three analogue hands. It remains supplementary/non-primary and does not replace the aircraft's required altimeter.

## Presentation
The renderer uses 50 circumference divisions with a long 100-ft hand, medium 1,000-ft hand and short 10,000-ft hand. A digital altitude readout supplements the analogue hands.

The accepted Kollsman presentation is a compact mechanical-style curved pressure scale at the **3 o'clock** position. The selected QNH sits beneath a fixed index while the surrounding pressure graduations move with the setting. The visible sector spans approximately **8 hPa total**. Pressure numbers and hatch marks remain at constant radii from the centre of the instrument; no `QNH`, `HPA` or `KOLLSMAN` unit text is shown in the window. The exact **1013.25 hPa** standard-pressure datum is identified by a substantially heavier tick. QNH selection itself remains integer hPa in 1 hPa steps.

Above 10,000 ft, a separate hatched annular sector appears at **9 o'clock**. It progressively reveals between 10,000 and 11,000 ft and remains fully exposed above 11,000 ft.

## Controls
- **Short press:** Compass.
- **Long press (~0.8 s):** enter/leave BARO/QNH setting.
- **Rotate:** QNH by 1 hPa per detent, currently 950–1050 hPa.
- **Short press in settings:** accept/leave settings.

QNH defaults to 1013 hPa on a fresh instrument and is stored in ESP32 NVS.

## Pressure source
The reference sensor is **Bosch BMP585**. First bench/static-plumbing development uses the **Adafruit BMP585 Ported breakout PID 6413**. The gel-filled BMP585 was chosen for environmental robustness while retaining low noise and good relative pressure accuracy. The BMI088 is never used to manufacture altitude.

Until the BMP585 driver and static plumbing are physically integrated and validated, normal non-simulation firmware keeps altitude invalid. Bench simulation is explicitly synthetic.

## Validity / failure
Altitude becomes valid only after pressure-sensor startup, range, freshness and plausibility checks pass. Missing, stale or invalid pressure immediately invalidates the indication rather than freezing the last plausible altitude.

## Bench checks
Compare against a trusted pressure reference over multiple pressures/altitudes; exercise hand wrap points; test QNH/NVS; rapid pressure changes; power cycles; static leaks/restrictions; disconnected/stale sensor conditions. See `../SENSORS.md`.
