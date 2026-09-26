# ESP32 EFIS

Experimental **supplementary/non-primary** multifunction electronic flight instrument for a non-certified aircraft, based on ESP32-S3 and a single 2.1-inch round 480×480 high-brightness display.

> **Safety:** experimental development hardware/software. It is not a certified or approved primary flight instrument and must not be relied upon as the sole source of attitude, altitude, heading or position information.

## Current development status — 16 September 2026

The software/emulator graphics baseline for Artificial Horizon/PFD, Altimeter and Compass has been accepted in deterministic Espressif QEMU at the real 480×480 framebuffer geometry. Physical hardware validation remains pending; compile or simulation results are not physical validation.

A new **adopted display requirement** adds GNSS position and receiver-reported horizontal accuracy to both the Horizon/PFD and Compass pages. The shared instrument data model and GNSS accuracy classifier are now present in firmware; final 480×480 renderer integration, GNSS receiver selection/acquisition, QEMU acceptance and hardware validation remain pending. See `docs/GNSS_DISPLAY.md`.

GNSS accuracy colour bands are: green <=1 m, light green >1–3 m, yellow >3–10 m, orange >10–30 m, red >30 m; no fix/stale/invalid is red with coordinates removed or obscured. These are project UI categories based on the receiver's horizontal accuracy estimate, not guaranteed error bounds or certification/integrity limits.

**Artificial Horizon / PFD — EXISTING BASELINE ACCEPTED IN QEMU; GNSS OVERLAY PENDING ACCEPTANCE.** Accepted attitude behavior remains unchanged. The new lower GNSS strip must not obscure the primary attitude presentation and has independent validity.

**Altimeter — ACCEPTED IN QEMU.** Existing classic three-pointer, digital altitude, QNH/Kollsman and failure behavior are unchanged.

**Compass — EXISTING BASELINE ACCEPTED IN QEMU; GNSS OVERLAY PENDING ACCEPTANCE.** Magnetic heading remains independent of GNSS. GNSS course is `TRK`, never `HDG`.

**BMI088 software pipeline — IMPLEMENTED, COMPILE-VALIDATED, HARDWARE VALIDATION PENDING.** Sensor-to-aircraft axis/sign mapping remains intentionally gated on physical commissioning.

**BMP585 and RM3100 live acquisition — PLANNED / HARDWARE PENDING.** Pressure-to-altitude calculation exists; physical acquisition and magnetic calibration/tilt-compensated heading remain hardware work.

**GNSS acquisition — REQUIREMENT ADOPTED / RECEIVER NOT YET FROZEN.** The project requires a source that provides valid fix state, WGS84 latitude/longitude and an explicit horizontal accuracy estimate. Satellite count alone must not drive the accuracy colour.

See `docs/PROJECT_STATUS.md`, `docs/GNSS_DISPLAY.md`, `docs/SENSORS.md`, `docs/SIMULATION.md` and `docs/TESTING.md`.

## Instrument pages

The EFIS has three pages on **one physical round display**, selected by the PEC09 rotary/push control:

1. **Horizon/PFD** — BMI088-based AHRS, pitch/roll and validated auxiliary fields, plus GNSS latitude/longitude and colour-coded position accuracy when valid.
2. **Altimeter** — classic three-pointer presentation using the selected ported BMP585 static-pressure sensor and adjustable QNH.
3. **Compass** — rotating-card presentation using the remotely mounted PNI RM3100-CB absolute-heading source, plus GNSS latitude/longitude and colour-coded position accuracy when valid.

No missing sensor value is replaced by a plausible fallback. Invalid or stale data must be unmistakably invalid.

## Hardware baseline

- Espressif **ESP32-S3-WROOM-1-N16R2** — 16 MB Quad flash / 2 MB Quad PSRAM
- project-specific 68 mm carrier PCB, parked pending physical-interface decisions
- TI **TPS62162-Q1** 3.3 V regulator
- Bosch **BMI088 Shuttle Board 3.0** IMU
- **Adafruit ported BMP585 PID 6413** pressure board
- **PNI RM3100-CB** remotely mounted three-axis magnetometer
- **GNSS receiver/interface: to be selected**; must provide explicit fix validity and horizontal accuracy estimate
- one Newhaven **NHD-2.1-480480AF-ASXP** 480×480 round IPS display
- Adafruit **TPS61169** backlight driver
- Microchip **MCP23008** GPIO expansion
- Bourns **PEC09-2320F-T0015** rotary encoder/push switch
- 5 V USB-C development power

See `BOM.md`, `docs/SENSORS.md`, `docs/HARDWARE.md` and `docs/WIRING.md` for authoritative detail. Procurement state does not imply physical validation.

## Firmware and development environment

`firmware/` is an **ESP-IDF v5.4.4** project named `esp32_efis`. It contains the physical display/control path, fail-obvious data validity, NVS-backed UI settings, explicit synthetic bench simulation, QEMU display backend, BMI088 acquisition, the initial attitude estimator and the shared GNSS accuracy-quality classifier.

The GNSS classifier deliberately centralizes the adopted bands so Horizon and Compass cannot silently use different thresholds. The instrument data model carries latitude, longitude, horizontal accuracy, satellites used, fix type, valid and stale states. Receiver parsing/acquisition and final on-screen drawing remain separate pending implementation tasks.

On macOS:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
zsh scripts/build-qemu.sh --clean
zsh scripts/run-qemu.sh
```

Physical hardware builds remain paused until hardware is available. A compile alone must never be recorded as physical validation.

## Simulator and acceptance

`simulator/` contains the SwiftUI development simulator. QEMU remains authoritative for ESP32 RGB565 rendering. Both simulators must be extended with deterministic GNSS cases covering no fix, stale data and every accuracy colour band before the new overlay can be marked accepted. Synthetic coordinates must remain unmistakably simulation data.

## Display baseline

There is **one** Newhaven 2.1-inch 480×480 display. Horizon/PFD, Altimeter and Compass are pages on that same display; they are not separate physical instruments. The panel uses RGB565 and 9-bit serial controller initialization with the existing 30 MHz RGB timing baseline.

GNSS information is deliberately a compact secondary strip. It must not compromise readability of attitude or heading, and real-panel legibility must be checked before the layout is frozen.

## Enclosure

The 3 1/8-inch flight-development enclosure is for the single round display and integrated electronics. Physical fitting and final aircraft interfaces remain pending actual hardware/measurements. See `docs/ENCLOSURE.md`.

## Development principles

The BMI088 is rigidly mounted with physically verified aircraft-axis alignment. Pressure, heading, attitude and GNSS have independent validity/freshness handling. GNSS `TRK` is never magnetic `HDG`; `GS` is never IAS. Receiver-reported accuracy is an estimate, not a guarantee, and poor/stale/no-fix position must fail visibly rather than freezing plausible coordinates.

## Boot, maintenance and diagnostics — 26 September 2026

The production interaction model now starts with a **rotary/push-controlled boot menu**. `START EFIS` is the default selection; `FULL TEST` launches the electrical/component diagnostic harness; `FIRMWARE UPDATE` enters the maintenance networking/OTA workflow. Rotation changes selection and a short press selects. Long-press Back/Cancel remains subject to physical encoder validation.

Firmware update first opens an explicit Wi-Fi connection dialog. Saved SSID/credentials persist in ESP-IDF NVS; production units require encrypted NVS for credentials and provide **Forget network**. Wi-Fi failure never blocks startup of the known-good EFIS. See `docs/OTA_USER_SCENARIO.md`, `docs/PHONE_NETWORK_AND_PUBLIC_OTA.md` and `docs/ELECTRICAL_TEST_HARNESS.md`.


### Persistent fault history

Detected software and hardware faults during normal operation are an adopted persistent-diagnostics requirement. A bounded, flash-wear-conscious non-volatile fault log will survive power cycles and be accessible through **FAULT LOG** on the rotary boot menu. It records stable fault identifiers and useful non-secret diagnostic context while immediate on-screen fail-obvious indications remain authoritative during operation. See `docs/ELECTRICAL_TEST_HARNESS.md` and `docs/PROJECT_STATUS.md`.
