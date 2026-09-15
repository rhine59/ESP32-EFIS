# Artificial Horizon / PFD panel — user guide

## Purpose
The Horizon panel is the primary page of this supplementary/non-primary multifunction instrument. A short PEC09 push cycles **Horizon/PFD → Altimeter → Compass → Horizon/PFD**.

## Presentation
The revised design takes its cues from modern compact round EFIS instruments while retaining a deliberately uncluttered attitude display. The centre remains the dominant blue-sky/brown-ground horizon with white pitch ladder and fixed yellow aircraft symbol. An upper roll arc and fixed yellow roll reference are added. Reserved data areas allow pressure altitude on the right and heading/track at the top once those independent sources exist and are valid.

No unavailable value is fabricated merely to fill a box. The present bench firmware therefore makes attitude, altitude and heading validity obvious while their live sensor pipelines are unfinished.

## Controls
- **Short press:** next panel.
- **Long press (~0.8 s):** enter/leave Horizon settings.
- **Rotate in settings:** brightness, 5% per detent, 10–100%.
- **Short press in settings:** accept/leave settings without changing panel.

The selected brightness and last selected panel are now persisted in ESP32 NVS. Actual TPS61169 PWM application remains a hardware bring-up task.

## Future PFD data
The PFD may show altitude only from the validated static-pressure system and heading/track only from an explicitly identified validated source. GPS groundspeed, if later added, must be labelled **GS**, never IAS.

## Failure behaviour
Stale, unavailable or implausible attitude must invalidate the normal attitude presentation. A plausible frozen horizon is unacceptable. Optional PFD fields must independently show invalid/unavailable rather than retaining stale values.

## Bench checks
Confirm screen cycling, long-press settings, persistence across power cycles, roll-scale geometry, independent field validity and obvious loss of BMI088/AHRS validity.
