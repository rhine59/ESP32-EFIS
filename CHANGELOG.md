## 2026-10-18 — Recovery stack fix flashed and read back on RedOne

With explicit approval, preserved a fresh factory backup, flashed only the corrected factory recovery image at 0x20000 and independently verified all 814560 image bytes by readback. Normal OTA A status remains running/selected. Physical recovery diagnostic retest not yet done.

## 2026-10-18 — Fix recovery diagnostic main-task stack overflow (not deployed)

Moved the 4096-byte USB diagnostics JSON buffer from the 3584-byte main task stack to checked heap allocation; added two regression tests. ESP-IDF 5.4.4 recovery build and 48 Python tests pass. Physical factory image unchanged pending separate flash authorization.

## 2026-10-18 — Physical factory recovery/return-to-A validated; diagnostic crash discovered

Explicitly authorised single-board OTA metadata erase entered factory recovery. USB `status` and `bootA` worked; bootloader returned to OTA A and normal heartbeats resumed. Recovery `test` triggered a main-task stack overflow and reboot; blocking defect documented. Post-return OTA selection valid for A. Partition B remains NO-GO.

## 2026-10-18 — Physical factory entry mechanism reviewed

Confirmed running Partition A USB console has no factory-selection command. A host-side OTA metadata erase would be required; documented the difference and held execution pending specific approval. No writes.

## 2026-10-18 — Single-board recovery plan and fresh live OTA check

Recorded single-board test approach and its elevated risks. Read-only live OTA snapshot again selects A and matches verified full backup. Physical factory boot/metadata erase still awaits separate explicit authorization.

## 2026-10-18 — Independent physical recovery execution gate

Added read-only ten-check evidence preflight for RedOne backup, OTA metadata and factory recovery, explicitly rejecting physical writes/boot authorization despite passing offline checks. 46 tests pass.

## 2026-10-18 — Fail-closed authenticated chunk resumability

Strengthened RedOne read-only flash backup tool with per-chunk hash manifest, device identity and layout binding, atomic persistence and fail-closed legacy/tamper handling. 44 tests pass; no device writes.

## 2026-10-18 — Independent chunk backup integrity audit

Added offline tool and tests comparing all 16 source flash chunks, assembled backup, current OTA metadata and independently captured factory recovery partition. Forty tests pass; no device writes.

## 2026-10-18 — Offline OTA metadata rescue rehearsal

Added fail-closed in-memory erase/restore rehearsal using verified physical flash backup and current OTA snapshot; full-image hash restored byte-for-byte. No device writes or boot changes.

## 2026-10-18 — Fresh complete RedOne flash backup verified

Captured 16 MiB read-only backup in sixteen verified 1 MiB chunks; verified full SHA-256 and independent OTA metadata/factory/first-MiB consistency. Added resumable read-only chunk tool. No boot or flash changes; recovery test NO-GO pending rescue validation.

## 2026-10-18 — Intermittent USB full backup handshake investigated

Verified read-only 64 KiB and 1 MiB transfers at 921600 baud, while repeated full 16 MiB attempts stalled at Connecting. No fresh full backup completed; recovery boot NO-GO.

## 2026-10-18 — Full flash backup diagnostics

Read-only 64 KiB test succeeded at 921600 baud, but 16 MiB attempts stalled at serial connection handshake. Fresh complete full backup still outstanding; factory recovery boot NO-GO.

## 2026-10-18 — Offline factory recovery transition simulation

Modeled fresh OTA selection through factory metadata erase and recovery bootA rewrite, covering NEW/UNDEFINED state variants. No physical boot or flash writes.

## 2026-10-18 — Fresh OTA snapshot and offline rescue preflight

Captured fresh read-only 8 KiB OTA metadata; discovered the older full backup has stale OTA selection. Added fail-closed offline rescue planner/tests. Fresh 16 MiB backup remains incomplete; physical factory recovery boot NO-GO.

## 2026-10-18 — Offline factory recovery return-path audit

Confirmed the deployed recovery image matches the local build and contains USB `bootA` selection of ota_0. Added fail-closed offline audit and tests; no physical factory boot or flash writes.

## 2026-10-18 — Physical factory recovery test planning

Documented that ESP-IDF factory boot selection erases OTA metadata and requires a validated return-to-A rescue path. Created a non-executable supervised recovery test plan; no device modifications authorised.

## 2026-10-18 — Physical RedOne running partition confirmed

Observed live bootloader and USB status telemetry independently confirming running/selected `ota_0`, despite a compiled `IMAGE B` label. No flash writes, boot selection or recovery test performed; Partition B NO-GO.

## 2026-10-18 — Live OTA record validation

Added an offline ESP-IDF OTA metadata decoder and regression tests. Physical RedOne metadata contains two CRC-valid, VALID records; latest selects Partition A. Running firmware not independently confirmed. No writes; Partition B NO-GO.

## 2026-10-18 — Complete live recovery partition verification

Read live OTA metadata and the entire factory recovery partition without writes; factory bytes matched backup and ESP32 image checksum/hash were valid. Bootability and active OTA slot remain to be independently confirmed. Partition B NO-GO.

## 2026-10-18 — Physical RedOne read-only inventory

Verified live ESP32-S3 identity and flash size, full-backup checksum, matching partition-table and recovery-header samples, and disabled secure boot/flash encryption. No flash/eFuse writes; physical Partition B remains NO-GO.

## 2026-10-18 — Stage 19 dedicated security-board preparation

Added a gated separate-board test plan, read-only preflight and regression tests. No physical board or provisioning approval established; existing RedOne remains untouched.

## 2026-10-18 — Stage 18 security and recovery architecture

Documented the hardware security epoch, signed release build, trusted build-floor and recovery compatibility strategy. Added a read-only configuration audit and regression test. Existing RedOne hardware unchanged; Partition B NO-GO.

## 2026-10-18 — Trusted build-floor storage policy

Added a fail-closed hardware-backed monotonic floor interface and host tests; no hardware provider or eFuse provisioning performed. Physical Partition B deployment remains blocked.

## 2026-10-18 — Shell release staging policy alignment

Legacy shell staging now shares OTA Admin build-floor validation, with negative regression tests. Staging remains separate from publishing and physical device OTA remains locked.

## 2026-10-18 — Publisher build-policy validation

Added strict signed build/minimum validation to OTA Admin staging and publishing with unit tests. Existing published manifests remain unchanged; physical OTA remains locked.

## 2026-10-18 — Fail-closed signed build gate in experimental staging

- Wired verified signed minimum-build parsing and anti-downgrade policy ahead of all inactive-slot staging operations.
- Explicitly block staging until trustworthy persistent floor and running-build provenance exist; legacy publisher semver minima are rejected.
- Host source tests and ESP-IDF build passed; no physical firmware changes or HTTP write route enabled.

## 2026-10-18 — Signed build-floor parser

Added strict minimum build parser and host tests. Not yet wired to OTA staging; physical deployment remains blocked.

## 2026-10-18 — Read-only device boot-health snapshot

- Added authenticated `GET /boot-health` to bench firmware for live ESP-IDF partition and boot-state evidence.
- Physical sensor/display/power/rollback/ground-confirmation evidence remains explicitly false; the endpoint cannot confirm or activate firmware.
- Host source tests and ESP-IDF build passed; no board flashing performed. Partition B remains NO-GO.

## 2026-10-18 — Fail-closed OTA boot-health policy

- Added pure C boot-health evidence policy with host tests for each missing prerequisite.
- Bench firmware refuses to confirm pending images while required physical health evidence is unavailable; OTA activation remains locked.
- ESP-IDF build and host regression tests passed; no physical board flashing or power-loss tests were performed.

## 2026-10-18 — Green EFIS status and Partition B deployment gate

- Authenticated EFIS status information now renders green in the Lollipop iOS connection panel instead of grey; the update controls remain disabled.
- Added a non-destructive, fail-closed Partition B readiness audit and unit tests. No physical deployment is authorised or attempted; outstanding hardware and rollback gates are documented in `docs/REDONE-PARTITION-B-DEPLOYMENT-READINESS.md`.

## 2026-10-18 — Comprehensive RedOne guides

- Added `docs/REDONE-USER-GUIDE.md` for customer/owner and bench use, including connection, licence, instrument operation, firmware safety, diagnostics and troubleshooting.
- Added `docs/REDONE-ARCHITECTURE-GUIDE.md` for component boundaries, hardware, signed OTA, boot/rollback, services, security, test commands and acceptance gates.
- Linked both guides from the project README. Documentation only: no firmware flash, device configuration or application deployment.

# Change History

This file is the chronological checkpoint history for ESP32-EFIS. GitHub `main` is the authoritative source of truth. Every future project checkpoint must update this file in the same change set as the implementation/documentation checkpoint.

For detailed design rationale, validation scope and superseded decisions, see `docs/PROJECT_STATUS.md`.

## 2026-10-05

### Adaptive licence-management screen
- Reworked the iPhone licence screen into an explicit full-height `ScrollView` with adaptive content width and safe-area bottom padding.
- All licence/account, purchase, entitlement-service, cached-licence and explanatory content remains reachable on small and large iPhone displays rather than relying on a fixed visible form height.
- Operation status remains pinned above the scrolling content.
- Build passes and the updated app has been installed/launched in the simulator.

### Fix licence account/catalogue loading
- Fixed iOS decoding of the server `price_display` field into the Swift `priceDisplay` model.
- Account state now loads independently of the licence product catalogue so a catalogue failure cannot hide valid ownership/entitlement data.
- Rebuilt and reinstalled EFIS Service in the iPhone 17 Pro simulator; build passes.

### iPhone signed-entitlement acquisition — PASS
- Fixed iOS Simulator Keychain failure `-34018` by restoring normal simulator code signing and removing the forced empty development-team setting from the generated project definition.
- Rebuilt, code-signed, installed and relaunched EFIS Service.
- User-confirmed **Get / Refresh Signed Entitlement** succeeds.
- User-confirmed Keychain-backed UI shows Device `EFIS-SIM-0001`, entitlement `ACTIVE` and cached signed envelope.
- Next validation: terminate/relaunch and confirm Keychain persistence.

### iPhone entitlement live integration — PASS
- Added restricted simulator phone entitlement broker.
- Phone no longer contains the simulator device HMAC credential.
- Broker performs internal challenge/HMAC exchange and returns only the already-signed DEVELOPMENT licence.
- Live HTTPS broker test returned expected Device ID, product, ACTIVE entitlement and non-empty signed licence.
- SwiftUI app builds and launches in iPhone 17 Pro simulator.

### iPhone entitlement client — STARTED
- Added `ios/EFISService/` SwiftUI application and XcodeGen project definition.
- Added Device-ID entry, entitlement retrieval, Keychain cache, cached-licence display and explicit EFIS transfer boundary.
- Phone has no Ed25519 licence-signing capability.
- Fixed Swift 6 actor isolation in the transfer abstraction.

### Docker licensing contract — COMPLETE FOR CURRENT SIMULATOR STAGE
- Regression harness passes signed acquisition and local Ed25519/schema/product/Device-ID verification.
- Verified persistence across offline restart.
- Verified rejection of tampered payload, bad signature and correctly signed wrong-Device-ID licence.
- Verified no-entitlement preservation of existing valid licence.
- Verified interrupted replacement recovery and startup cleanup of orphan candidate.
- Verified Licence Reset invariants, offline acquisition refusal, corrupt-store detection and signed recovery.
- Physical protected-NVS, provisioning and real power-loss validation deliberately remain hardware work.

### Licensing security regression — PASS
- Added and executed non-destructive licence failure-path harness.
- Corrected wrong-device test to use a valid signature for another Device ID, independently proving Device-ID binding.
- Removed interactive `sudo` requirement from Synology rebuild workflow.

## 2026-10-04

### Signed licence service and persistence — PASS
- Added development licence service using deterministic CBOR and Ed25519.
- Added device challenge/HMAC authentication and simulator trust endpoint.
- Simulator acquires, verifies and installs signed DEVELOPMENT licences.
- Persisted signed envelope survives simulator restart and verifies locally while offline.
- Added rebuild and licence test scripts.
- Added negative-test fixtures for tampering, signature corruption and Device-ID mismatch.

## 2026-10-02

### Product naming and documentation
- Consolidated customer-facing branding around Lollipop Design.
- Canonical engineering product roles remain EFIS and SMUX.
- Updated project documentation to avoid unstable branding leaking into protocol, Docker, OTA and cryptographic identifiers.

### Enclosure/material decisions
- Adopted ASA as the preferred enclosure material baseline.
- Documented captive M5 lid-fastening approach and thermal considerations.

## 2026-10-01

### CAN and firmware architecture
- Adopted AEF-CAN as the extensible aircraft data bus.
- Established Classical CAN 500 kbit/s / 11-bit baseline while keeping application semantics future-compatible with CAN FD.
- Added EFIS/SMUX firmware dependency and compatibility strategy.
- Added phone-mediated OTA requirement for aircraft locations without Internet connectivity.
- Added factory USB-C programming approach for SMUX.
- Added staged/checkpointed firmware delivery and recovery architecture.
- Reviewed and improved firmware transport and other sub-optimal architecture decisions.

### SMUX sensor architecture
- Documented sensor auto-discovery, EFIS↔SMUX connection, sensor harness bundling and sensor power.
- Added Rotax 912 ULS battery voltage, fuel pressure and fuel-level input requirements.
- Adopted EFIS-controlled engineering units and per-channel low/normal/high thresholds; oil pressure uses psi.

### Documentation/manual
- Added indexed project manual generation and commissioning-process documentation.
- Corrected PDF BOM table formatting.

## 2026-09-30

### OTA physical-test planning
- Defined minimal two-image ESP32 OTA harness with visibly different LED behaviour.
- Documented publication, pull, staging and activation experiment.

### CAN architecture start
- Added provisional CAN/sensor phase to the project.
- Established supplementary/non-certified role and future-proof protocol goals.

## 2026-09-29

### Speech/chat integration review
- Reviewed server speech/chat changes and STT → chat → TTS integration/validation path.

### Server platform
- Documented proposed Docker/virtualisation host architecture, Proxmox/LXC/VM roles and later k3s option.
- Added networking/switching and DNS considerations for the development infrastructure.

## 2026-09-27

### Customer support service
- Added Dockerized Lollipop Design RedOne support-service architecture.
- Established human validation boundary before customer Q&A becomes authoritative.

## 2026-09-26

### Boot, maintenance and diagnostics
- Adopted rotary/push boot menu with START EFIS, FULL TEST and FIRMWARE UPDATE.
- Added persistent fault-history requirement.
- Added maintenance Wi-Fi/NVS/Forget-network behaviour and fail-independent normal startup.

### Product licensing architecture
- Adopted immutable EFIS Device ID and signed offline-verifiable licensing.
- Separated account, entitlement/payment and private signing responsibilities.
- Defined online and offline licence flows and explicit Licence Reset semantics.
- Adopted deterministic CBOR + Ed25519 envelope architecture and key rotation identifier.
- Established that licence verification is local and normal EFIS startup never depends on network/account availability.

### Pressure scope
- Explicitly removed ASI/IAS/PITOT/differential-pressure capability.
- BMP585 is STATIC pressure only.

## Earlier baseline checkpoints

Earlier development established the project's supplementary/non-primary safety model, ESP32-S3-WROOM-1-N16R2 hardware baseline, Newhaven 480×480 round RGB565 display, Bourns rotary/push control, BMI088 attitude sensing, BMP585 static-pressure altitude source, RM3100 remote magnetometer, QEMU authoritative renderer, SwiftUI simulator, fail-obvious sensor validity, Synology-hosted OTA origin/admin services, separate Stage/Publish workflow, A/B OTA/rollback design and maintenance-only iPhone hotspot networking.

The detailed historical decision register—including adopted, superseded, parked and dismissed alternatives—is retained in `docs/PROJECT_STATUS.md`. This summary does not replace that register.

### iPhone Keychain persistence across simulator shutdown — PASS
- Completely terminated the iOS Simulator after caching the signed entitlement.
- Reopened the original iPhone 17 Pro simulator and launched EFIS Service without requesting or refreshing a licence.
- User-confirmed the cached entitlement immediately returned as `ACTIVE`.
- This validates iPhone-side Keychain persistence across simulator shutdown/restart for the current development client.
- Next implementation checkpoint: QR acquisition of the immutable EFIS Device ID.

### iPhone QR Device-ID scanner — IMPLEMENTED / BUILD-VALIDATED
- Replaced the QR placeholder with an AVFoundation QR scanner.
- Accepts either a direct `EFIS-...` Device ID or `efis://device/<Device-ID>` QR payload.
- Valid scans populate the entitlement Device-ID field; manual entry remains available.
- Added camera privacy usage text to the Git-authoritative XcodeGen project.
- Resolved Swift 6 actor-isolation issues in the capture delegate.
- Xcode iOS Simulator build passes.
- Physical camera scanning cannot be validated in the iOS Simulator and remains a real-iPhone test.

### Simulator Device-ID QR — PASS
- Web simulator now generates a canonical QR payload `efis://device/<Device-ID>`.
- QR is rendered locally as PNG by the simulator; no external QR service is used.
- Simulator UI displays both QR and textual payload.
- Identification-only security boundary is stated explicitly.
- Synology simulator rebuilt successfully and live QR endpoint returned HTTP 200 with a generated PNG.
- This provides the EFIS side of the phone QR acquisition workflow; real camera scan remains a physical-iPhone test.

### Phone-to-EFIS signed licence transfer — IMPLEMENTED / BUILD-VALIDATED
- Replaced the iPhone transfer placeholder with a local HTTP signed-envelope transfer client.
- Added simulator `POST /api/phone/install-license`.
- EFIS simulator checks Device ID, independently verifies the existing Ed25519 signed envelope against locally provisioned trust, validates schema/product/device binding, and only then atomically persists and activates it.
- The phone sends the opaque signed envelope; it does not sign, reinterpret or grant the licence.
- iOS Simulator target builds successfully and updated app was installed/launched.
- Synology web simulator rebuilt with the receiving endpoint.
- End-to-end user-triggered Transfer button validation remains the next test.

### Phone-to-EFIS signed licence transfer — END-TO-END PASS
- User-triggered Transfer to EFIS completed successfully from the iOS Simulator.
- Phone UI reported transfer completion.
- Independent query of the EFIS simulator after transfer reported licence `VALID`, class `DEVELOPMENT`, under trust key `sim-dev-1`.
- This proves the simulated phone-to-EFIS path reaches the EFIS verifier and results in an installed, cryptographically verified licence rather than merely a successful HTTP submission.
- Also corrected the iPhone UI so operation status is permanently visible at the top of the screen.
- This remains a simulator/service-contract validation; physical ESP32 protected storage and real local phone transport remain later hardware validation.

### Offline phone licence transfer and restart — PASS
- Extended the automated licence regression harness to model the aircraft-side offline scenario.
- A signed licence was obtained while service connectivity was available and retained as the phone-side cached envelope.
- EFIS simulator was then set offline and its installed licence cleared while preserving the provisioned trust anchor.
- The cached signed envelope transferred successfully while EFIS was offline and was independently verified/installed as `VALID`.
- Simulator restart while still offline reloaded the same licence as `VALID` without licence-service contact.
- Full licence regression suite passed, including integrity, Device-ID binding, entitlement refusal, interrupted replacement, reset, corruption recovery, offline transfer and offline restart persistence.

### iPhone licence purchase and management — DEVELOPMENT UI IMPLEMENTED
- Added licence account management state to EFIS Service: ownership, entitlement, current plan and transferability.
- Added server-provided licence plan catalogue and purchase actions.
- Added development-only purchase API; it explicitly takes no payment and is not a production commerce path.
- Successful simulated purchase activates the development entitlement and the phone then retrieves/caches the resulting server-signed licence.
- Existing QR, Keychain and Transfer to EFIS paths remain intact.
- iOS Simulator build passes and updated app has been installed/launched.
- Production gate remains authenticated customer accounts plus payment-provider checkout and verified webhook before entitlement activation.

### Licence lifecycle management UI — IMPLEMENTED
- Added simulated annual renewal/auto-renewal enablement and cancellation.
- Added ownership-transfer initiation using buyer email plus cancellation of a pending transfer.
- Account display now exposes renewal and pending-transfer state when applicable.
- Lifecycle actions remain server-authoritative; the phone only requests changes.
- Purchase/renewal/transfer endpoints remain development simulation and take no payment.
- iOS build passes, updated app is installed/launched, and Synology simulator has been rebuilt.

## 2026-10-05 — iPhone licence lifecycle and verified EFIS installation checkpoint
- Reworked EFIS Service licensing into Licence, Purchase, Manage and Transfer tabs for reliable access on all phone screen sizes.
- Added severity-coloured activity/progress banners across all licence actions.
- Added state-aware renewal and ownership-transfer controls and validated cancel/re-enable/pending/cancel flows.
- Confirmed Apple Keychain secure licence caching; documented that runtime Keychain testing requires a normally signed simulator build.
- Strengthened phone-to-EFIS transfer so success requires explicit `INSTALLED` + `VALID` receiver acknowledgement after verification and persistence.
- Proved the installed simulator licence survives EFIS container restart while offline.
- Simplified the success banner and moved the returned installed licence ID into Transfer details.

## 2026-10-05 — process-oriented EFIS Service UI architecture
- Adopted guided process/state-machine interaction as the standard UI model for all EFIS Service use cases.
- Replaced the normal app entry point with an outcome-oriented process catalogue.
- Added common green/blue/grey/amber/red progression semantics and reusable step presentation.
- Added process definitions for new setup, reassignment/sale, receiving a transfer, renewal, licence installation, EFIS replacement, recovery, firmware update, commissioning and diagnosis.
- Implemented Reassign EFIS as the first state-aware reference flow using the real account and ownership-transfer lifecycle state.
- Kept the validated Licence/Purchase/Manage/Transfer interface under Advanced for diagnostics and manual recovery.
- Buyer transfer acceptance remains explicitly implementation-pending and is shown as an amber waiting state rather than falsely completed.

## 2026-10-05 — physical iPhone setup workflow
- Built, signed, installed and launched EFISService on the paired iPhone 13 Pro Max using the existing Apple Development team.
- Converted Set up a new EFIS from a process placeholder into a state-aware guided workflow.
- Setup progression now derives from account recognition, ACTIVE entitlement, signed licence cache and explicit EFIS installation acknowledgement.
- Normal setup exposes only the next valid action: identify EFIS, choose licence, obtain signed licence, install on EFIS, then confirm VALID.
- Retained the explicit EFIS acknowledgement requirement; reaching the installation screen alone never marks setup complete.

## 2026-10-05 — receive transferred EFIS reference workflow
- Added simulation-only buyer acceptance with pending-transfer and invited-email validation.
- Buyer mismatch is rejected; acceptance changes the simulated owner atomically and records transfer status ACCEPTED.
- Added a state-aware Receive a transferred EFIS workflow to the iOS app.
- After acceptance the app obtains a replacement signed entitlement, installs it on the EFIS and requires explicit VALID acknowledgement before completion.
- Production caveat is explicit: email matching is development validation, not buyer authentication. Production requires authenticated customer identity and a short-lived single-use transfer invitation credential.
- Deployed the updated EFIS web simulator service and installed/launched the updated app on the physical iPhone 13 Pro Max.

## 2026-10-05 — RedOne included first-year licence workflow
- Added Buy / activate a licence as a first-class guided process with plain-language completed/next-step guidance.
- Added development entitlement states INCLUDED_UNUSED, INCLUDED_ACTIVE and PAID_ACTIVE; EXPIRED is reserved for expiry processing.
- New RedOne simulator state begins with one unused included first-year entitlement.
- Activating the included year consumes it once, starts a 365-day term from activation and exposes the expiry/renewal date.
- A second attempt to claim the included year is rejected with HTTP 409.
- Payment choices are not shown while the included first year is available.
- Physical iPhone build succeeded and the updated app was installed and launched.

## 2026-10-05 — tap-current-step workflow interaction
- Adopted tap the current process step to advance as the canonical phone interaction.
- Blue/current process rows can execute their state transition directly; grey future rows remain disabled and visually subdued.
- Amber and red rows may expose safe waiting-state or corrective actions; completed green rows do not repeat state-changing operations.
- Wired direct row actions for included-year activation, signed-licence acquisition and EFIS installation in the Buy/activate flow, and licence acquisition/installation in Setup and Receive flows.
- Retained separate controls where user input or a choice is required.
- Rebuilt, installed and launched the updated app on the physical iPhone 13 Pro Max.

## 2026-10-05 — explicit tappable workflow rows
- Replaced implicit row tap gestures with native full-row Buttons for actionable workflow steps.
- Actionable rows now show a prominent chevron-in-circle and `Tap` label on the right so the interaction is visually unambiguous.
- Waiting rows remain non-interactive and visually subdued; completed rows remain confirmation only.
- Added an accessibility hint to actionable workflow steps.
- Rebuilt, installed and launched the corrected app on the physical iPhone.

## 2026-10-05 — dual workflow action targets
- Removed the explicit `Tap`/chevron affordance from actionable process rows.
- The full current step row/text remains tappable.
- The plain-language instruction under `What to do next` can invoke the same workflow action, giving the user two natural ways to advance.
- Both interaction targets share the same authoritative state transition rather than duplicating workflow logic.
- Updated the workflow architecture and rebuilt/installed the app on the physical iPhone.

## 2026-10-05 — repair Setup workflow tap path
- Corrected `Set up a new EFIS`, where blue/current rows could previously be rendered without an attached action.
- The current Identify EFIS row and top guidance now invoke EFIS identification directly.
- Setup now recognises `INCLUDED_UNUSED` and offers/executes the included first-year activation instead of falling through to paid plan selection.
- Active licence acquisition and EFIS installation remain available from both the current row and top guidance.
- Replaced Setup’s old non-interactive status banner with the shared actionable `ProcessGuidanceView`.
- Rebuilt, installed and launched the corrected app on the physical iPhone.

## 2026-10-05 — List button hit-testing and guidance contrast
- Changed actionable workflow row buttons from plain to borderless List buttons to avoid SwiftUI List row-selection/tap interference while preserving the full-row label hit area.
- `What to do next` remains blue while its actionable instruction is now green, clearly separating the heading from the action offered beneath it.
- Rebuilt, installed and launched the updated app on the physical iPhone.

## 2026-10-05 — fix iOS account URL query construction
- Diagnosed physical-iPhone `NSURLErrorDomain -1004` after confirming workflow taps were firing.
- The account request incorrectly used `URL.appending(path:)` with `?device_id=...`, causing `?` to be encoded as `%3F` and the query to become part of the path.
- Account lookup now constructs `device_id` with `URLComponents` and `URLQueryItem`.
- Rebuilt, installed and launched the corrected app on the physical iPhone.

## 2026-10-05 — validate physical iPhone licence-service network path
- Confirmed the physical iPhone can reach the Synology licence service and that the public TLS certificate for `granvillehouse.synology.me` is valid when the hostname is used.
- Added a Synology `local-dns` dnsmasq service providing split DNS for `granvillehouse.synology.me -> 192.168.1.99`; FRITZ!Box DHCP now advertises the NAS as the LAN DNS server.
- Diagnosed iOS `-1004` as a resolver/network-path issue rather than an EFIS licence API failure. The phone's Limit IP Address Tracking setting interfered with the private split-DNS path; disabling it for the home Wi-Fi allowed EFIS Service to load the licence account.
- Removed the temporary direct-IP probe after diagnosis; TLS verification remains strict and the app continues to use the hostname rather than a private IP.
- Documented that production must use a normal publicly routable HTTPS licence endpoint and must not depend on split DNS or changing iPhone privacy settings.

## 2026-10-05 — reject split DNS as customer licence architecture
- Reclassified the Synology split-DNS configuration as a development diagnostic only, not a supported RedOne deployment requirement.
- Defined the production licence API requirement: stable public DNS, publicly trusted TLS, standard HTTPS TCP 443, and identical operation over ordinary Wi-Fi and cellular.
- Explicitly prohibited customer requirements to change router/DNS settings, disable iOS privacy features, install certificates, hard-code private IPs, or edit backend URLs during normal setup.
- Added pre-release validation requirements across home Wi-Fi, unrelated Wi-Fi and cellular with normal iOS privacy settings enabled.

## 2026-10-05 — separate development and release licence endpoints
- Moved the iOS licence-service endpoint behind `EFISServiceConfiguration`.
- Debug builds retain the editable Synology development endpoint for simulator work.
- Release builds read `EFISLicenceServiceURL` from application configuration and no longer expose a customer-editable backend URL.
- Both Debug and Release simulator builds pass.
- A production public HTTPS service is now an explicit release gate; the development NAS endpoint cannot silently ship as the customer backend.

## 2026-10-05 — production licence-service release gate
- Added a production deployment specification separating the public customer API, PostgreSQL entitlement/account state and private signing boundary from the simulator harness.
- Release EFIS Service now accepts only a configured HTTPS licence endpoint on the default HTTPS port or explicit TCP 443 and fails closed when no production endpoint is supplied.
- Explicitly prohibited deploying the current simulator licence service as the customer backend.
- Added security, hosting, database, signing, payment, monitoring and cross-network validation gates required before TestFlight uses the production service.

## 2026-10-05 — retain Synology as current licence hosting platform
- Confirmed the project Synology remains the hosting platform for the licence/account service during the current development and early distribution phase.
- External managed/cloud hosting is deferred rather than treated as a current release prerequisite.
- Zero-configuration client networking remains mandatory: users must not alter DNS/router/iOS privacy settings.
- Preferred next deployment step is a stable public HTTPS route to the Synology that avoids local NAT-loopback dependence, while keeping the signer private and preserving the production service boundaries.

## 2026-10-05 — adopt app-controlled Synology local/public routing
- Rejected external tunnel products and router-specific DNS/NAT-loopback configuration as dependencies.
- Adopted canonical public HTTPS first with automatic authenticated local-Synology fallback only when the app is on the hosting LAN and the public route is unreachable.
- Local routing must use discovery rather than a hard-coded NAS IP and must preserve cryptographic server authentication; TLS validation may not be bypassed.
- Removed the temporary Cloudflare Quick Tunnel container from the Synology.

## 2026-10-05 — stage authenticated Synology LAN licence gateway
- Added `local-license-gateway/` as the dedicated TLS-protected LAN fallback boundary.
- Gateway exposes only `/api/phone/` plus a minimal health endpoint and proxies to the loopback-bound Synology simulator/API during development.
- Local gateway uses a dedicated pinned TLS identity independent of DSM certificate renewal; private key remains on the NAS.
- Bonjour `_redone-license._tcp` discovery and iOS certificate/public-key pin validation are mandatory before enabling fallback in the app.

## 2026-10-05 — validate authenticated local licence fallback on physical iPhone
- Added the Synology `redone-local-license-gateway` container with repository-owned mDNS advertisement and dedicated TLS identity.
- Added iOS public-first/local-fallback routing for account management and signed-entitlement retrieval.
- Local HTTPS is accepted only when the gateway leaf-certificate SHA-256 matches the pin embedded in the signed app; a discovered LAN service alone is not trusted.
- Corrected mDNS advertisement to publish the NAS interface address dynamically rather than loopback.
- Physical iPhone test passed: `Licence account loaded` with normal router/DNS settings and no external tunnel.

## 2026-10-05 — make Synology licence path rebuildable and simplify workflow guidance
- Added the detailed canonical RedOne licence network/disaster-recovery architecture and acceptance checklist.
- Added gateway rebuild and strict smoke-test scripts; the main Synology rebuild now includes the authenticated local gateway.
- Documented TLS-key backup, lost-key recovery and overlap-first certificate rotation; private keys remain outside Git.
- Simplified process GUI: the top guidance contains only the next action/status; duplicate lower `Next action` sections were removed and progress/history remains in the numbered process list.

## 2026-10-05 — make XcodeGen definitions authoritative
- Reconciled local Xcode project drift back into tracked `project.yml` definitions.
- Added the EFIS Service local-network usage description required by authenticated Synology fallback to its XcodeGen definition.
- Confirmed the simulator XcodeGen project automatically includes `NetworkSetupView.swift` and `OTAFlowView.swift`.
- Added `scripts/generate-xcode-projects.sh`; both EFIS Service and simulator projects regenerate and build successfully from Git definitions.
- Removed generated simulator `.xcodeproj` files from version control and ignore generated Xcode projects plus per-user `xcuserdata`/`xcuserstate`.

## 2026-10-06 — Lollipop account signup in EFIS Service
- Added **Create a Lollipop account** as a first-class process on the phone home screen.
- Added a guided account workflow separating account creation from RedOne registration/licensing.
- Account credentials remain owned by the dedicated account service; EFIS Service opens the secure registration flow rather than routing credentials through the licence simulator.
- Debug/release registration URLs are separated in app configuration; production remains fail-closed until the account-service HTTPS route is configured.

## 2026-10-06 — deploy Lollipop account authority on Synology
- Provisioned the existing PostgreSQL-backed `account-service` on the Synology with runtime-only database/session secrets.
- Verified PostgreSQL healthy, account service running on loopback `127.0.0.1:8091`, `/healthz` HTTP 200 and `/register` rendering.
- Updated account portal branding from EFIS to Lollipop/RedOne.
- Kept the account origin loopback-only; public phone registration requires the DSM HTTPS reverse-proxy boundary rather than exposing Docker port 8091.

## 2026-10-06 — validate public Lollipop account registration route
- DSM HTTPS reverse proxy on `granvillehouse.synology.me:8450` is live and forwards to the loopback-only account origin on `127.0.0.1:8091`.
- External validation returned HTTP 200 from `/healthz` with successful TLS certificate verification (`ssl_verify_result=0`).
- External `/register` validation confirmed the Lollipop Account page and Lollipop branding.
- The EFIS Service development build already targets `https://granvillehouse.synology.me:8450/register`; no client URL change was required.

## 2026-10-06 — require Lollipop email verification
- New Lollipop accounts remain unverified until the registered email address opens a single-use authentication link.
- Verification tokens are random, stored only as SHA-256 hashes, expire after 30 minutes by default, and are invalidated when a replacement is requested.
- Sign-in and portal sessions fail closed for unverified accounts.
- Added SMTP-configurable transactional delivery without coupling the account service to a hosted mail provider.

## 2026-10-06 — Lollipop persistent authentication and Android parity
- Added five-minute single-use QR/deep-link app login challenges and hard 90-day revocable mobile sessions.
- Added `/v1/me`, `/v1/logout` and reauthentication email support; server stores token hashes only.
- iOS Lollipop stores its session in Keychain and silently validates it after restart; QR login and restart persistence physically validated.
- Added Android Lollipop implementation with matching process catalogue, QR/deep-link login, Android Keystore-backed encrypted session persistence, `/v1/me` validation, expiry reauthentication and sign-out.
- Added Synology configuration runbook and Android build script.
- Root Synology rebuild now validates/rebuilds the account service as part of the repository stack.

## 2026-10-10 — EFIS A/B OTA and independent recovery design
- Documented dual-slot firmware, rollback, optional minimal factory recovery firmware, physical recovery entry and ROM USB service fallback.
- Recorded ESP32-S3 bootloader/flash and irreversible security-policy limitations, offline Lollipop recovery flow, and bench fault-injection acceptance criteria.
- No bootloader or partition-table firmware changes made at this checkpoint.
