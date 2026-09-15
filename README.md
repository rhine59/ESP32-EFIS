# ESP32 EFIS

Experimental **supplementary/non-primary** multifunction electronic flight instrument for a non-certified aircraft, based on ESP32-S3 and a 2.1-inch round 480×480 high-brightness display.

> **Safety:** experimental development hardware/software. It is not a certified or approved primary flight instrument and must not be relied upon as the sole source of attitude, altitude or heading information.

## Current development status — 15 September 2026

The **software/emulator graphics stage is complete and accepted**. Artificial Horizon/PFD, Altimeter and Compass have each been exercised in deterministic Espressif QEMU sequences at the real 480×480 framebuffer geometry, visually reviewed and accepted. The native SwiftUI simulator is maintained as an interactive representation of the accepted firmware behaviour; QEMU remains authoritative for the ESP32 RGB565 renderer.

Physical hardware is **not currently available**, so all hardware-dependent build, flash, sensor commissioning, display, encoder, enclosure-fit and aircraft-integration activities are deliberately **PAUSED / NOT VALIDATED ON HARDWARE**. A successful ESP32-S3 hardware-configuration compile verifies build integrity only; it is not hardware validation.

**Artificial Horizon / PFD — ACCEPTED IN QEMU.** Accepted pitch and roll direction, ±10°/±20° pitch, ±30°/±60° bank, combined pitch/bank, 5°/10° pitch ladder hierarchy, fixed aircraft datum, fixed bank-angle scale, moving roll pointer, `ATT FAIL` and recovery.

**Altimeter — ACCEPTED IN QEMU.** Accepted classic three-pointer presentation, digital altitude, pressure/QNH calculation path, 9-o'clock progressive >10,000-ft hatch sector, compact curved 3-o'clock Kollsman scale with 1013.25 hPa datum, `ALT FAIL` and recovery. QNH remains 950–1050 hPa in integer 1 hPa increments.

**Compass — ACCEPTED IN QEMU.** Accepted rotating card, N/E/S/W references, three-digit heading, 000/359 wrap, continuous rotation, selected-heading bug geometry, `HEADING FAIL` and recovery.

**BMI088 software pipeline — IMPLEMENTED, COMPILE-VALIDATED, HARDWARE VALIDATION PENDING.** The SPI driver verifies both BMI088 sections, reads six-axis samples in engineering units and timestamps them. A complementary attitude estimator with plausibility and stale-data checks exists. A disabled-by-default commissioning diagnostic can log raw axes and acceleration magnitude. The sensor-to-aircraft axis/sign mapping is intentionally not assumed, and BMI088 output is not yet connected to the live Horizon.

**BMP585 and RM3100 live acquisition — PLANNED / HARDWARE PENDING.** The pressure-to-altitude calculation is implemented and simulation-tested, but the physical BMP585 acquisition path and RM3100 acquisition/calibration/tilt-compensated heading path remain to be implemented and validated with hardware.

See `docs/PROJECT_STATUS.md` for the complete activity/validation matrix and remaining work, `docs/SENSORS.md` for sensor functions, `docs/SIMULATION.md` for emulator acceptance, and `docs/TESTING.md` for the validation programme.

## Instrument pages

The EFIS has three round-instrument pages selected by the PEC09 rotary/push control:

1. **Horizon/PFD** — BMI088-based AHRS, pitch/roll, roll scale and validated auxiliary altitude/heading fields.
2. **Altimeter** — classic three-pointer presentation using the selected ported BMP585 static-pressure sensor and adjustable QNH.
3. **Compass** — rotating-card presentation using the selected remotely mounted PNI RM3100-CB absolute-heading source, fused with the AHRS as appropriate.

No missing sensor value is replaced by a plausible fallback. Invalid or stale data must be unmistakably invalid.

## Hardware baseline

- Espressif **ESP32-S3-WROOM-1-N16R2** — 16 MB Quad flash / 2 MB Quad PSRAM
- project-specific 68 mm carrier PCB, currently parked pending physical-interface decisions
- TI **TPS62162-Q1** 3.3 V regulator
- Bosch **BMI088 Shuttle Board 3.0** IMU
- **Adafruit ported BMP585 PID 6413** pressure board for the static-pressure development installation
- **PNI RM3100-CB** remotely mounted three-axis magnetometer
- Newhaven **NHD-2.1-480480AF-ASXP** 480×480 round IPS display
- Adafruit **TPS61169** backlight driver
- Microchip **MCP23008** GPIO expansion
- Bourns **PEC09-2320F-T0015** rotary encoder/push switch
- 5 V USB-C development power

See `BOM.md`, `docs/SENSORS.md`, `docs/HARDWARE.md` and `docs/WIRING.md` for authoritative detail. Procurement state does not imply physical validation.

## Firmware and development environment

`firmware/` is an **ESP-IDF v5.4.4** project named `esp32_efis`. It contains the physical display/control path, fail-obvious data validity, NVS-backed UI settings, explicit synthetic bench simulation, an Espressif QEMU virtual-display backend, BMI088 acquisition and the initial attitude estimator.

On macOS, the standard new-shell setup is:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
```

The current active development workflow while hardware is unavailable is QEMU:

```bash
zsh scripts/build-qemu.sh --clean
zsh scripts/run-qemu.sh
```

The physical build script remains in the repository for later commissioning, but routine hardware-build activity is paused until hardware is available. A compile alone must never be recorded as physical validation.

`scripts/efis-env.sh` pins the project to the known ESP-IDF v5.4.4 Python environment and also finds the Espressif QEMU installation when its bin directory is not exported automatically. Do not mix ESP-IDF Python environments within one build directory.

The QEMU configuration is isolated in `build-qemu` and `sdkconfig.qemu.defaults`. It enables synthetic data and the virtual 480×480 RGB565 display and disables physical external PSRAM because the emulator does not provide the N16R2's real Quad-PSRAM device in this configuration. Physical hardware builds retain the module's 2 MB PSRAM configuration through `sdkconfig.defaults`.

Bench/QEMU simulation is development-only. Every synthetic firmware screen carries a conspicuous red **SIM** marker. Never flash a QEMU build to aircraft hardware. See `docs/SIMULATION.md`, `docs/MACOS_BUILD_AND_QEMU_SETUP.md` and `firmware/README.md`.

## iPhone/iPad simulator

`simulator/` contains a native SwiftUI ESP32 EFIS simulator for rapid display development. It provides the three accepted pages, manual pitch/roll/altitude/heading controls, QNH and heading-bug controls, AUTO FLIGHT, independent sensor-failure injection and deterministic acceptance sequences. Synthetic data is explicitly identified and is not a flight-data source.

The Swift simulator must track accepted emulator presentation and scenario behaviour. See `simulator/README.md`.

## Display baseline

The Newhaven panel's **native and maximum display resolution is 480×480 pixels**. QEMU deliberately uses the same 480×480 framebuffer. The panel uses 16-bit RGB565 with 9-bit serial controller initialization. Current RGB timing is 30 MHz PCLK, HFP/HBP 50/50, HS pulse 4, VFP/VBP 50/50 and VS pulse 2. Two 480×480 RGB565 framebuffers require 921,600 bytes, fitting in the N16R2's 2 MB Quad PSRAM on physical hardware.

The desktop QEMU view is not a prediction of apparent physical sharpness when enlarged on a Mac display. Physical display quality remains unvalidated until the selected panel is available.

## Enclosure

The 3 1/8-inch flight-development enclosure retains the 80.30 mm panel-opening reference, 79.60 mm locating body, 88 mm square front flange, 62.9 mm panel-hole square, 58 mm target body depth, removable optical-window bezel, LCD carrier, rigid BMI088 carrier, 68 mm PCB rear mount, USB-C service opening and M5 insert provisions.

The multifunction revision adds rear service provisions for the static-pressure connection and remote magnetometer cable. Final hole/connector geometry remains intentionally pending until actual fittings and hardware can be validated. See `docs/ENCLOSURE.md`.

## Repository layout

```text
.
├── README.md
├── BOM.md
├── docs/
│   ├── PROJECT_STATUS.md
│   └── user-guides/
├── firmware/
├── scripts/
├── simulator/
├── hardware/
└── enclosure/
```

## Development principles

The BMI088 is to be rigidly mounted with physically verified aircraft-axis alignment. Gyros provide short-term attitude propagation while acceleration-sensitive corrections are confidence weighted. Pressure, heading and attitude sources have independent validity/freshness handling. GNSS track, if later introduced, is labelled **TRK**, not heading; groundspeed is **GS**, never IAS.

Until physical hardware becomes available, active work is limited to software, emulator, simulator, documentation, static analysis and tests that do not claim to validate real sensors, electrical interfaces, physical controls or display hardware.
