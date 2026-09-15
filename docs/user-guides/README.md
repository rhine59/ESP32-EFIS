# Instrument user guides

The instrument UI is deliberately documented **one panel per user-guide file** so each display can evolve independently while retaining common control behaviour.

## Panel guides

- [Artificial Horizon](HORIZON.md)
- [Altimeter](ALTIMETER.md)
- [Compass](COMPASS.md)

## Common PEC09 control model

The Bourns `PEC09-2320F-T0015` is the single front-panel control.

- **Short press:** cycle to the next screen.
- **Long press (~0.8 seconds):** enter or leave settings for the current screen.
- **Rotate:** changes the current screen's setting only while settings are active.
- **Short press in settings:** exits settings and stays on the same screen.

Current setting assignments are Horizon = brightness, Altimeter = QNH, Compass = heading bug.

The current firmware intentionally marks all three flight-data presentations invalid until their live data sources are implemented. No panel is allowed to fabricate a plausible value merely to make the UI look complete.
