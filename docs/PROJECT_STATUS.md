# ESP32 EFIS — Project activity and validation status

**Status date:** 15 September 2026

This document is the project-level record of what has been implemented, what has actually been validated, and what remains. It deliberately distinguishes **implemented**, **compile-validated**, **QEMU/simulator-validated**, and **physically validated**. A successful build is not evidence that a sensor, display, control, electrical interface or mechanical installation works on hardware.

The project remains an experimental **supplementary/non-primary** flight instrument. Missing, invalid or stale real data must fail obviously; synthetic data must never become an automatic fallback.

## Current development gate

**Physical hardware activities are PAUSED because no physical prototype hardware is currently available.** Do not schedule routine hardware builds, flashing, sensor commissioning, display bring-up, encoder testing, enclosure fit checks or aircraft integration until hardware is available. Software may continue to compile for the ESP32-S3 target where useful, but the result is recorded only as **compile validation**.

Active work while paused: QEMU regression, Swift simulator parity, documentation, pure calculation/estimator tests, code review and safety/failure-path development that does not depend on claiming physical behaviour.

## Validation vocabulary

| Status | Meaning |
|---|---|
| **ACCEPTED — QEMU** | Deterministic firmware/emulator behaviour has been visually/functionally reviewed and accepted at 480×480. |
| **SYNCED — SWIFT** | Native Swift simulator represents the accepted emulator behaviour for interactive testing; it is not the authoritative pixel renderer. |
| **COMPILE-VALIDATED** | ESP32-S3 firmware configuration compiled successfully. No physical operation is implied. |
| **IMPLEMENTED — UNVALIDATED** | Code/design exists but the required validation has not yet been performed. |
| **PLANNED / PENDING HARDWARE** | Work requires physical hardware or installation and is deliberately deferred. |
| **PARKED** | Design/work intentionally held until prerequisites are available. |

## Completed activities and validation

| Function / activity | Work completed | Validation status |
|---|---|---|
| Project safety model | Supplementary/non-primary role; explicit simulation marking; no plausible fallback for invalid real sources | **DOCUMENTED / DESIGN RULE** |
| ESP-IDF environment | ESP-IDF v5.4.4 environment script; separate hardware and QEMU build directories/configuration | **USED / QEMU VALIDATED** |
| QEMU display backend | Espressif virtual RGB display at native 480×480 RGB565; physical PSRAM disabled only in QEMU config | **ACCEPTED — QEMU** |
| Synthetic scenario engine | Deterministic attitude, altitude, heading, failure and recovery scenarios | **ACCEPTED — QEMU** |
| Artificial Horizon geometry | Pitch/roll direction, pitch ladder, fixed aircraft symbol, bank scale and roll pointer | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Horizon validity | `ATT FAIL` and explicit recovery | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Altimeter presentation | Three pointers, 0–9 scale, digital altitude | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| >10,000-ft warning | 9-o'clock 60° annular hatching, progressive 10,000→11,000 ft then full | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Kollsman presentation | Compact 3-o'clock curved scale, ~8 hPa total visible span, fixed selected-QNH index, 1013.25 datum, no units/labels | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| QNH UI/storage | 950–1050 hPa integer range, 1 hPa increments, NVS-backed UI setting | **SOFTWARE IMPLEMENTED; QEMU/UI BEHAVIOUR ACCEPTED; PHYSICAL ENCODER PENDING** |
| Pressure-to-altitude calculation | Reusable ISA pressure/QNH calculation with input validation | **IMPLEMENTED / SIMULATION-TESTED; REAL BMP585 INPUT PENDING** |
| Altimeter validity | `ALT FAIL` and recovery | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Compass presentation | Rotating card, N/E/S/W, 3-digit heading, conventional rotation | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Heading wrap/rotation | 000/359 crossing and continuous rotation | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Heading bug | Selected magnetic heading displayed at `bug - heading`; 060° held during acceptance sequence | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Compass validity | `HEADING FAIL` and recovery | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| BMI088 SPI driver | Separate accel/gyro CS, chip-ID checks, ±6 g and ±500 dps ranges, six-axis engineering-unit reads, timestamp | **IMPLEMENTED; COMPILE-VALIDATED; PENDING HARDWARE** |
| BMI088 commissioning diagnostics | Optional ~5 Hz X/Y/Z accel, magnitude and X/Y/Z gyro logging; disabled by default; never feeds display | **IMPLEMENTED; COMPILE-VALIDATED; PENDING HARDWARE** |
| Attitude estimator | Gyro propagation plus gravity correction, acceleration plausibility gate, timing/non-finite rejection, 250 ms stale invalidation | **IMPLEMENTED; COMPILE-VALIDATED; PHYSICAL AXIS/DYNAMIC VALIDATION PENDING** |
| BMI088-to-display safety gate | Live attitude connection intentionally withheld until physical axis/sign mapping is demonstrated | **IMPLEMENTED SAFETY GATE** |
| Swift simulator | Adaptive iPhone/iPad layout, manual controls, AUTO FLIGHT, failures, accepted instrument artwork | **SOFTWARE OPERATIONAL; PARITY MAINTAINED** |
| Enclosure CAD | Flight-development case, bezel, display carrier, IMU carrier, rear cover, strain relief and fit gauge | **DESIGNED / CI-CHECKED WHERE APPLICABLE; PHYSICAL FIT PENDING** |
| Carrier PCB | Architecture/pin allocation and design work | **PARKED pending physical-interface decisions** |
| BOM/procurement record | Selected core components and ordered-part tracking | **DOCUMENTED; receipt/bench validation separate** |

## Accepted emulator sequences

### Artificial Horizon

Level; pitch +10°, -10°, +20°, -20°; left/right bank 30° and 60°; combined +10° pitch/right 30° bank; attitude failure; recovery. Accepted graphics include 6.8 px/degree pitch scaling, 5°/10° ladder hierarchy, fixed aircraft datum and fixed bank scale.

### Altimeter

0, 500, 1,000, 2,500, 5,000, 9,500, 9,900, 10,000, 10,100, 10,500 and 12,500 ft; moving sweep; altitude failure; recovery. QNH pressure calculation was separately exercised with fixed simulated pressure and QNH changes. Final 9-o'clock hatching and compact 3-o'clock Kollsman geometry were visually accepted.

### Compass

000°, 045°, 090°, 135°, 180°, 225°, 270°, 315°; moving 350°→010° crossing; continuous rotation; heading failure; recovery to north. Heading bug held at 060° for deterministic geometry checking.

## Remaining work and required validation

| Priority / function | Work still required | Required validation | Current status |
|---|---|---|---|
| Swift parity regression | Keep all three native simulator pages/scenarios aligned with accepted firmware/QEMU behaviour | Compare Swift states with QEMU acceptance states after renderer changes | **ACTIVE SOFTWARE TASK** |
| BMI088 axis mapping | Determine Shuttle Board axes/signs relative to aircraft +X forward, +Y right, +Z down | Stationary ±1 g orientations plus positive pitch/roll/yaw hand rotations | **PENDING HARDWARE** |
| BMI088 gyro bias | Characterise stationary bias/noise and startup stability | Logged stationary datasets at representative temperatures | **PENDING HARDWARE** |
| Attitude estimator tuning | Tune complementary correction and potentially evolve algorithm after real data | Known static angles, dynamic fixture motion, acceleration rejection, vibration | **PENDING HARDWARE** |
| Live attitude connection | Map validated body-frame samples into estimator and `instrument_data_t` | Direction checks, stale/disconnect injection, comparison to independent reference | **BLOCKED BY AXIS VALIDATION** |
| BMP585 driver | Implement physical acquisition, startup/configuration, pressure/temperature samples and timestamps | Chip identity/status, reference pressure comparison, range/stale/disconnect tests | **PLANNED / PENDING HARDWARE** |
| Static system | Final pressure fitting/tube arrangement | Leak/blockage testing and aircraft static comparison | **PENDING HARDWARE** |
| Live altitude pipeline | Feed validated BMP585 pressure through QNH calculation into `altitude_ft` | Reference pressure/altitude points over QNH range plus failure tests | **PENDING HARDWARE** |
| RM3100 driver | Implement remote magnetometer acquisition and freshness/error handling | Identity/communication, field-vector plausibility, cable robustness | **PLANNED / PENDING HARDWARE** |
| Magnetometer calibration | Hard-iron offset, soft-iron matrix, installation alignment | Multi-orientation calibration dataset and residual-error analysis | **PENDING HARDWARE** |
| Tilt-compensated heading | Fuse calibrated magnetic vector with validated attitude | Known headings at level and bank/pitch, north-wrap and failure tests | **PENDING HARDWARE** |
| Magnetic reference | Freeze magnetic/true variation policy and user presentation | Documentation and comparison to independent reference | **OPEN DESIGN ITEM** |
| MCP23008/PEC09 | Validate panel selection, QNH and heading-bug control, detents/direction/push behaviour | Physical interaction and persistence tests | **PENDING HARDWARE** |
| NVS persistence on target | Confirm settings survive power cycles and corruption handling is safe | Repeated hardware restart/power interruption | **PENDING HARDWARE** |
| Newhaven LCD | Validate ST7701S init, RGB timing, colour order, brightness and double buffering | Physical panel bring-up and long-run display test | **PENDING HARDWARE** |
| Backlight | Validate TPS61169 drive, brightness, current and thermal behaviour | Electrical/thermal measurement | **PENDING HARDWARE** |
| ESP32-S3 PSRAM | Validate real N16R2 2 MB PSRAM with two framebuffers | Hardware boot/stress test | **PENDING HARDWARE** |
| Power integrity | Validate 5 V input, 3.3 V rail, brownout margin and display/backlight transients | Bench electrical measurements | **PENDING HARDWARE** |
| Enclosure fit | Print/assemble development enclosure and carriers | Physical dimensional/clearance/strain-relief check | **PENDING HARDWARE** |
| EMI/magnetic installation | Establish RM3100 location and interference from ESP32, regulator, display/backlight and aircraft | Powered ground tests with engine/equipment states | **PENDING HARDWARE** |
| Vibration | Characterise sensor/display/connector behaviour over representative vibration | Ground vibration/engine-RPM tests with logging | **PENDING HARDWARE** |
| Thermal/sunlight | Validate display readability and sensor/electronics stability | Elevated temperature/direct sunlight tests | **PENDING HARDWARE** |
| Aircraft ground integration | Wiring, static line, axes, magnetic effects, engine-running operation | Independent references and recorded ground test | **PENDING HARDWARE** |
| Airborne comparison | Experimental non-primary evaluation only after ground gates pass | Logged comparison against independent trusted instruments | **FUTURE / BLOCKED** |
| Carrier PCB | Resume/freeze connector placement and manufacture only after prototype interfaces are proven | Electrical review, PCB validation, assembled-board bench test | **PARKED** |

## Hardware-resumption gate

When physical parts become available, resume in this order: inventory/visual inspection → ESP32/display/power bench bring-up → BMI088 diagnostic axis mapping → estimator static/dynamic validation → BMP585 acquisition/static plumbing → MCP23008/encoder → RM3100 remote acquisition/calibration → integrated failure/staleness tests → enclosure/thermal/vibration → aircraft ground testing. Do not skip directly from successful compilation or emulator graphics to airborne use.

## Documentation rule

Every functional change must update the relevant code documentation and project status in the same development stage. Any statement of validation must name the validation layer: compile, QEMU, Swift simulator, electronics bench, physical fixture, aircraft ground or airborne comparison. This prevents emulator success from being mistaken for hardware or flight validation.
