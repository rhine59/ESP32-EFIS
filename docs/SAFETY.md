# Safety and Airworthiness Notes

## Status of this project

This is an **experimental electronics project**, not a certified or approved primary flight instrument.

The device must not be relied upon as the sole source of attitude information in flight unless and until the complete system has been independently demonstrated, accepted and approved for that role under the rules applicable to the aircraft.

## Key hazards

Potential hazards include:

- incorrect attitude due to gyro bias or accelerometer misinterpretation
- misleading attitude during sustained acceleration or manoeuvring
- stale frozen display after sensor or software failure
- vibration-induced connector or mounting failure
- display washout in sunlight
- overheating in a closed cockpit
- power interruption or brownout
- software crashes or invalid arithmetic
- incorrect installation alignment
- EMI/RFI interaction with other avionics

## Design rules

The project should follow these principles:

1. **Fail visibly.** A bad or stale solution must show ATTITUDE INVALID.
2. **Never freeze a plausible horizon silently.**
3. **Log faults and reset causes where possible.**
4. **Keep the IMU mechanically rigid and its orientation documented.**
5. **Use secure wiring and strain relief for any aircraft-installed prototype.**
6. **Do not treat bench success as evidence of airborne reliability.**
7. **Use independent attitude references during testing.**
8. **Retain a clearly experimental/non-primary status until proven otherwise.**

## Power

The prototype is powered from a regulated 5 V USB-C source. The project currently excludes direct connection of raw aircraft 12 V to the instrument.

Any future direct-aircraft power design would need its own electrical-protection review, including transient, reverse-polarity, noise and overcurrent considerations.

## Enclosure material

PLA is not preferred for a sun-heated cockpit because of its relatively low heat resistance and creep risk. A more suitable engineering filament such as ASA or ABS should be evaluated, along with inserts/fasteners and real thermal testing.

## Flight testing

Airborne evaluation should only occur after bench, motion, vibration, thermal and aircraft-ground testing are satisfactory. During flight testing, the unit should remain a secondary experimental display and must be compared with an independent trusted reference.

## Change control

Hardware, firmware, calibration, filter tuning and enclosure changes can all affect attitude performance. Important changes should therefore be committed to source control and documented before flight evaluation.
