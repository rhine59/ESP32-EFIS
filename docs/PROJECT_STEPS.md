# ESP32 EFIS — Project Steps and Validation Gates

**Status date:** 16 September 2026

This document defines the ordered development path for the ESP32 EFIS. The instrument has **one physical Newhaven 2.1-inch 480×480 display** and three selectable pages: Horizon/PFD, Altimeter and Compass. The project remains experimental **supplementary/non-primary**.

The newly adopted GNSS requirement is part of the Horizon/PFD and Compass design: both pages will show latitude/longitude and position quality. The coordinate numbers are colour-coded from the GNSS receiver's reported horizontal-accuracy estimate. GNSS is independent of attitude, barometric altitude and magnetic heading; loss of one source must not falsely invalidate or validate another.

## Stage 0 — Software baseline and requirements

**Current state: active / substantially complete for existing instruments; GNSS display extension now active.**

Maintain the accepted 480×480 QEMU renderer, Swift simulator, safety/failure model, documentation and deterministic tests. Add the GNSS data model and shared accuracy classifier, then implement the position overlay on both Horizon/PFD and Compass.

GNSS display acceptance states must include valid positions at each accuracy band, stale data, no fix and invalid data. Thresholds are: ≤1 m green; >1–3 m light green; >3–10 m yellow; >10–30 m orange; >30 m red. Stale/no-fix must not leave believable frozen coordinates. `TRK` means GNSS course over ground; `GS` means GNSS groundspeed; neither may be presented as `HDG` or IAS.

**Gate to Stage 1:** requirements documented; QEMU/Swift scenarios defined; no software-only result described as physical validation.

## Stage 1 — Bench hardware and single-display bring-up

Inspect received parts. Establish current-limited bench power. Bring up the ESP32-S3-WROOM-1-N16R2, the **single** Newhaven display through NHD-FFC40/verified FFC, TPS61169 backlight, MCP23008 and PEC09. Verify RGB565 colour/order/timing, PSRAM framebuffer operation, brightness control and physical page selection.

**Gate to Stage 2:** stable power, single display and controls operate reliably on the bench; measured power/current recorded; obvious display/control failures understood.

## Stage 2 — Sensors and GNSS integration

Integrate BMI088, ported BMP585, remote-development RM3100 and a selected GNSS receiver. The GNSS receiver must provide latitude, longitude, fix state/freshness and an explicit horizontal-accuracy estimate; receiver/antenna hardware is not yet frozen.

Validate BMI088 axes/signs before connecting it to the live Horizon. Validate BMP585 pressure/altitude and stale/failure behaviour. Validate RM3100 acquisition, calibration approach and tilt-compensated heading. Validate GNSS update/freshness, accuracy classification and display on Horizon/PFD and Compass. Exercise simultaneous and independent failures so valid GNSS cannot make invalid attitude/heading appear valid and GNSS failure does not invalidate otherwise-valid attitude/heading.

**Gate to Stage 3:** all four source interfaces are stable enough that installation measurements are meaningful; GNSS display behaviour has passed QEMU/Swift acceptance and bench GNSS data tests; physical sensor results are explicitly recorded.

## Stage 3 — Aircraft survey and measurements

Survey the Skyranger without committing final installation hardware. Measure static-system tube OD/ID/material, tee location, run and panel clearance. Survey magnetically quiet RM3100 positions and routing. Survey GNSS receiver/antenna positions for sky view, cable/module routing and interference. Confirm enclosure/panel clearances and service access.

**Gate to Stage 4:** static, magnetometer and GNSS installation requirements are measured rather than guessed.

## Stage 4 — Physical interfaces and enclosure freeze

Use Stage 3 measurements to freeze the static fitting/plumbing, remote magnetometer harness/connector/gland, GNSS antenna/receiver interface and routing, optical window and enclosure openings. Conduct physical fit trials before irreversible geometry is treated as final.

**Gate to Stage 5:** external interfaces and mechanical constraints are sufficiently stable to commit connector positions and PCB geometry.

## Stage 5 — Custom carrier PCB

Resume the parked carrier PCB. Complete and review the KiCad schematic and recommended 4-layer layout around the validated display, controls, BMI088, BMP585, RM3100 and GNSS interfaces. Include power protection/decoupling appropriate to the validated bench design. Generate manufacturing files, BOM and placement data; order a small prototype batch only after review.

Populate/test one board first. Repeat display, sensor, GNSS, power, thermal, failure/staleness and interference tests before treating the board revision as suitable for installation development.

**Gate to Stage 6:** integrated carrier passes bench functional/electrical/thermal/fault tests, including GNSS reception/interference and RM3100 magnetic-interference checks.

## Stage 6 — Aircraft installation and ground validation

Freeze aircraft 12 V conversion/protection, fuse/circuit protection, wiring/connectors and mounting from measured prototype data. Install the instrument, static connection, remote RM3100 and GNSS receiver/antenna using the validated interfaces.

Perform aircraft-ground tests with radios, engine/electrical loads, display brightness and other relevant equipment in representative states. Confirm attitude sense, static altitude, heading/magnetic interference, GNSS position/freshness/accuracy indication, power stability, thermal behaviour and failure annunciation.

**Gate to Stage 7:** no unresolved ground-test issue that could create a plausible but incorrect flight indication.

## Stage 7 — Airborne comparison and refinement

Only after the preceding gates, perform cautious airborne comparison against independent trusted instruments/sources. Record discrepancies and environmental effects. Do not use the ESP32 EFIS as the sole source of attitude, altitude, heading or navigation information.

Any material change discovered here loops back to the relevant earlier stage; it does not bypass bench validation.

## Cross-stage rules

Every functional change updates code, relevant documentation, `PROJECT_STATUS.md` decision history where material, and this step plan when sequencing changes. Every validation claim identifies its layer: compile, QEMU, Swift, Docker runtime, electronics bench, physical fixture, aircraft ground or airborne.

No missing/stale source may leave a plausible frozen indication. Simulation is conspicuously marked and is never an automatic fallback. PCB and irreversible aircraft-interface decisions remain parked until their prerequisite measurements and bench validations are complete.

See `GNSS_DISPLAY.md`, `PROJECT_STATUS.md`, `TESTING.md`, `SENSORS.md`, `WIRING.md`, `ENCLOSURE.md`, `POWER_BUDGET.md` and `../BOM.md`.

## Added boot/maintenance workstream — 26 September 2026

- implement rotary-controlled boot menu with START EFIS (default), FULL TEST and FIRMWARE UPDATE;
- implement simulated electrical-test result model and documented failure codes before physical test claims;
- integrate physical component tests as each hardware interface is commissioned;
- implement boot-time Wi-Fi dialog and persistent NVS credentials;
- enable encrypted NVS for production Wi-Fi credentials;
- preserve a Start EFIS escape path for every network/update failure;
- keep activation explicit after download/verification and validate A/B first-boot rollback.
