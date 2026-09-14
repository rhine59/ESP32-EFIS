# Testing Plan

## Principle

The artificial horizon must be tested progressively. Bench behaviour that looks convincing is not enough to establish trustworthy airborne attitude information.

## Stage 1 — Electronics bench test

Verify:

- stable 5 V USB-C power
- ESP32-S3 boots repeatedly
- BMI088 identity/status checks pass
- accelerometer and gyro samples are sensible
- display initialises reliably
- rotary encoder works
- no brownouts at maximum display brightness

## Stage 2 — Static orientation tests

Place the instrument at known attitudes and compare displayed pitch/roll with physical references.

Suggested checkpoints:

- level
- ±10° pitch
- ±20° pitch
- ±30° roll
- ±60° roll
- inverted/large-angle behaviour if the algorithm is intended to support it

Record repeatability and hysteresis.

## Stage 3 — Dynamic hand/fixture tests

Move the unit through smooth and abrupt rotations while logging raw IMU and estimated attitude.

Check:

- latency
- overshoot
- drift after motion stops
- quaternion normalisation
- frame-rate stability
- invalid-state behaviour during induced faults

## Stage 4 — Acceleration-rejection tests

Translate the instrument without deliberately rotating it and observe whether linear acceleration creates false pitch/roll corrections.

This is especially important because accelerometers cannot distinguish gravity from all other specific forces.

## Stage 5 — Vibration testing

Expose the instrument to representative vibration and compare:

- raw gyro noise
- raw accelerometer noise
- estimated attitude noise
- display readability
- connector integrity

The test should include representative engine RPM ranges if conducted safely on the aircraft while stationary.

## Stage 6 — Thermal and sunlight tests

Test the enclosure/display at elevated temperature and direct sunlight.

Check:

- high-nit display readability
- LCD colour/contrast
- case distortion
- ESP32 temperature stability
- IMU bias change
- backlight current/thermal load
- USB-C connector/cable behaviour

## Stage 7 — Aircraft ground installation test

Before any airborne evaluation:

- verify mechanical security
- verify instrument/aircraft axis alignment
- confirm full control movement does not contact wiring
- check for electrical interference
- check operation with engine off and engine running
- compare the instrument with independent attitude references where practical

## Stage 8 — Airborne experimental comparison

Only after the previous stages are satisfactory and only as a non-primary experimental display.

Compare against an independent, trusted attitude reference. Collect logs rather than relying on visual impressions alone.

Important manoeuvres for evaluation include:

- straight and level
- normal turns
- climbs/descents
- acceleration/deceleration
- turbulence
- prolonged bank

## Fault injection

The software should be deliberately tested for:

- disconnected BMI088
- stale SPI data
- corrupted values
- display task slowdown
- processor restart
- power interruption
- invalid calibration data

The expected response is a conspicuous invalid indication rather than a frozen plausible horizon.
