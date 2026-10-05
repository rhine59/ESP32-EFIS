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
