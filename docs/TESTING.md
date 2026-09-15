# Testing Plan

## Principle

The ESP32 EFIS must be tested progressively. Convincing graphics, either in QEMU or on the bench, do not establish trustworthy airborne attitude, altitude or heading information. Invalid/stale sources must fail obviously rather than freeze a plausible indication.

## Stage 0 — Build and emulator regression

Before physical hardware is required, exercise the development configuration.

Start a clean shell with:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
```

Confirm the script reports ESP-IDF v5.4.4, the pinned ESP-IDF Python interpreter and a working `qemu-system-xtensa` when QEMU is installed.

For QEMU, always use a clean `build-qemu` after emulator configuration changes. Confirm `sdkconfig.qemu.defaults` enables QEMU and synthetic data but disables physical SPIRAM. The emulator must reach `app_main()` without an `esp_psram_init()` assertion, open the 480×480 virtual display, animate synthetic data, cycle all three pages and show the red **SIM** marker on every page.

Also build the normal hardware configuration separately and verify bench simulation remains OFF. Never reuse `build-qemu` for hardware deployment.

## Stage 1 — Electronics bench test

Verify stable 5 V USB-C power, repeated ESP32-S3 boot, physical 2 MB Quad-PSRAM operation, BMI088 identity/status, sensible accelerometer/gyro samples, reliable display initialization, rotary encoder operation and absence of brownouts at maximum display brightness.

## Stage 2 — Static orientation tests

Place the instrument at known attitudes and compare displayed pitch/roll with physical references. Test level, ±10° pitch, ±20° pitch, ±30° roll, ±60° roll and any larger-angle behaviour the final algorithm is intended to support. Record repeatability and hysteresis.

## Stage 3 — Dynamic hand/fixture tests

Move the unit through smooth and abrupt rotations while logging raw IMU and estimated attitude. Check latency, overshoot, drift after motion stops, quaternion normalisation, frame-rate stability and invalid-state behaviour during induced faults.

## Stage 4 — Acceleration-rejection tests

Translate the instrument without deliberately rotating it and observe whether linear acceleration creates false pitch/roll corrections. Accelerometers cannot distinguish gravity from all other specific forces, so acceleration-sensitive corrections must be confidence weighted.

## Stage 5 — Altitude/static-pressure tests

Once the ported BMP585 path is live, compare pressure and indicated altitude against traceable/reference pressure sources over representative QNH settings. Test pressure-port leakage/blockage, stale data and sensor disconnection. The altimeter must become conspicuously invalid rather than retain a plausible frozen altitude.

## Stage 6 — Heading tests

Once the remote PNI RM3100-CB path is live, test hard/soft-iron calibration, aircraft installation effects, cable routing, heading repeatability and turns through 000/359. Compare against an independent heading reference. GNSS track, if later displayed, must remain explicitly labelled TRK rather than being substituted for heading.

## Stage 7 — Vibration testing

Expose the instrument to representative vibration and compare raw gyro noise, raw accelerometer noise, estimated attitude noise, display readability and connector integrity. Include representative engine RPM ranges if this can be done safely while the aircraft is stationary.

## Stage 8 — Thermal and sunlight tests

Test the enclosure/display at elevated temperature and direct sunlight. Check high-nit readability, LCD colour/contrast, case distortion, ESP32 stability, IMU bias change, backlight thermal load and USB-C connector/cable behaviour.

## Stage 9 — Aircraft ground installation test

Before airborne evaluation, verify mechanical security, instrument/aircraft axis alignment, control/wiring clearance, electrical/magnetic interference, operation with engine off/running, static-pressure installation integrity and remote magnetometer behaviour. Compare with independent references where practical.

## Stage 10 — Airborne experimental comparison

Only after the preceding stages are satisfactory and only as a non-primary experimental display. Compare against independent trusted references and collect logs rather than relying on visual impressions alone. Include straight/level flight, normal turns, climbs/descents, acceleration/deceleration, turbulence and prolonged bank.

## Fault injection

Deliberately test disconnected/stale/corrupt BMI088 data, pressure-sensor failure, magnetometer failure, display task slowdown, processor restart, power interruption and invalid calibration data. Synthetic simulation must never activate automatically as a fallback for a failed real sensor.

The required response to a real-source failure is a conspicuous invalid indication, not synthetic substitution and not a frozen plausible value.
