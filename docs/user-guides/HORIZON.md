# Artificial Horizon panel — user guide

## Purpose
The Horizon panel is the attitude display of the supplementary/non-primary instrument. A short press of the Bourns PEC09 push switch cycles **Horizon → Altimeter → Compass → Horizon**.

## Display
The normal design uses blue sky, brown ground, a white horizon/pitch ladder and a fixed yellow aircraft symbol. Live pitch and roll will come from the BMI088-based quaternion AHRS.

The current firmware is still a bench-development build: BMI088 communication exists, but live attitude estimation is not yet connected to the renderer. The panel therefore overlays the invalid indication rather than pretending the static proof-of-life horizon is current aircraft attitude.

## Controls
- **Short press:** next panel.
- **Long press (~0.8 s):** enter/leave Horizon settings.
- **Rotate while settings are active:** adjust display brightness in 5% steps, constrained to 10–100%.
- **Short press while settings are active:** leave settings without changing panel.

Brightness is currently a UI setting only; hardware PWM application is the next backlight-control step.

## Planned live-data requirements
The Horizon panel becomes operational only after the firmware has live BMI088 XYZ acquisition, gyro-bias calibration, sensor-to-aircraft axis transformation, quaternion attitude estimation, acceleration rejection/confidence logic and freshness monitoring.

## Failure behaviour
Stale, unavailable or implausible attitude data must make the normal horizon unmistakably invalid. A plausible frozen attitude is not acceptable. This requirement applies even though the instrument is supplementary/non-primary.

## Bench checks
Confirm the encoder cycles panels, long press enters settings, rotation changes the setting, the display never presents the static test attitude as valid, and loss of BMI088 communication remains obvious.
