# AHRS / Attitude Solution

## Purpose

The BMI088 provides raw angular-rate and specific-force measurements. It does **not** directly provide a trustworthy aircraft attitude solution. The ESP32-S3 therefore runs the attitude estimator.

## Initial estimator architecture

The first implementation should be quaternion based.

Inputs:

- gyro X/Y/Z
- accelerometer X/Y/Z
- calibration parameters
- sensor-to-aircraft alignment transform

Outputs:

- quaternion attitude state
- roll
- pitch
- health/confidence flags

## Update rates

Suggested initial targets:

- IMU acquisition: 200–500 Hz
- attitude propagation: same rate as gyro acquisition
- accelerometer correction: lower effective bandwidth than gyro propagation
- display update: 30–60 Hz

These values are starting points and must be validated experimentally.

## Gyroscope role

The gyro is the primary short-term attitude source. Angular rates are integrated into the quaternion state.

Advantages:

- fast response
- unaffected directly by linear acceleration

Limitation:

- bias causes attitude drift over time

## Accelerometer role

The accelerometer provides long-term reference information only when the measured specific-force vector is sufficiently close to the expected gravity magnitude and dynamics are benign enough for it to be informative.

A simple aircraft acceleration can make the measured vector differ from gravity, so the filter must **not** blindly force the estimated vertical to follow every accelerometer sample.

## Confidence weighting

The estimator should reduce accelerometer correction when any of the following are observed:

- magnitude differs significantly from approximately 1 g
- rapid changes in acceleration
- high angular rates
- turbulence / vibration indicators
- implausible disagreement with the propagated gyro attitude

## Candidate algorithms

Early development can compare:

- quaternion complementary filter
- Mahony-style filter
- Madgwick-style filter
- error-state / extended Kalman filtering later if justified

The project should prefer understandable, testable behaviour over algorithmic complexity for its own sake.

## Yaw

The first instrument requirement is pitch and roll. The BMI088 does not include a magnetometer, so absolute heading is not a primary objective for the initial version.

Yaw still exists internally in the quaternion propagation, but long-term absolute yaw reference is not required to render an artificial horizon.

## Startup

On startup the system should:

1. initialise the BMI088 and verify identity/status
2. estimate gyro zero-rate bias while stationary
3. estimate an initial gravity direction from accelerometer data
4. initialise the quaternion
5. mark attitude invalid until minimum stability/initialisation criteria are satisfied
6. transition explicitly to valid attitude mode

## Health monitoring

The estimator should continuously track:

- sensor communication failures
- stale sample age
- gyro saturation
- accelerometer saturation
- NaN/infinite calculations
- quaternion normalisation errors
- unreasonable attitude jumps
- time-step anomalies

Any serious condition should make the displayed attitude invalid.

## Future aiding

GNSS velocity and potentially pitot/static information may later be investigated as aiding sources. These are not required for the first bench prototype.
