# Compass panel — user guide

## Purpose
The Compass page uses the familiar aircraft directional-gyro/HSI convention: aircraft symbol and top lubber line remain fixed while the compass card rotates beneath them. It is supplementary/non-primary.

## Presentation
The renderer uses a black rotating card, white 5-degree ticks, stronger major divisions, fixed yellow lubber triangle and fixed yellow aircraft symbol. A yellow heading bug belongs to the rotating card.

A compact lower GNSS strip is now an **adopted requirement**. When GNSS is valid it shows WGS84 latitude/longitude, fix state and receiver-reported horizontal accuracy; satellites used may be shown where space permits. Latitude/longitude numbers and the accuracy indication use the common project colour bands: green <=1 m, light green >1–3 m, yellow >3–10 m, orange >10–30 m and red >30 m. Invalid or stale GNSS is red and stale coordinates are removed/obscured rather than frozen. See `../GNSS_DISPLAY.md`.

## Controls
- **Short press:** Horizon/PFD.
- **Long press (~0.8 s):** enter/leave HDG BUG setting.
- **Rotate:** heading bug 1 degree per detent through 000–359°.
- **Short press in settings:** accept/leave settings.

Heading bug and last panel are persisted in ESP32 NVS.

## Heading source
The reference magnetic sensor is **PNI RM3100-CB**, mounted remotely from the instrument electronics on a rigid non-magnetic bracket. BMI088 gyro/accelerometer attitude is combined with calibrated three-axis magnetic field for tilt-compensated heading. Raw gyro yaw is not accepted as an absolute compass source.

The RM3100-CB installation requires hard-iron and soft-iron calibration, installation-axis alignment and magnetic-interference testing with aircraft electrical loads in multiple states. Until that pipeline is integrated and valid, the normal non-simulation build keeps heading invalid.

## Heading versus track
GNSS course over ground is labelled **TRK**, not HDG. Magnetic/true reference and variation handling must be explicit. GNSS ground speed is **GS**, never IAS. GPS position validity is independent of magnetic-heading validity: loss of one must not make the other appear valid or invalid without cause.

## Failure behaviour
Missing, stale, implausible or magnetically disturbed heading data invalidates the card rather than freezing the last plausible heading. Missing/stale GNSS removes the coordinates and shows an explicit red GPS invalid/stale indication; it does not invalidate a healthy magnetic compass.

## Bench/aircraft checks
Verify card sense, 000/359 continuity, bug relationship, NVS persistence, tilt compensation, full calibration, source freshness and magnetic effects from display/backlight, radios, wiring and adjacent equipment. GNSS tests cover no fix, stale data and all accuracy-colour bands. See `../SENSORS.md` and `../GNSS_DISPLAY.md`.
