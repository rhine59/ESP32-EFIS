# Testing Plan

## Principle

The ESP32 EFIS must be tested progressively. Convincing graphics, either in QEMU or on the bench, do not establish trustworthy airborne attitude, altitude or heading information. Invalid/stale sources must fail obviously rather than freeze a plausible indication.

**Current gate — 15 September 2026:** no physical prototype hardware is available. Hardware-dependent testing is therefore **PAUSED**. Stages 1–10 below remain the required validation programme, not completed work. A successful ESP32-S3 compile is recorded only as compile validation.

## Stage 0 — Build, emulator and simulator regression — CURRENT SOFTWARE STAGE

The 480×480 graphics/presentation passes for Artificial Horizon, Altimeter and Compass have been completed and accepted in QEMU. Their accepted states and failure/recovery sequences are recorded in `SIMULATION.md` and `PROJECT_STATUS.md`. The native Swift simulator is maintained in step for interactive testing.

Start a clean shell with:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
```

Confirm the script reports ESP-IDF v5.4.4, the pinned ESP-IDF Python interpreter and a working `qemu-system-xtensa` when QEMU is installed.

For QEMU, use a clean `build-qemu` after emulator configuration changes. Confirm `sdkconfig.qemu.defaults` enables QEMU and synthetic data but disables physical SPIRAM. The emulator must reach `app_main()`, open the 480×480 virtual display and show the red **SIM** marker.

Regression requirements remain: attitude, altitude and heading invalid states must fail obviously wherever each source is presented; recovery must restore only valid synthetic data; 000/359 heading wrap must remain continuous; >10,000-ft hatching and the compact Kollsman scale must retain their accepted geometry.

While hardware is unavailable, routine hardware builds/flashing are paused. If a hardware-target compile is performed specifically to check source compatibility, record it as **COMPILE-VALIDATED only** and do not infer physical PSRAM, SPI, LCD, encoder or sensor operation.

## Stage 1 — Electronics bench test — PAUSED / PENDING HARDWARE

Verify stable 5 V USB-C power, repeated ESP32-S3 boot, physical 2 MB Quad-PSRAM operation, BMI088 identity/status, sensible accelerometer/gyro samples, reliable display initialization, rotary encoder operation and absence of brownouts at maximum display brightness.

Use the disabled-by-default BMI088 commissioning diagnostic to establish physical sensor axes/signs. Do not connect BMI088 data to the live Horizon before that mapping is demonstrated.

## Stage 2 — Static orientation tests — PENDING HARDWARE

Place the instrument at known attitudes and compare displayed pitch/roll with physical references. Test level, ±10° pitch, ±20° pitch, ±30° roll and ±60° roll. Record repeatability, hysteresis and indication direction.

## Stage 3 — Dynamic hand/fixture tests — PENDING HARDWARE

Move the unit through smooth and abrupt rotations while logging raw IMU and estimated attitude. Check latency, overshoot, drift after motion stops, estimator stability, frame-rate stability and invalid-state behaviour during induced faults.

## Stage 4 — Acceleration-rejection tests — PENDING HARDWARE

Translate the instrument without deliberately rotating it and observe whether linear acceleration creates false pitch/roll corrections. Accelerometers cannot distinguish gravity from all other specific forces, so acceleration-sensitive corrections must remain confidence weighted.

## Stage 5 — Altitude/static-pressure tests — PENDING HARDWARE

Implement and commission the ported BMP585 acquisition path, then compare pressure and indicated altitude against traceable/reference pressure sources over representative QNH settings. Test pressure-port leakage/blockage, stale data and sensor disconnection. The altimeter must become conspicuously invalid rather than retain a plausible frozen altitude.

## Stage 6 — Heading tests — PENDING HARDWARE

Implement and commission the remote PNI RM3100-CB path. Test hard/soft-iron calibration, aircraft installation effects, cable routing, heading repeatability, tilt compensation and turns through 000/359. Compare against an independent heading reference. GNSS track, if later displayed, must remain explicitly labelled TRK rather than being substituted for heading.

## Stage 7 — Vibration testing — PENDING HARDWARE

Expose the instrument to representative vibration and compare raw gyro noise, raw accelerometer noise, estimated attitude noise, display readability and connector integrity. Include representative engine RPM ranges if this can be done safely while the aircraft is stationary.

## Stage 8 — Thermal and sunlight tests — PENDING HARDWARE

Test the enclosure/display at elevated temperature and direct sunlight. Check high-nit readability, LCD colour/contrast, case distortion, ESP32 stability, IMU bias change, backlight thermal load and USB-C connector/cable behaviour.

## Stage 9 — Aircraft ground installation test — PENDING HARDWARE

Before airborne evaluation, verify mechanical security, instrument/aircraft axis alignment, control/wiring clearance, electrical/magnetic interference, operation with engine off/running, static-pressure installation integrity and remote magnetometer behaviour. Compare with independent references where practical.

## Stage 10 — Airborne experimental comparison — FUTURE / BLOCKED

Only after the preceding stages are satisfactory and only as a non-primary experimental display. Compare against independent trusted references and collect logs rather than relying on visual impressions alone. Include straight/level flight, normal turns, climbs/descents, acceleration/deceleration, turbulence and prolonged bank.

## Fault injection

Deliberately test disconnected/stale/corrupt BMI088 data, pressure-sensor failure, magnetometer failure, display task slowdown, processor restart, power interruption and invalid calibration data. Synthetic simulation must never activate automatically as a fallback for a failed real sensor.

The required response to a real-source failure is a conspicuous invalid indication, not synthetic substitution and not a frozen plausible value.

## Bootable full electrical test harness — 26 September 2026

A rotary-selectable **FULL TEST** boot option is now an adopted requirement. It runs deterministic electrical/component checks and reports PASS / FAIL / NOT TESTED plus stable documented `ECCC-NN` failure codes. Tests continue after non-dangerous failures to collect a complete fault list. Optional/unfitted hardware must not be reported as failed. Display/backlight tests include a human visual check.

Implementation/validation proceeds from simulated PASS/FAIL cases through Phase-1 hardware, BMI088/BMP585, RM3100/GNSS and eventual production power/serial-interface tests. Each implemented test requires both a known-good PASS and an injected or realistic FAIL case. See `ELECTRICAL_TEST_HARNESS.md` for the code registry and staged implementation plan.
