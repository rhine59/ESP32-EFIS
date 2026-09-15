# Altimeter panel — user guide

## Purpose
The Altimeter panel is designed to reproduce the quick visual interpretation of a classic round aircraft altimeter on the 480×480 display. It is a supplementary/non-primary indication and is not a replacement for the aircraft's required altimeter.

## Controls
- **Short press:** next panel (Compass).
- **Long press (~0.8 s):** enter/leave Altimeter settings.
- **Rotate while settings are active:** change QNH one hPa per detent.
- QNH is constrained to **950–1050 hPa** in the current UI.
- **Short press while settings are active:** leave settings without changing panel.

The initial default is 1013 hPa. Persistence to NVS is deliberately deferred until the sensor/data architecture is complete.

## Display concept
The renderer provides a classic dark circular dial with a white scale and separate altitude hands. A QNH setting area is reserved in the lower part of the dial. The final version should include clearly readable altitude numerals and QNH digits sized for the 2.1-inch display.

## Pressure sensor required
**The present hardware specification does not contain a barometric pressure sensor.** The BMI088 measures acceleration and angular rate; it cannot provide barometric altitude. Therefore the current Altimeter panel is intentionally invalid and does not invent an altitude.

Before this panel can display live altitude, the hardware needs a suitable static-pressure/barometric sensor and a defined pneumatic/static installation. Sensor selection should consider range, resolution, temperature behaviour, long-term drift, update rate and aircraft static-pressure plumbing.

## Altitude calculation
When a pressure source is added, firmware will convert measured static pressure to pressure altitude and apply the pilot-selected QNH for indicated altitude. The implementation must define units, filtering, startup validity, pressure-sensor diagnostics and stale-data limits.

## Failure behaviour
Missing, stale or invalid pressure data must invalidate the dial rather than leave the last plausible altitude displayed.

## Bench checks
Before aircraft installation, compare the electronic indication against a trusted pressure reference over multiple pressures/altitudes, exercise the full QNH range, test rapid pressure changes, power cycles and deliberately disconnected/stale sensor conditions.
