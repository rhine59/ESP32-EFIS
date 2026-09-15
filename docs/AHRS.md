# AHRS / Attitude Solution

## Purpose and current status

The BMI088 provides raw angular-rate and specific-force measurements; it does not directly provide a trustworthy aircraft attitude. An initial attitude estimator is now implemented in `firmware/main/attitude_estimator.c` and compiles for the ESP32-S3 target. **It has not been physically validated and is deliberately not connected to the live Horizon until the Shuttle Board axis/sign mapping is demonstrated on hardware.**

Physical sensor work is currently paused because no prototype hardware is available.

## Implemented initial estimator

The present implementation is a deliberately simple **pitch/roll complementary estimator**, not the quaternion estimator described in the earlier design proposal. That distinction is important: documentation must describe the code that exists, while quaternion/Mahony/Madgwick/error-state approaches remain possible later evolutions after real BMI088 data are available.

Input is a `bmi088_sample_t` already expressed in aircraft body axes. Required body convention is:

- **+X forward**
- **+Y right**
- **+Z down**

Sensor-to-aircraft axis/sign transformation is intentionally outside the estimator and has not yet been frozen.

Outputs in `attitude_estimator_t` are pitch, roll, last-sample timestamp, initialization state and validity.

## Current calculation

On first usable sample, gravity-derived roll and pitch initialize the estimator. Subsequent samples propagate:

- roll from gyro X rate
- pitch from gyro Y rate

When acceleration magnitude is considered gravity-usable, the gyro-propagated result is corrected toward accelerometer-derived attitude with a complementary weight of **0.98 gyro / 0.02 accelerometer per update**.

Accelerometer attitude is calculated only when total acceleration magnitude lies between **0.70 g and 1.30 g**. Outside this range, gyro propagation can continue but the accelerometer is not blindly treated as gravity.

The present pitch validity limit is ±89° and roll ±180°. These are implementation guards, not claims about validated flight envelope.

## Timing and stale-data handling

The estimator rejects:

- null/non-finite samples
- initialization without a plausible gravity vector
- zero sample interval
- sample interval greater than **100 ms**
- non-finite output
- output beyond the current pitch/roll implementation limits

`attitude_estimator_check_stale()` marks an initialized attitude invalid when the latest sample is more than **250 ms** old. A failed/stale real source must ultimately result in `attitude_valid=false`; it must never leave a frozen plausible Horizon.

These thresholds are initial software values and require physical/dynamic validation before aircraft use.

## BMI088 acquisition layer

The current BMI088 SPI driver:

- uses separate accelerometer and gyroscope chip selects
- verifies accelerometer ID `0x1E` and gyro ID `0x0F`
- configures ±6 g accelerometer range
- configures ±500 °/s gyro range
- handles the accelerometer SPI dummy byte
- returns six engineering-unit values plus a monotonic millisecond timestamp

An optional `CONFIG_EFIS_BMI088_DIAGNOSTICS` commissioning mode logs acceleration X/Y/Z, acceleration magnitude and gyro X/Y/Z at approximately 5 Hz. It is OFF by default, unavailable in QEMU and never feeds the display.

## Physical installation gate — not yet passed

Before connecting BMI088 measurements to the Horizon:

1. connect the actual Shuttle Board to the ESP32-S3 prototype
2. verify both chip IDs and stable sample acquisition
3. establish which physical sensor axes/signs correspond to aircraft +X forward, +Y right, +Z down
4. confirm approximately 1 g stationary magnitude in known orientations
5. record stationary gyro bias/noise
6. verify positive/negative pitch and roll rate signs by deliberate hand/fixture rotation
7. encode the explicit sensor-to-body mapping
8. only then feed mapped samples into the estimator and `instrument_data_t`

This gate prevents an assumed PCB orientation from producing a convincing but reversed attitude indication.

## Validation still required

Static tests: level, ±10°/±20° pitch and ±30°/±60° roll against a physical reference.

Dynamic tests: smooth/abrupt rotations, latency, overshoot, drift after stopping and timing behaviour.

Acceleration rejection: translational acceleration without intended rotation.

Fault/stale tests: communication failure, delayed samples, invalid values and disconnect; indication must become conspicuously invalid.

Vibration/thermal tests: characterize gyro/accelerometer noise and estimator stability under representative conditions.

Only after these tests should estimator weighting or a more sophisticated quaternion/filter architecture be selected on evidence from real data.

## Future estimator evolution

Candidate later approaches remain quaternion complementary filtering, Mahony, Madgwick or an error-state/EKF approach if measurements justify the additional complexity. Gyro bias estimation, calibration storage, confidence weighting based on angular rate/vibration, and potentially other aiding sources remain future work.

Absolute heading is a separate fusion problem using the remote RM3100 plus validated attitude for tilt compensation. GNSS course over ground, if introduced, is **TRK**, not HDG.
