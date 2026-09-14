# Calibration

## Goals

Calibration must address both sensor errors and mechanical alignment.

## Gyroscope calibration

At minimum:

1. hold the instrument completely stationary
2. collect several seconds of gyro data
3. calculate zero-rate bias for X/Y/Z
4. store the offsets
5. repeat at different temperatures during development to assess drift

The startup sequence may perform a fresh stationary bias estimate, but it must not silently assume the aircraft is stationary if motion is detected.

## Accelerometer calibration

A six-position static calibration should be implemented:

- +X up
- -X up
- +Y up
- -Y up
- +Z up
- -Z up

This can be used to estimate bias and scale errors for each axis.

## Axis alignment

The breakout-board axes may not match the desired aircraft axes. The firmware must define and document an explicit transform between:

- sensor axes
- instrument enclosure axes
- aircraft axes

The target aircraft convention should be documented before flight testing, e.g. longitudinal, lateral and vertical directions and positive rotations.

## Panel installation offset

Even a correctly printed enclosure may not sit perfectly level in the aircraft panel. A deliberate installation-alignment routine may therefore be useful.

Any user zero/cage feature must be carefully designed so it cannot mask a serious mounting or sensor fault.

## Vibration checks

Calibration on a quiet bench is not sufficient. The system should later be tested with representative engine/airframe vibration while stationary to determine:

- gyro noise increase
- accelerometer vibration spectrum
- filter sensitivity
- mechanical resonances

## Stored calibration

Calibration values should be stored in ESP32 non-volatile storage with:

- version number
- timestamp or sequence counter if useful
- checksum/validation
- sane-range checks on load

Corrupt or implausible calibration data should force a safe fallback or recalibration request.
