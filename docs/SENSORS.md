# Sensor architecture

This project is a supplementary/non-primary flight instrument. Sensor validity, freshness and installation effects must be explicit; missing data must never be replaced by plausible stale data.

## Attitude sensor — BMI088

**Bosch Sensortec BMI088** is the reference six-axis inertial source for pitch and roll. It combines independent 16-bit triaxial accelerometer and gyroscope sections and is specifically intended for vibration-heavy applications including drones and robotics.

The ESP32-S3 uses SPI with separate accelerometer and gyroscope chip selects. Firmware verifies both chip IDs before accepting the device, explicitly configures ±6 g acceleration and ±500 °/s gyro ranges, observes the accelerometer SPI dummy-byte behaviour, and waits for accelerometer startup before samples are accepted.

`bmi088_read_sample()` now supplies engineering-unit acceleration in g and angular rate in degrees/second plus a monotonic sample timestamp. `attitude_estimator` is a separate body-frame estimator: gyro integration supplies short-term motion while gravity-derived pitch/roll provides low-frequency correction through a complementary filter. Accelerometer correction is suppressed when total acceleration is outside 0.70–1.30 g so manoeuvre acceleration is not blindly interpreted as gravity.

The estimator is fail-obvious. It rejects non-finite samples, refuses initialization without a plausible gravity vector, invalidates an excessive sample interval, rejects impossible/non-finite attitude output and provides a 250 ms stale-data invalidation check. A failed or stale attitude must set `attitude_valid=false`; the renderer must never continue to show a frozen plausible attitude.

### Installation-axis gate

The estimator requires aircraft body axes **+X forward, +Y right, +Z down**. The Bosch shuttle-board axes have not yet been physically related to the final EFIS enclosure/aircraft installation. Therefore raw BMI088 samples are **not yet connected to the live `instrument_data_t` attitude fields**. Before that connection is enabled, the actual mounted shuttle board must be bench-tested in known nose-up, nose-down, left-bank and right-bank orientations and an explicit sensor-to-body axis/sign mapping recorded in firmware and this document. This deliberately prevents an unverified axis assumption from becoming a plausible but reversed flight indication.

The first hardware attitude acceptance sequence is: verify chip IDs and raw stationary values; establish axis/sign mapping; confirm approximately 1 g magnitude when stationary; characterize stationary gyro bias; exercise known ±10°/±20° pitch and ±30°/±60° roll positions; then enable the estimator-to-display path and verify stale/disconnect failure. Calibration and vibration testing follow before any aircraft evaluation.

### BMI088 commissioning diagnostic

A dedicated build option, `CONFIG_EFIS_BMI088_DIAGNOSTICS`, is available for bench axis commissioning. It is **OFF by default**, unavailable in the QEMU build, and does not connect BMI088 measurements to the instrument display. When enabled on hardware it logs approximately five samples per second in this form:

```text
BMI088 DIAG t=12345ms A[g] X=+0.001 Y=-0.006 Z=+1.002 |A|=1.002 G[dps] X=+0.08 Y=-0.03 Z=+0.11
```

Use the diagnostic with the Shuttle Board stationary and then rotate it deliberately through known orientations. Record which sensor acceleration axis carries approximately ±1 g for each orientation and which gyro axis/sign responds to each positive rotation. The required final mapping is aircraft **+X forward, +Y right, +Z down**. Do not enable the estimator-to-display path until that mapping has been physically demonstrated rather than inferred from connector or PCB orientation.

For a stationary board, `|A|` should be close to 1 g and gyro rates should remain near zero apart from bias/noise. Large stationary departures, unstable readings, SPI errors or implausible gyro output are commissioning failures to resolve before attitude work continues.

To enable the diagnostic temporarily:

```bash
cd ~/Documents/Xcode/ESP32-EFIS/firmware
idf.py menuconfig
```

Select **ESP32 EFIS development options → Enable BMI088 axis commissioning diagnostics**, save, then build/flash/monitor. Disable the option again after commissioning. The startup log explicitly states when diagnostics are enabled and that the diagnostic data are not feeding the display.

## Pressure sensor — frozen choice

**Bosch Sensortec BMP585** is the reference static-pressure sensor for the Altimeter/PFD.

Why BMP585 rather than BMP581/BMP390/DPS310:
- 300–1250 hPa full-accuracy range
- ±6 Pa typical relative accuracy and 0.08 Pa RMS pressure noise
- ±0.5 Pa/K typical temperature coefficient
- gel-filled cavity / enhanced resistance to water, dust and harsh environments
- I2C/I3C/SPI and 3.3 V-compatible supplies
- active component with strong UK stock
- same modern BMP58x family while giving this aircraft installation useful environmental robustness

Its maximum absolute accuracy is specified at ±50 Pa in Bosch's current data, so QNH/reference-pressure setting remains essential as with any barometric altimeter.

### Prototype module

Use **Adafruit BMP585 Ported I2C/SPI breakout, PID 6413** for bench and first flight-development plumbing. It provides a practical ported module and is available through DigiKey. This is preferable to inventing a pressure chamber around an unported bench breakout.

For a later custom carrier, decide after pressure tests whether to retain a separately mounted ported BMP585 module or integrate the bare BMP585 with a purpose-designed sealed plenum. Do not freeze the bare-sensor pneumatic geometry until the ported prototype has been characterized.

### Static plumbing

The enclosure provides a reinforced STATIC service boss with a 3 mm pilot hole. Enlarge it only for the final bulkhead/tube fitting after the Skyranger static tubing has been measured. Support tubing independently, leak-test it, avoid kinks/excessive volume, and prevent cabin pressure leaking into the static line.

Firmware applies pilot-selected QNH to measured static pressure. Startup, range, rate-of-change, temperature and stale-data checks must pass before `altitude_valid` becomes true.

## Magnetometer — frozen choice

**PNI RM3100-CB (P/N 14754)** is the reference absolute magnetic-field source.

Reasons: three-axis magneto-inductive architecture; ±1100 µT range; 13 nT sensitivity / ~15 nT noise at the documented high-resolution setting; I2C/SPI; -40 to +85 °C; compact 14.22 × 15.75 × 7.14 mm board; documented rugged/vibration performance; UK supply through Solsta.

The RM3100-CB is remote-mounted away from the ESP32, DC/DC converter, backlight current, steel fasteners and other panel magnetic disturbances. It needs a rigid non-magnetic mount with known FWD/UP/lateral axes and a locking strain-relieved cable through the rear MAG service boss.

## Heading fusion

The compass does not use raw magnetometer azimuth alone. Heading is produced from calibrated 3-axis magnetic field plus BMI088 attitude, including tilt compensation, hard-iron offset, soft-iron matrix and installation alignment. Magnetic/true reference and variation handling must be explicit. GNSS course over ground is **TRK**, not HDG.

## Bench development

Until sensors are physically connected and their installation mappings are verified, bench simulation supplies clearly synthetic values. Simulation must be disabled for aircraft-use firmware.
