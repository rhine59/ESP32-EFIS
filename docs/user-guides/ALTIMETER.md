# Altimeter panel — user guide

## Purpose
The Altimeter page deliberately resembles a classic round aircraft altimeter: black face, high-contrast white circumference scale and three analogue hands. It remains supplementary/non-primary and does not replace the aircraft's required altimeter.

## Presentation
The renderer uses 50 circumference divisions with a long 100-ft hand, medium 1,000-ft hand and short 10,000-ft hand. A lower Kollsman/QNH setting area is provided.

## Controls
- **Short press:** Compass.
- **Long press (~0.8 s):** enter/leave BARO/QNH setting.
- **Rotate:** QNH by 1 hPa per detent, currently 950–1050 hPa.
- **Short press in settings:** accept/leave settings.

QNH defaults to 1013 hPa on a fresh instrument and is stored in ESP32 NVS.

## Pressure source
The reference sensor is now **Bosch BMP581**. Bench development uses an Adafruit BMP581 breakout; the final carrier is intended to use the bare sensor connected to the aircraft static system through a sealed pressure plenum and rear STATIC fitting. The BMI088 is not used to manufacture altitude.

Until the BMP581 driver and plumbing are physically integrated and validated, the normal non-simulation build keeps altitude invalid. Bench simulation may exercise the graphics but is explicitly synthetic.

## Validity / failure
Altitude becomes valid only after pressure-sensor startup, range, freshness and plausibility checks pass. Missing, stale or invalid pressure immediately invalidates the indication rather than freezing the last plausible altitude.

## Bench checks
Compare against a trusted pressure reference over multiple pressures/altitudes; exercise all hand wrap points; test QNH and NVS; test rapid pressure changes, power cycles, static leaks/restrictions and disconnected/stale sensor conditions. See `../SENSORS.md`.
