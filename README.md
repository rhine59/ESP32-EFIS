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

Project checkpoints are recorded chronologically in [`CHANGELOG.md`](CHANGELOG.md). Every future checkpoint must update that change history; GitHub `main` remains the authoritative source of truth.

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


### Product licensing

The production architecture now reserves a signed, offline-verifiable product-licence mechanism. Licences are generated by an authorised off-device tool, installed through maintenance provisioning and verified on the EFIS using a public key; the private signing key is never stored on the instrument. The rotary boot menu will expose **LICENSE** status/install/reset functions. Licence state persists across normal firmware updates, while reset is deliberate, logged and separate from Wi-Fi/factory reset. Licensing of optional functions must never compromise fail-obvious instrument behaviour.


### Licence account service architecture — 26 September 2026

**ADOPTED / DESIGN STAGED.** Add a separate Docker service (working name `efis-account`) alongside OTA/admin services. It owns customer accounts, registered EFIS devices, licence entitlements and payment-provider linkage; it does not hold the licence-signing private key in the public web tier.

Device identity uses a provisioned immutable **EFIS Device ID / serial number** as the primary key. The ESP32 factory/eFuse base MAC may be recorded as a secondary hardware fingerprint and registration aid, but MAC address alone is not the licence identity because interface MACs can be derived/changed and MAC exposure is unnecessary for manual licensing.

Online boot-maintenance flow: LICENSE -> Connect Wi-Fi -> identify device -> authenticated account/licence endpoint -> fetch signed licence entitlement -> verify locally -> store in protected NVS -> continue offline. The EFIS must not send a user password; device authentication uses a provisioned device credential/challenge mechanism to be specified. Normal flight startup must not depend on account/payment/network availability.

Offline flow: show Device ID and short registration code/QR-capable text; user obtains a signed licence from the account portal on another device and enters/imports it manually or via USB service. The licence is verified locally with the embedded public verification key.

Payment integration is provider-adapter based. The account service creates checkout/customer-management requests and consumes verified payment webhooks; payment card data is handled by the payment provider, not stored by EFIS services. Payment status changes entitlements; a separate private signing worker/service generates signed licence payloads. Define explicit grace/revocation policy before subscriptions are enabled.

Suggested containers: `efis-account` API/web portal; PostgreSQL account/device/entitlement store; private `efis-license-signer` with tightly restricted signing-key access; existing `efis-ota` and `efis-ota-admin`. Payment provider secrets live only in server-side secret storage.



## Pressure scope — 26 September 2026

ASI/IAS capability has been removed from scope. The BMP585 uses the aircraft **STATIC** pressure connection for altitude/barometric pressure. The EFIS has no PITOT input or differential-pressure airspeed sensor.


## Product identity — 2 October 2026

The adopted development brand is **Lollipop Design**. The EFIS/flight-display product is **RedOne** and the engine-interface product is **BlueOne**. Customer-facing references should therefore use **Lollipop Design RedOne** and **Lollipop Design BlueOne**.

Engineering acronyms and stable implementation identifiers remain valid where they describe technical roles: RedOne is the EFIS; BlueOne is the sensor multiplexer (SMUX/SMUX in existing architecture material). Repository, protocol, Device ID, Docker, OTA and cryptographic identifiers are not automatically renamed by this branding decision. See `docs/BRANDING.md`.

## Customer support chatbot — 27 September 2026

A Dockerized **Lollipop Design RedOne Support** service is staged under `support-service/`. It retrieves approved product documentation, records customer interactions/feedback and builds a candidate Q&A queue. Customer conversations never become authoritative automatically: a human reviewer must validate candidates against current product documents before they enter the validated Q&A database. See `docs/SUPPORT_SERVICE.md` and `support-service/README.md`.


## Server platform — 29 September 2026

The proposed server-side infrastructure baseline is a **£750-class, 64 GB RAM / 1 TB NVMe virtualisation host** running Proxmox VE, with separate production Docker, development/test and monitoring VMs plus an optional k3s lab. Existing Docker Compose services should migrate first without requiring Kubernetes; k3s is a deliberate later evaluation path. This platform supports OTA, accounts/licensing, Lollipop Design RedOne Support and related services and is **not part of the flight hardware baseline**. See `docs/SERVER_PLATFORM.md`.


## AEF-CAN aircraft data bus — 30 September 2026

**ADOPTED / PROTOCOL STAGED.** The project now defines **AEF-CAN (Aircraft Experimental Flight CAN)** as the extensible internal data bus for the proposed Lollipop Design BlueOne sensor multiplexer (SMUX/SMUX), Lollipop Design RedOne display and future aircraft modules. It is deliberately hardware-independent and describes aircraft measurements and validity rather than display presentation.

V1 uses 500 kbit/s Classical CAN with 11-bit identifiers. The current ESP32-S3 TWAI controller requires an external CAN transceiver and is Classical-CAN-only; future CAN FD hardware can be added without redefining the application-level measurement semantics.

The protocol reserves functional CAN-ID ranges for engine, electrical, air data, GNSS/navigation, attitude, fuel, aircraft state, alerts, configuration, diagnostics and logging. It defines canonical wire units, scaled integer encoding, explicit freshness/fault semantics, node discovery/capabilities and major/minor compatibility rules. Producers publish facts; consumers own display units, thresholds and colours.

`protocol/aef-can.yaml` is the machine-readable source of truth. The long-form rationale and implementation/testing rules are in `docs/CAN-PROTOCOL.md`. Future C/C++, Swift and Python codecs/test vectors should be generated or verified from the YAML to prevent firmware/simulator/documentation drift.

The AEF-CAN/SMUX system remains **secondary, supplementary and non-certified**. No CAN value may remain silently presented as live after its freshness timeout.

### Licence negative-test correction — 5 October 2026

The Synology licence harness now distinguishes cryptographic integrity from device binding. Tampered-payload and bad-signature candidates exercise Ed25519 rejection; the wrong-device case uses a correctly signed simulator-only licence for a different immutable Device ID and must be rejected by the explicit Device-ID check while the installed valid licence remains unchanged. `scripts/rebuild-synology.sh` uses direct Docker access and no longer requires interactive `sudo`.

### Licensing simulator checkpoint — 5 October 2026

The Synology licence regression harness now passes the complete current simulator contract: signed acquisition, offline persistence, cryptographic and Device-ID rejection, no-entitlement handling, interrupted replacement recovery, Licence Reset, offline acquisition refusal, corrupt persistent-store detection and signed recovery. Startup discards an orphan temporary candidate after an interrupted replacement and retains the previously committed valid licence.

This closes the Docker/simulator licensing stage. Physical ESP32 protected-NVS, real power-loss atomicity and secure factory provisioning remain separate hardware validation gates.


## Documentation index

This is the canonical index to the maintained project documentation. Each link is relative so it works directly in GitHub and in a local clone. Documentation supplied inside third-party `firmware/managed_components` dependencies is intentionally excluded.

### Project control, planning and procurement

- [Bill of Materials and purchasing checklist](BOM.md) — Prototype BOM, quantities, sourcing, prices and acquisition/receipt status.
- [Change history](CHANGELOG.md) — Chronological implementation and documentation checkpoints; `main` is the authoritative project history.
- [Project status and decision record](docs/PROJECT_STATUS.md) — Current implementation/validation state plus adopted, proposed, parked, superseded and rejected design decisions.
- [Project steps and validation gates](docs/PROJECT_STEPS.md) — Ordered development stages, dependencies and evidence required before progressing.
- [Parts selection and sourcing](docs/PARTS_SELECTION.md) — Reference component choices and purchasing sources for the prototype hardware.
- [Procurement status checkpoint](docs/PROCUREMENT_STATUS_2026-09-16.md) — Evidence-based snapshot of delivered and in-transit prototype parts.
- [Parts cost model](docs/COST_MODEL.md) — Estimated repeatable production parts cost separated from development equipment and spares.
- [Branding](docs/BRANDING.md) — Development product-family naming and branding status.
- [Complete project manual PDF](docs/generated/MicroSky-Horizon-Complete-Project-Manual.pdf) — Generated indexed PDF compilation of project documentation for offline/reference use.

### System, hardware and mechanical design

- [Hardware design](docs/HARDWARE.md) — Processor, display, sensors, interfaces and reference hardware architecture.
- [Wiring plan](docs/WIRING.md) — Prototype electrical architecture and frozen ESP32-S3 GPIO/signal allocation.
- [Display design](docs/DISPLAY.md) — Newhaven round-display selection, geometry and display implementation requirements.
- [Sensor architecture](docs/SENSORS.md) — Attitude, pressure, magnetic and related sensor roles, validity and freshness rules.
- [AHRS / attitude solution](docs/AHRS.md) — BMI088 attitude-estimation implementation, limitations and physical-validation gate.
- [GNSS display](docs/GNSS_DISPLAY.md) — Position, accuracy, fix-state and presentation requirements for Horizon and Compass pages.
- [Calibration](docs/CALIBRATION.md) — Sensor-error and mechanical-alignment calibration requirements.
- [Power budget](docs/POWER_BUDGET.md) — Preliminary current/power estimates and later measurement requirements.
- [Enclosure](docs/ENCLOSURE.md) — Flight-development enclosure geometry, controls and mechanical packaging.
- [Mechanical, materials and thermal standard](docs/MECHANICAL_MATERIALS_AND_THERMAL.md) — RedOne/SMUX materials, captive fasteners and thermal-management decisions.
- [Carrier PCB requirements](hardware/pcb/README.md) — Revision-A custom carrier physical/layout requirements and board role.
- [Carrier PCB schematic definition](hardware/schematics/CARRIER_PCB_SCHEMATIC.md) — Authoritative electrical definition for the first custom ESP32-S3 carrier.
- [KiCad Carrier PCB Revision A](hardware/kicad/carrier_rev_a/README.md) — KiCad project scope, board construction and principal components.
- [Electrical POST and test harness](docs/ELECTRICAL_TEST_HARNESS.md) — Boot-selectable component/interface self-test requirements and failure reporting.
- [Design suggestion image register](docs/design-suggestions/README.md) — Non-authoritative visual inspiration register and rules for adopting ideas into the design.
- [Project images](docs/images/README.md) — Register of regenerable architecture, roadmap and other documentation graphics.

### Firmware, CAN, SMUX and deployment

- [Firmware overview](firmware/README.md) — ESP-IDF target, multi-panel firmware structure and principal firmware capabilities.
- [Firmware deployment](firmware/DEPLOYMENT.md) — macOS build, flash and monitor procedure for the ESP32-S3 hardware.
- [macOS build and QEMU setup](docs/MACOS_BUILD_AND_QEMU_SETUP.md) — Authoritative Apple-Silicon development environment, ESP-IDF and QEMU runbook.
- [AEF-CAN protocol](docs/CAN-PROTOCOL.md) — Adopted aircraft experimental CAN architecture and frozen V1 core wire contract.
- [Stage 7 SMUX integration](docs/STAGE-7-SMUX.md) — Provisional Sensor Multiplexer/engine-monitoring expansion and EFIS integration boundary.
- [Safety and airworthiness](docs/SAFETY.md) — Experimental supplementary-instrument status, limitations and safety principles.
- [Testing plan](docs/TESTING.md) — Progressive validation programme from software through bench/hardware/aircraft testing.

### Simulation and demonstration

- [Simulation architecture](docs/SIMULATION.md) — Bench/QEMU simulation policy, synthetic-data annunciation and accepted graphics state.
- [QEMU video demonstration](docs/DEMONSTRATION.md) — Procedure and scope for recording the actual firmware renderer running under QEMU.
- [EFIS simulator](simulator/README.md) — Swift simulator purpose, operation and relationship to the ESP32 renderer.
- [Web simulator](efis-web-simulator/README.md) — Docker browser emulator for boot/maintenance, OTA and licensing workflows without physical hardware.

### OTA and remote updates

- [Remote firmware updates](docs/REMOTE_UPDATES.md) — OTA architecture, rollback/fallback policy and ESP32 flash/update design.
- [OTA image administration](docs/OTA_IMAGE_ADMIN.md) — Definitive Upload → Publish → Download → Activate administration workflow.
- [OTA user scenario](docs/OTA_USER_SCENARIO.md) — User-facing OTA interaction model and separation of publication from activation.
- [Physical OTA test node](docs/OTA_PHYSICAL_TEST_NODE.md) — Minimal ESP32-S3 fixture for exercising OTA independently of full EFIS hardware.
- [Phone networking and public OTA](docs/PHONE_NETWORK_AND_PUBLIC_OTA.md) — Phone pairing, Wi-Fi/network path and public Synology OTA-access design.
- [OTA server](ota-server/README.md) — Containerised OTA server implementation, manifest/image hosting and administration interface.

### Licensing, accounts and customer/service apps

- [Product licensing specification](docs/LICENSING.md) — Authoritative entitlement model, trust boundaries and offline licensing rules.
- [Licensing architecture and flows](docs/LICENSING_ARCHITECTURE_AND_FLOWS.md) — End-to-end actors, trust boundaries and lifecycle/recovery use cases.
- [Process workflow architecture](docs/PROCESS_WORKFLOW_ARCHITECTURE.md) — Process-oriented EFIS Service UX/state-machine design and Advanced diagnostic boundary.
- [Device registration](docs/DEVICE_REGISTRATION.md) — Initial ownership claiming, permanent Device ID and account-association design.
- [Customer accounts and mobile apps](docs/CUSTOMER_ACCOUNT_AND_APPS.md) — Shared web/iOS/Android account, registration, payment and entitlement architecture.
- [Production licence service](docs/PRODUCTION-LICENCE-SERVICE.md) — Synology-hosted production direction, zero-configuration network contract and production-readiness gates.
- [RedOne licence network architecture and disaster recovery](docs/REDONE-LICENCE-NETWORK-ARCHITECTURE.md) — Public-first/local-fallback routing, mDNS, pinned TLS, trust boundaries, rebuild, backup and recovery procedure.
- [EFIS Service iPhone app](ios/EFISService/README.md) — SwiftUI service/licensing app responsibilities and security boundary.
- [Customer mobile apps](customer-app/README.md) — Shared role and security model for the native customer companion applications.
- [Customer iOS app](customer-app/ios/EFISCustomer/README.md) — SwiftUI customer-app skeleton, secure storage and planned account/payment integration.
- [Customer Android app](customer-app/android/README.md) — Kotlin/Compose customer-app skeleton, Keystore and planned account/payment integration.
- [Account service](account-service/README.md) — Prototype account, EFIS registration and entitlement service plus its security boundary.
- [Licence service development harness](license-service/README.md) — Development-only challenge, device proof, entitlement and signed-licence vertical slice.
- [Licence signer](license-signer/README.md) — Private Ed25519/deterministic-CBOR signing service and key/network isolation boundary.
- [Licence signer build and deployment](license-signer/BUILD-AND-DEPLOY.md) — Complete Synology build/run procedure for the private signing service.
- [RedOne local licence gateway](local-license-gateway/README.md) — Authenticated LAN fallback gateway, Bonjour discovery and pinned-TLS design.

### Support service

- [Support-service architecture](docs/SUPPORT_SERVICE.md) — Customer-support chatbot architecture, approved-document knowledge base and controlled learning loop.
- [Support-service implementation](support-service/README.md) — Docker service implementation, runtime/configuration and support API details.

### Instrument user guides

- [User-guide index](docs/user-guides/README.md) — Entry point for the panel-specific operator documentation.
- [Artificial Horizon / PFD guide](docs/user-guides/HORIZON.md) — Horizon presentation, controls, indications and source-validity behaviour.
- [Altimeter guide](docs/user-guides/ALTIMETER.md) — Classic analogue/digital altimeter presentation and operating notes.
- [Compass guide](docs/user-guides/COMPASS.md) — Rotating compass-card presentation, heading bug and operating conventions.

### Rebuilding generated Xcode projects

The `.xcodeproj` bundles are generated artifacts rather than authoritative source. After a fresh clone, install XcodeGen and run [`scripts/generate-xcode-projects.sh`](scripts/generate-xcode-projects.sh). The tracked `project.yml` files contain the reproducible project configuration.
