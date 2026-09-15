# Compass panel — user guide

## Purpose
The Compass page uses the familiar aircraft directional-gyro/HSI convention: aircraft symbol and top lubber line remain fixed while the compass card rotates beneath them. It is supplementary/non-primary.

## Presentation
The renderer uses a black rotating card, white 5-degree ticks, stronger major divisions, fixed yellow lubber triangle and fixed yellow aircraft symbol. A yellow heading bug belongs to the rotating card.

## Controls
- **Short press:** Horizon/PFD.
- **Long press (~0.8 s):** enter/leave HDG BUG setting.
- **Rotate:** heading bug 1 degree per detent through 000–359°.
- **Short press in settings:** accept/leave settings.

Heading bug and last panel are persisted in ESP32 NVS.

## Heading source
The reference magnetic sensor is now **PNI RM3100-CB**, mounted remotely from the instrument electronics on a rigid non-magnetic bracket. BMI088 gyro/accelerometer attitude is combined with calibrated three-axis magnetic field for tilt-compensated heading. Raw gyro yaw is not accepted as an absolute compass source.

The RM3100-CB installation requires hard-iron and soft-iron calibration, installation-axis alignment and magnetic-interference testing with aircraft electrical loads in multiple states. Until that pipeline is integrated and valid, the normal non-simulation build keeps heading invalid.

## Heading versus track
GNSS course over ground, if later provided, is labelled **TRK**, not HDG. Magnetic/true reference and variation handling must be explicit.

## Failure behaviour
Missing, stale, implausible or magnetically disturbed heading data invalidates the card rather than freezing the last plausible heading.

## Bench/aircraft checks
Verify card sense, 000/359 continuity, bug relationship, NVS persistence, tilt compensation, full calibration, source freshness and magnetic effects from display/backlight, radios, wiring and adjacent equipment. See `../SENSORS.md`.
