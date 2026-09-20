# ESP32 EFIS — Project activity, validation and decision status

**Status date:** 20 September 2026

This is the authoritative project-level record of implementation, validation **and significant design decisions**. It records ideas that are adopted, proposed, parked, superseded or dismissed, including the reason, so rejected approaches are not accidentally reintroduced later.

The project remains experimental **supplementary/non-primary**. Missing/invalid/stale real data fails obviously; synthetic data is never an automatic fallback. Build/simulation success is not physical validation.

## Current development gate

Physical hardware activity remains paused until prototype hardware is available. Active software work includes QEMU regression, Swift parity, documentation, pure estimator/calculation tests, static safety review, and OTA server/user-flow work.

## Status vocabulary

| Status | Meaning |
|---|---|
| **ADOPTED** | Agreed architecture/design; implementation may still be pending. |
| **IMPLEMENTED** | Code/hardware artefact exists; validation is stated separately. |
| **VALIDATED** | Tested at the explicitly named validation layer. |
| **PROPOSED** | Worth considering; no final decision yet. |
| **PARKED** | Deliberately deferred until a prerequisite or later phase. |
| **SUPERSEDED** | Replaced by a later design; retained here for history. |
| **DISMISSED** | Deliberately rejected; reason retained here. |
| **BLOCKED** | Cannot proceed until a dependency is resolved. |
| **ACCEPTED — QEMU** | Deterministic firmware/emulator behaviour reviewed at 480×480. |
| **SYNCED — SWIFT** | Swift represents accepted behaviour/scenario; not authoritative pixel renderer. |
| **COMPILE-VALIDATED** | ESP32 target compiled; no physical operation implied. |
| **IMPLEMENTED — UNVALIDATED** | Code exists; required runtime/physical validation not performed. |

## Completed / current activities

| Function | State | Validation |
|---|---|---|
| Safety model | supplementary/non-primary; explicit simulation; fail-obvious validity | **ADOPTED / DOCUMENTED** |
| QEMU RGB565 backend | native 480×480 virtual display | **ACCEPTED — QEMU** |
| Horizon | accepted pitch/bank geometry, ladder, bank scale, `ATT FAIL` | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Altimeter | three pointers, digital altitude, >10k hatch, Kollsman, `ALT FAIL` | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Compass | rotating card, wrap, heading bug, `HEADING FAIL` | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| QNH/storage | 950–1050 hPa, 1 hPa, NVS-backed setting | **SOFTWARE/QEMU ACCEPTED; ENCODER PENDING** |
| Pressure calculation | validated calculation path | **SIMULATION-TESTED; BMP585 INPUT PENDING** |
| BMI088 SPI/diagnostics | engineering-unit acquisition + commissioning log path | **COMPILE-VALIDATED; HARDWARE PENDING** |
| Attitude estimator | gyro/gravity complementary estimator, plausibility/staleness gates | **COMPILE-VALIDATED; PHYSICAL TUNING PENDING** |
| BMI088 live display gate | withheld until physical axes/signs verified | **IMPLEMENTED SAFETY GATE** |
| Swift instrument simulator | adaptive instruments/manual/AUTO/failure/acceptance scenarios | **SOFTWARE OPERATIONAL; PARITY MAINTAINED** |
| Phone/network simulator | hotspot credentials, HTTPS manifest config and staged connectivity UI | **IMPLEMENTED — SWIFT; REAL ESP32 NETWORK PENDING** |
| OTA user simulator | auto-download preference, manual Download, verified Ready, explicit `ACTIVATE & REBOOT`, success/rollback | **IMPLEMENTED — SWIFT; PHYSICAL OTA PENDING** |
| OTA Docker origin | loopback nginx read-only public-origin backend on host 127.0.0.1:8180 | **VALIDATED — SYNOLOGY RUNTIME + PUBLIC HTTPS HEALTH PATH** |
| OTA Docker admin | private dashboard on host 127.0.0.1:8090, staged releases, per-release metadata/hash, explicit Publish/republish/delete | **VALIDATED — SYNOLOGY RUNTIME + PRIVATE HTTPS ADMIN DASHBOARD; RELEASE WORKFLOW PENDING** |
| OTA CLI staging helper | versioned binary copy + SHA-256 + metadata; cannot publish | **IMPLEMENTED — RUNTIME UNVALIDATED** |
| OTA A/B ESP32 client | dual-slot/write/boot/self-test/rollback design | **ADOPTED / NOT IMPLEMENTED ON ESP32** |
| OTA security | HTTPS + signed-image design; Secure Boot/flash encryption later | **ADOPTED; LATER HARDENING** |
| Enclosure CAD | development case/carriers/fit gauge | **DESIGNED; PHYSICAL FIT PENDING** |
| Carrier PCB | architecture/pins | **PARKED** |

## Design decision and ideas register

This register records material alternatives as well as the chosen design. A later change should update the existing entry or add a new one rather than erasing the history.

### Safety, role and data semantics

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D001 | Treat ESP32 EFIS as supplementary/non-primary | **ADOPTED** | Avoids implying certification or sole-source flight-instrument status; independent trusted instruments remain required. |
| D002 | Continue displaying the last plausible value after a sensor becomes invalid/stale | **DISMISSED** | A frozen believable attitude/altitude/heading is hazardous. Invalid/stale sources must fail obviously. |
| D003 | Substitute synthetic/simulator data when a real source fails | **DISMISSED** | Could create plausible false flight information. Synthetic data is development-only and conspicuously marked. |
| D004 | Label future GNSS course as heading | **DISMISSED** | Course over ground is not magnetic heading; if added it is labelled `TRK`, and groundspeed `GS`, never IAS. |

### Display, instruments and controls

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D010 | Newhaven NHD-2.1-480480AF-ASXP round 480×480 high-brightness display | **ADOPTED** | Fits the compact round instrument concept; 1000-nit class display; accepted renderer uses native 480×480 geometry. |
| D011 | 18-bit RGB pixel bus | **DISMISSED** | GPIO pressure is more important than the extra colour bits; ST7701S supports the adopted 16-bit RGB565 path. |
| D012 | 16-bit RGB565 + 9-bit serial controller initialization | **ADOPTED** | Reduces GPIO demand while retaining full 480×480 framebuffer operation. |
| D013 | Earlier 18 MHz / 40/60/20 / 10/10/6 display timing | **SUPERSEDED** | Those values came from the MIPI timing table; current RGB baseline is 30 MHz with 50/50/4 and 50/50/2 timing. |
| D014 | Touchscreen user interface | **DISMISSED** | Selected panel has no touch; compact rotary/push control is the intended physical interaction. |
| D015 | Bourns PEC09 rotary encoder/push control | **ADOPTED** | Compact physical control for page selection/settings; physical behaviour still pending hardware validation. |
| D016 | Three instrument pages: Horizon/PFD, Altimeter, Compass | **ADOPTED** | Provides the agreed multifunction presentation while keeping each round page clear and testable. |
| D017 | Rectangular QNH/Kollsman box | **SUPERSEDED** | Replaced by accepted compact curved 3-o'clock Kollsman scale to use round-display space better. |
| D018 | >10,000-ft progressive altimeter hatching | **ADOPTED / ACCEPTED QEMU** | Provides an unmistakable visual cue without replacing the classic three-pointer presentation. |
| D019 | Selected-heading bug at relative bearing `bug - heading` | **ADOPTED / ACCEPTED QEMU** | Conventional rotating-card relationship; deterministic 060° bug used for acceptance. |

### Processor, memory and carrier hardware

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D030 | ESP32-S3-WROOM-1-N16R2 bare module | **ADOPTED** | 16 MB flash, 2 MB Quad PSRAM, native USB and sufficient memory while preserving GPIO35–37. |
| D031 | ESP32-S3 N8R8 / Octal-PSRAM module | **DISMISSED** | Project is GPIO-constrained rather than memory-constrained; Octal memory consumes GPIO35–37 needed by current shared SPI design. |
| D032 | ESP32-S3 DevKitC as final installed processor board | **SUPERSEDED** | Useful for bench work but final design favours compact bare N16R2 module on project carrier; exact older DevKit variant availability also weak. |
| D033 | Project-specific carrier PCB | **ADOPTED / PARKED** | Preferred final architecture, but connector placement/physical interfaces should not be frozen before prototype hardware proves them. |
| D034 | Finalise/manufacture carrier PCB before prototype interface validation | **DISMISSED FOR CURRENT PHASE** | Risks locking incorrect display, encoder, pressure, magnetometer or enclosure interfaces. |
| D035 | Two full 480×480 RGB565 framebuffers in PSRAM | **ADOPTED** | About 921,600 bytes total, fitting the N16R2's 2 MB Quad PSRAM; physical PSRAM operation remains to be validated. |

### Sensors, attitude, altitude and heading

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D050 | Bosch BMI088 Shuttle Board 3.0 for attitude sensing | **ADOPTED** | Separate accel/gyro, vibration-oriented device, available development board and implemented SPI acquisition path. |
| D051 | Infer BMI088 aircraft axes from PCB/connector orientation | **DISMISSED** | A plausible reversed attitude is unacceptable; physical +X forward/+Y right/+Z down mapping must be demonstrated first. |
| D052 | Connect BMI088 immediately to live Horizon | **BLOCKED / DELIBERATELY WITHHELD** | Physical axis/sign mapping and dynamic validation are prerequisites. |
| D053 | Complementary gyro/gravity pitch/roll estimator as initial AHRS | **ADOPTED / IMPLEMENTED** | Simple auditable first estimator; gravity correction is suppressed outside plausible acceleration. More advanced fusion remains possible after real data. |
| D054 | Treat accelerometer continuously as gravity | **DISMISSED** | Manoeuvre acceleration would corrupt attitude; adopted estimator gates correction using acceleration magnitude. |
| D055 | BMP585 as static-pressure source | **ADOPTED** | Pressure range/relative accuracy/environmental robustness suit the development static-altimeter role. |
| D056 | BMP581/BMP390/DPS310 alternatives | **DISMISSED FOR BASELINE** | BMP585 chosen for the documented combination of range, relative accuracy, environmental robustness and availability. |
| D057 | Adafruit ported BMP585 module for prototype | **ADOPTED** | Provides practical static plumbing without inventing a pressure chamber around an unported breakout. |
| D058 | Freeze bare-BMP585 sealed-plenum design now | **PARKED** | Decide only after the ported prototype/static system is characterised. |
| D059 | PNI RM3100-CB remote magnetometer | **ADOPTED** | Remote placement reduces panel magnetic interference; three-axis field supports calibrated tilt-compensated heading. |
| D060 | Mount magnetometer beside ESP32/regulator/display | **DISMISSED** | Local electronics/backlight/steel can distort magnetic field; remote non-magnetic installation is preferred. |
| D061 | Use raw magnetometer azimuth as final compass heading | **DISMISSED** | Final heading needs calibration, installation alignment and tilt compensation using validated attitude. |
| D062 | Magnetic/true reference and variation policy | **PROPOSED / OPEN** | Must be explicit before final heading behaviour is frozen. |

### Simulation, testing and development workflow

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D080 | Espressif QEMU at real 480×480 framebuffer geometry as authoritative software renderer | **ADOPTED** | Exercises actual ESP32 renderer without claiming physical display validation. |
| D081 | SwiftUI iPhone/iPad simulator | **ADOPTED / IMPLEMENTED** | Faster interactive scenario/UI development; it mirrors accepted behaviour but is not pixel-authoritative. |
| D082 | Treat Swift simulator appearance as proof of ESP32 display output | **DISMISSED** | Swift is a native representation, not the RGB565 renderer. QEMU is authoritative until physical display validation. |
| D083 | Mark all synthetic firmware screens clearly `SIM` | **ADOPTED** | Prevents synthetic values being mistaken for flight data. |
| D084 | Continue routine physical hardware work while hardware is unavailable | **PARKED** | Hardware-dependent claims cannot be validated; active work remains software/QEMU/Swift/docs. |
| D085 | Treat a successful hardware-target compile as physical validation | **DISMISSED** | Compile proves build integrity only. |
| D086 | Automatic hardware CI builds during hardware pause | **PARKED / SUPERSEDED BY MANUAL WORKFLOW** | Routine automatic builds add little physical evidence; workflow remains manually invokable when useful. |
| D087 | Automated QEMU demonstration/video workflow | **ADOPTED / IMPLEMENTED** | Provides repeatable demonstration of implemented instrument states; recording helper itself still requires local runtime validation. |

### OTA release source, hosting and administration

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D100 | GitHub `main` as a directly installable firmware feed | **DISMISSED** | Development source should not automatically become installable firmware; releases need an approval/publication boundary. |
| D101 | ESP32 download directly from private GitHub using a PAT | **DISMISSED** | Would place repository credentials on the instrument and couple OTA to GitHub authentication. |
| D102 | GitHub as authoritative source/build/release history + separate HTTPS distribution origin | **ADOPTED** | Separates development/release history from simple device-facing distribution and avoids GitHub credentials on EFIS. |
| D103 | Synology-hosted Docker/nginx OTA origin | **ADOPTED / IMPLEMENTED; SYNOLOGY LOCAL RUNTIME VALIDATED** | Both OTA containers build/start on the DS918+ and local health endpoints pass; public read-only HTTPS endpoint is externally health-validated on `granvillehouse.synology.me:8448`; physical EFIS consumption remains pending. |
| D104 | Expose Docker nginx port 8080 directly to Internet | **DISMISSED** | Origin remains loopback-only; public path is HTTPS :443 via reverse proxy. |
| D105 | Publicly readable approved manifest/binaries | **ADOPTED** | URL secrecy is not the trust boundary; TLS plus signed-image verification is the intended production trust model. |
| D106 | Put signing private key/GitHub token/Wi-Fi credentials in OTA container | **DISMISSED** | Distribution server should not hold development credentials or signing secrets. |
| D107 | Browser admin interface for hosted EFIS images | **ADOPTED / IMPLEMENTED** | Simplifies staged image inventory, metadata/hash review, publication, republishing and deletion. |
| D108 | Expose OTA admin UI on public update hostname | **DISMISSED** | Management is a higher-risk capability; keep it LAN/VPN/private authenticated reverse-proxy only. |
| D109 | Upload firmware and immediately publish it | **SUPERSEDED / DISMISSED** | Upload mistakes should not become consumable releases. Upload now creates STAGED release; Publish is a separate explicit admin action. |
| D110 | Separate Stage and Publish operations | **ADOPTED / IMPLEMENTED** | Creates deliberate administrative approval boundary. CLI staging helper cannot publish. |
| D111 | Delete currently published release | **DISMISSED / BLOCKED BY ADMIN UI** | Prevents manifest from pointing at a removed current image. |
| D112 | Republish an older retained image | **ADOPTED / IMPLEMENTED** | Provides administrative withdrawal/rollback of the advertised release independently of device A/B rollback. |

### EFIS networking and update user experience

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D130 | Add a cellular modem to EFIS for OTA | **DISMISSED FOR CURRENT DESIGN** | iPhone hotspot provides temporary field connectivity without additional modem/SIM/power/integration burden. |
| D131 | iPhone Personal Hotspot as temporary EFIS Internet gateway | **ADOPTED** | Phone supplies network only; EFIS remains the HTTPS OTA client. |
| D132 | Phone itself downloads/flashes EFIS firmware | **DISMISSED** | Adds an unnecessary phone-side update protocol; adopted design keeps update verification/flash/rollback on ESP32. |
| D133 | Maintenance-only Network Connection dialog on instrument | **ADOPTED; SWIFT SIMULATED** | User needs explicit hotspot credentials/server/test controls without networking silently appearing during normal operation. |
| D134 | Store hotspot SSID/password in NVS with Forget action | **ADOPTED / ESP32 IMPLEMENTATION PENDING** | Enables repeat maintenance use while keeping credentials local to the instrument. Password must not be logged/server-sent. |
| D135 | Open Wi-Fi for OTA maintenance | **DISMISSED** | Use authenticated WPA2/WPA3 Personal as supported; no reason to accept an open maintenance network. |
| D136 | Wi-Fi silently reconnects during normal instrument operation | **DISMISSED** | Network/OTA activity is maintenance-only and should not unexpectedly alter operational behaviour. |
| D137 | Layered connection test: Phone → DNS/Internet → TLS → OTA server | **ADOPTED; SWIFT SIMULATED** | Produces useful fault isolation without downloading/installing firmware. |

### OTA download, activation, rollback and security

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D150 | Single-slot in-place firmware overwrite | **DISMISSED** | Power/network/image failure could destroy the known-good application. |
| D151 | ESP-IDF A/B OTA slots + `otadata` | **ADOPTED / ESP32 IMPLEMENTATION PENDING** | Candidate is written to inactive slot; previous known-good remains recoverable. |
| D152 | Automatically activate/reboot whenever a new release is published | **DISMISSED** | Publication should not unexpectedly restart an instrument. Final activation remains a local explicit action. |
| D153 | Optional automatic download of the next published update | **ADOPTED; SWIFT SIMULATED** | Reduces maintenance friction while leaving activation under user control. Only allowed in maintenance/update context. |
| D154 | Default auto-download setting ON | **ADOPTED IN SIMULATOR** | Candidate can be ready before user chooses activation; does not imply automatic reboot. Physical policy still requires validation. |
| D155 | Simple `ACTIVATE & REBOOT` final user action | **ADOPTED; SWIFT SIMULATED** | Keeps normal user interaction simple while preserving a deliberate activation boundary. |
| D156 | Allow casual cancel after flash writing has begun | **DISMISSED** | Interruption safety should come from A/B design, not encourage power-off/cancellation during flash operations. |
| D157 | Mark candidate good immediately on reaching `app_main()` | **DISMISSED** | Candidate must pass first-boot self-test before becoming known-good. |
| D158 | Application-controlled first-boot confirmation + automatic rollback | **ADOPTED / ESP32 IMPLEMENTATION PENDING** | Failed/crashed/unconfirmed candidate restores previous known-good firmware. |
| D159 | Treat missing development sensors as automatic OTA self-test failure | **DISMISSED FOR INITIAL SELF-TEST** | Sensors may legitimately be disconnected during maintenance/development; absence should produce invalid data rather than reject otherwise bootable firmware. Stricter production profile may follow. |
| D160 | OTA-update bootloader/partition table in initial implementation | **DISMISSED FOR INITIAL SCOPE** | Initial OTA is application-only; bootloader/partition-table updates increase recovery risk. |
| D161 | SHA-256 alone as publisher authentication | **DISMISSED** | Hash detects corruption but not publisher identity; signed application images are required for production trust. |
| D162 | HTTPS certificate validation | **ADOPTED** | Protects transport/server identity and is separate from image-signature verification. |
| D163 | Signed application images | **ADOPTED / NOT YET IMPLEMENTED** | Device must verify publisher authenticity independently of public hosting. Private signing key stays off device/server repository. |
| D164 | Enable irreversible eFuse anti-rollback immediately | **PARKED** | Operational recovery and A/B rollback should be proven before irreversible version restrictions. |
| D165 | Secure Boot v2 / flash encryption | **PROPOSED FOR HARDENING** | Evaluate after baseline OTA/recovery is proven; not required to validate the first OTA mechanics. |
| D166 | Destructive config migration before candidate is accepted | **DISMISSED** | Would break rollback. Config schemas must be versioned/backward-compatible or migrations staged until candidate confirmation. |

### Enclosure and installation

| ID | Idea / decision | State | Reason / replacement |
|---|---|---|---|
| D180 | 3 1/8-inch flight-development enclosure with removable bezel/carriers | **ADOPTED / CAD IMPLEMENTED** | Supports iterative prototype access and round-display instrument format. |
| D181 | Freeze final static/magnetometer/USB openings before actual fittings are measured | **PARKED / DISMISSED FOR CURRENT PHASE** | Physical connector/tube/cable dimensions must be proven before irreversible CAD/PCB geometry. |
| D182 | Hard-coated AR optical clear polycarbonate front window | **ADOPTED AS REFERENCE** | Scratch resistance and anti-reflection are desirable for cockpit readability; physical evaluation pending. |
| D183 | Aircraft integration before bench sensor/display/failure validation | **BLOCKED** | Ground/bench validation gates must pass before aircraft evaluation. |

## Definitive OTA policy

**Stage → Publish → Download → Activate.** Admin upload/stage never publishes. Publish changes the public manifest. EFIS auto-download may download/verify only in maintenance context. **Activation/reboot is always explicit.** First boot must self-test and either mark the candidate known-good or rollback. See `OTA_IMAGE_ADMIN.md`, `OTA_USER_SCENARIO.md`, `PHONE_NETWORK_AND_PUBLIC_OTA.md`, `REMOTE_UPDATES.md` and `../ota-server/README.md`.

## Accepted emulator sequences

Horizon: level, ±10/±20 pitch, ±30/±60 bank, combined attitude, failure/recovery. Altimeter: representative 0–12,500 ft values, sweep, failure/recovery and QNH exercises. Compass: cardinal/intercardinal headings, 350→010 wrap, rotation, failure/recovery with deterministic 060° bug. Full details remain in `SIMULATION.md`.

## Remaining work

| Function | Work / validation required | Status |
|---|---|---|
| Decision-register maintenance | record every material new proposal, adoption, supersession, dismissal or parked item with reason | **ONGOING DOCUMENTATION RULE** |
| Swift parity | keep instrument/network/OTA scenarios aligned with firmware policy | **ACTIVE SOFTWARE TASK** |
| OTA server deployment | containers build/run on Synology; local health, private admin HTTPS dashboard and public read-only HTTPS health path are validated; manifest/release and physical EFIS OTA remain | **NETWORK PATH VALIDATED / RELEASE + DEVICE TESTING PENDING** |
| OTA ESP32 Phase 1 | freeze A/B partition sizes; manifest/parser/state machine; persisted auto-download policy | **ADOPTED / SOFTWARE CANDIDATE** |
| OTA ESP32 Phase 2 | maintenance Wi-Fi + HTTPS writer + explicit activation + boot confirmation | **PENDING HARDWARE** |
| OTA interruption/rollback | A↔B, Wi-Fi/power loss, corrupt image, crash/self-test rollback, NVS compatibility, USB recovery | **PENDING HARDWARE** |
| OTA security | signed releases/verification; later Secure Boot/flash encryption; eFuse anti-rollback deferred | **ADOPTED / LATER HARDENING** |
| BMI088 axes/bias/tuning/live connection | physical orientation, stationary/dynamic data, estimator tuning | **PENDING HARDWARE** |
| BMP585/static/live altitude | physical driver, pressure validation, plumbing, failure/staleness | **PENDING HARDWARE** |
| RM3100/calibration/heading | acquisition, hard/soft iron, installation alignment, tilt compensation | **PENDING HARDWARE** |
| MCP23008/PEC09/NVS | physical interaction/persistence | **PENDING HARDWARE** |
| LCD/backlight/PSRAM/power | physical bring-up, stress, thermal/electrical checks | **PENDING HARDWARE** |
| Enclosure/EMI/vibration/thermal | physical and powered installation tests | **PENDING HARDWARE** |
| Aircraft ground/airborne comparison | only after all preceding gates | **FUTURE / BLOCKED** |
| Carrier PCB | resume after prototype interfaces proven | **PARKED** |

## Hardware-resumption gate

Inventory/inspection → ESP32/display/power → BMI088 axis mapping → estimator validation → BMP585/static → encoder → RM3100/calibration → integrated failure/staleness → **real OTA download/activation/interruption/rollback** → enclosure/thermal/vibration → aircraft ground testing. Never infer airborne readiness from compilation, Docker, Swift or QEMU results.

## Documentation and decision-history rule

Every functional change updates relevant code documentation and project status in the same stage. Validation statements must identify the layer: compile, QEMU, Swift, Docker runtime, electronics bench, physical fixture, aircraft ground or airborne.

Every **material design idea** must also be represented in the Design Decision and Ideas Register when it affects architecture, safety, hardware selection, user workflow, testing or future work. Record the idea even when it is rejected. Use **PROPOSED**, **ADOPTED**, **IMPLEMENTED**, **PARKED**, **SUPERSEDED**, **DISMISSED** or **BLOCKED**, and retain the reason/replacement. Do not silently delete historical decisions when the design changes; mark them superseded/dismissed and add the replacement decision. This file is therefore the authoritative answer to both **“where is the project now?”** and **“what did we consider and why did we choose this design?”**.
