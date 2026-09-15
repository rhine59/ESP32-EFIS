# Compass panel — user guide

## Purpose
The Compass page uses the familiar aircraft directional-gyro/HSI convention: the aircraft and top lubber line remain fixed while the compass card rotates beneath them. It is a supplementary/non-primary display.

## Presentation
The revised renderer uses a black round card, white 5-degree ticks, stronger major divisions, fixed yellow top lubber triangle and fixed yellow aircraft symbol. When a valid heading is available, the entire scale rotates opposite aircraft heading so the current heading is always read at 12 o'clock. A yellow heading bug is positioned on the rotating card.

## Controls
- **Short press:** Horizon/PFD.
- **Long press (~0.8 s):** enter/leave HDG BUG setting.
- **Rotate:** move the heading bug 1 degree per detent through 000–359°.
- **Short press in settings:** accept/leave settings.

Heading bug and last selected panel are stored in ESP32 NVS and restored after power cycling.

## Heading source required
BMI088 alone cannot provide stable absolute heading. Gyro yaw drifts and the accelerometer cannot determine magnetic north, so the current page remains explicitly invalid until an absolute source is chosen.

Candidate architecture includes a properly installed/calibrated three-axis magnetometer, or GNSS track presented explicitly as **TRK** rather than heading. Panel-mounted magnetometers require careful aircraft magnetic-interference testing.

## Heading versus track
GNSS course over ground must never silently masquerade as magnetic heading. If GNSS track is later displayed, it is labelled TRK. Magnetic/true reference and variation handling must be explicit in the final design.

## Failure behaviour
Missing, stale or invalid heading data invalidates the card rather than freezing the last plausible heading.

## Bench/aircraft checks
Verify clockwise/counter-clockwise card sense, 000/359 continuity, heading-bug relationship to the rotating card, NVS persistence, source freshness, invalid-state behaviour and magnetic installation effects.
