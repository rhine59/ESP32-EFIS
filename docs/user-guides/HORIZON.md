# Artificial Horizon / PFD panel — user guide

## Purpose
The Horizon panel is the primary page of this supplementary/non-primary multifunction instrument. A short PEC09 push cycles **Horizon/PFD → Altimeter → Compass → Horizon/PFD**.

## Presentation
The revised design takes its cues from modern compact round EFIS instruments while retaining a deliberately uncluttered attitude display. The centre remains the dominant blue-sky/brown-ground horizon with white pitch ladder and fixed yellow aircraft symbol. An upper roll arc and fixed yellow roll reference are added. Reserved data areas allow pressure altitude and heading/track only when their independent sources are valid.

A compact lower GNSS strip is now an **adopted requirement**. When GNSS is valid it shows WGS84 latitude/longitude, fix state and receiver-reported horizontal accuracy; satellites used may be shown where space permits. Latitude/longitude numbers and the accuracy indication are colour coded from the common project thresholds: green <=1 m, light green >1–3 m, yellow >3–10 m, orange >10–30 m and red >30 m. Invalid or stale GNSS is red and the last plausible coordinates must not remain displayed as current. See `../GNSS_DISPLAY.md`.

No unavailable value is fabricated merely to fill a box. Attitude, altitude, heading and GNSS each have independent validity.

## Controls
- **Short press:** next panel.
- **Long press (~0.8 s):** enter/leave Horizon settings.
- **Rotate in settings:** brightness, 5% per detent, 10–100%.
- **Short press in settings:** accept/leave settings without changing panel.

The selected brightness and last selected panel are persisted in ESP32 NVS. Actual TPS61169 PWM application remains a hardware bring-up task.

## PFD auxiliary data
Altitude is shown only from the validated static-pressure system. Heading is shown only from the validated magnetic/AHRS source. GNSS course over ground is labelled **TRK**, never HDG; GNSS groundspeed is **GS**, never IAS. GNSS position/accuracy does not substitute for attitude, barometric altitude or magnetic heading.

## Failure behaviour
Stale, unavailable or implausible attitude must invalidate the normal attitude presentation. A plausible frozen horizon is unacceptable. Optional PFD fields independently show invalid/unavailable rather than retaining stale values. GNSS loss affects the GNSS strip only and must not invalidate an otherwise valid horizon.

## Bench checks
Confirm screen cycling, long-press settings, persistence across power cycles, roll-scale geometry, independent field validity and obvious loss of BMI088/AHRS validity. GNSS tests must cover no fix, stale data and each accuracy-colour band while confirming that stale coordinates disappear.
