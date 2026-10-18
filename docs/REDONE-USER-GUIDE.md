# Lollipop Design RedOne — User Guide

**Edition:** 18 October 2026 · **Audience:** owners, pilots, installers and support staff · **Status:** development reference, not a released product manual.

> **Flight safety:** RedOne is an experimental, supplementary, non-certified electronic flight instrument. Never use it as the sole source of attitude, altitude, heading or navigation information. A successful software test, green status or diagnostic PASS does not establish airworthiness. Follow aircraft operating limitations and maintain independent approved/appropriate instruments.

## Contents
1. [What RedOne does](#1-what-redone-does)
2. [What you need](#2-what-you-need)
3. [First-time setup](#3-first-time-setup)
4. [Connect your phone](#4-connect-your-phone)
5. [Understand the Lollipop app](#5-understand-the-lollipop-app)
6. [Accounts and ownership](#6-accounts-and-ownership)
7. [Licensing](#7-licensing)
8. [Instrument operation](#8-instrument-operation)
9. [Firmware management](#9-firmware-management)
10. [Diagnostics](#10-diagnostics)
11. [Troubleshooting](#11-troubleshooting)
12. [Data, security and privacy](#12-data-security-and-privacy)
13. [Support and service](#13-support-and-service)
14. [Current availability](#14-current-availability)

## 1. What RedOne does

RedOne is Lollipop Design's proposed compact EFIS: a single 2.1-inch circular 480 × 480 display presenting selectable **Horizon/PFD**, **Altimeter** and **Compass** pages. It is not three separate displays. A rotary/push control is the intended physical interface. Proposed inputs include BMI088 attitude sensing, BMP585 static pressure, RM3100 magnetic heading and GNSS position/accuracy. GNSS ground track (TRK) must not be confused with magnetic heading (HDG); ground speed is not indicated airspeed. Missing or stale data must be shown as invalid rather than frozen as believable readings.

The companion **Lollipop** app is intended for account/device ownership, licences, connection, firmware, commissioning and diagnostics. Some processes are implemented or simulated; do not interpret a visible menu as proof the corresponding physical operation is available.

## 2. What you need

For bench use: a provisioned RedOne ESP32-S3 test unit, a charged iPhone running the Lollipop development app, and the device's own Wi-Fi connection information. A suitable internet connection is required to obtain a published firmware release; RedOne's local Wi-Fi does not itself provide internet. Production packaging, hardware controls and customer onboarding are not yet validated. Do not fit or rely on an unfinished bench assembly in an aircraft.

## 3. First-time setup

1. Power the bench device using the approved development power arrangement. Do not connect unknown aircraft power or sensor wiring.
2. Open Lollipop and select the guided **Set up a new EFIS** workflow where available.
3. Identify the device and authenticate or create the owner account using the account workflow. Account verification and reset availability depend on the deployed service; do not assume an offline login is a new account registration.
4. Check device ownership and licence entitlement. The product design includes a first year of licence service, activated once for that device; this is an entitlement rule, not a promise that commercial activation is currently live.
5. Connect to RedOne, read device status and complete only the steps confirmed as available. A screen marked pending, unavailable or simulated is not complete.
6. Commission sensors, controls and display only against the physical test procedure once hardware is assembled and validated.

## 4. Connect your phone

The bench access point uses the pattern `RedOne_<MACADDRESS>`; the current test example is `RedOne_3C0F02D61FDD`. The actual identifier differs by device. In Lollipop, open **Connection**, use the QR or saved-device path if shown, and join the RedOne network. iOS may display its own Wi-Fi join permission dialog. Return to Lollipop and use **Verify connection** or **Read EFIS status** to confirm that the app is actually talking to RedOne. Merely seeing the Wi-Fi network or receiving a join-request acknowledgement does not prove device authentication.

The current bench status service is `http://192.168.4.1/status` on the RedOne Wi-Fi network, authenticated with a provisioned token held in iOS Keychain. This address is a bench implementation detail, not a permanent production public endpoint. A future product-box QR workflow is a **planned feature**, not a guaranteed production capability. Saved Wi-Fi details are device-specific; if the network has changed, use the reconnect/new-device path.

## 5. Understand the Lollipop app

The preferred interface is **process-led**: choose the outcome, read **What to do next**, then tap the active step or its instruction. Status colours mean:

| Colour | Meaning | Your action |
|---|---|---|
| Green | Positively confirmed complete | Continue |
| Blue | Current actionable step | Tap to proceed |
| Grey | Not yet available | Complete prerequisites |
| Amber | Waiting or attention needed | Review instruction, retry/refresh if offered |
| Red | Failed or blocked | Correct the cause before continuing |

An action must be confirmed by the device or service; opening a screen does not complete a step. Keep **Connection**, firmware management and diagnostic results in their own groups. Low-level manual controls belong under **Advanced**, not in the normal guided workflow. App layouts and feature parity across iOS and Android are development goals; the iOS bench workflow is the best-validated phone path at this checkpoint.

## 6. Accounts and ownership

The intended flows are **register/verify account**, **sign in**, **recover access**, **register RedOne**, **reassign/sell RedOne**, and **accept a transferred RedOne**. Ownership changes require an authenticated server-side acceptance and audit record; a phone-local email match is not sufficient. Some transfer journeys currently have development-simulator behaviour. Do not hand over a device on the assumption that a simulated transfer has changed the real account owner. Account passwords should never be entered into RedOne's local diagnostic HTTP interface.

## 7. Licensing

The architecture uses signed, device-bound licences with offline verification on RedOne. A new device is intended to include its first year, starting at first activation. A later transfer should preserve the remaining term without granting a second free year. Lollipop should check an existing or included entitlement before offering payment. The app can display licence state, retrieve a signed entitlement and guide installation where supported. **Do not treat an app-side cached licence as installed** until RedOne explicitly confirms `VALID`. Licensing must not suppress basic safety/failure indications.

## 8. Instrument operation

The proposed rotary/push boot menu defaults to **START EFIS** and includes maintenance/diagnostic functions such as **FULL TEST**, **FIRMWARE UPDATE**, **LICENSE** and **FAULT LOG** as these are implemented. Rotate to select a page or menu item and press to confirm; exact encoder gestures remain subject to hardware validation. Horizon displays attitude, Altimeter uses static pressure and adjustable QNH, and Compass displays magnetic heading separately from GNSS track. GNSS latitude/longitude and receiver-reported horizontal accuracy are planned on Horizon and Compass; no fix/stale/invalid data must be visibly unavailable. Receiver accuracy colours are informational estimates, not integrity guarantees. **No airspeed indicator is provided.**

Before any future flight evaluation, verify installation, sensor orientation, static-pressure connection, QNH, magnetic calibration, readable display, power behaviour, error indications and independent backup instruments using a documented ground-test checklist. Do not conduct in-flight reliance testing on unvalidated firmware.

## 9. Firmware management

**Current rule: Push, Activate and Rollback are disabled. Do not attempt to bypass them.**

The intended safe workflow is:

1. **Download a signed release first** while the phone has internet access. Retain the verified signed envelope with the firmware binary for offline transfer near the aircraft.
2. **Connect to RedOne** over its local Wi-Fi, preferably using the remembered connection, and verify device identity and current firmware/partition status.
3. **Preflight checks:** product/hardware compatibility, pinned publisher signature, complete image SHA-256, permitted build version, suitable inactive OTA slot and maintenance safety prerequisites.
4. **Transfer to inactive Partition A or B**, without overwriting the running image or factory recovery. Show progress, errors and retry state.
5. **Verify stored image**, including flash readback; then request explicit on-ground activation. No activation merely because upload finished.
6. **Reboot and check health** before marking the new image valid; retain a rollback route if the new image fails.

Steps 4–6 describe the **target design**, not presently available phone actions. The current firmware includes read-only signature/hash/preflight endpoints and compiled experimental staging code that is **not routable**. The bench `/update`, `/verify`, `/activate` endpoints deliberately reject writes/activation. Never use generic `idf.py flash` on the provisioned device; it can overwrite recovery, NVS and partition layout. Physical power-loss/rollback acceptance is still outstanding.

## 10. Diagnostics

Use **Read diagnostics from RedOne** for results, rather than assuming a firmware-status screen is a diagnostic report. Results are reported as PASS, FAIL, SKIP or TODO and should include what was tested and why a test was skipped. Available read-only checks may include flash/heap capacity, Wi-Fi state and partition inventory. External sensors, display, power ADC and CAN require an assembled, verified carrier and are not automatically tested merely because the app shows them. A green PASS describes only that specific measurement; it is not a certificate of flightworthiness. Keep diagnostic tests separate from firmware management.

## 11. Troubleshooting

| Symptom | Check / safe response |
|---|---|
| RedOne network not visible | Confirm bench power and firmware boot; inspect USB logs without resetting NVS |
| iPhone joined Wi-Fi but app cannot verify | Reopen Connection, confirm Wi-Fi network, retry status/authenticated read |
| Status says `pending_verify` | Do not force activation or manually mark valid; preserve rollback evidence |
| Firmware Push disabled | Expected: security and hardware acceptance gates are not complete |
| Signed release rejected | Check correct product/hardware, trusted publisher, intact signed manifest and exact image hash; never disable verification |
| Licence not active | Distinguish account entitlement, phone cache and device-confirmed installed licence |
| Diagnostics show SKIP | Hardware/interface may be absent or not validated; SKIP is not PASS |
| Sensor value missing/stale | Treat indication as unavailable and use independent instrumentation |
| Phone has no internet on RedOne Wi-Fi | Download the release before joining RedOne; use internet network for publisher access |

## 12. Data, security and privacy

Keep account passwords in the account sign-in process, not in support logs. iOS credentials/tokens belong in Keychain (Android equivalents in secure OS-backed storage). Do not publish Wi-Fi passwords, API tokens, signing private keys, licence secrets or device backups in GitHub issues or screenshots. The publisher private signing key must remain off the EFIS and outside the public web tier. Do not share precise aircraft location or registration/ownership information unless necessary and authorised.

## 13. Support and service

Record the device identifier, firmware version, running partition, boot state, time, exact failed step and non-secret diagnostic results. Do not send passwords, API tokens or complete flash dumps to general support. For a fault involving power, firmware, display or sensors, stop relying on the instrument and follow the approved bench/service procedure. The support-service design and reviewed Q&A process are described in `docs/SUPPORT_SERVICE.md`.

## 14. Current availability

As of 18 October 2026: iOS connection/status and several account/licence workflows have development implementations; hardware/display/sensor commissioning and many customer processes are not production-validated. OTA signature verification, read-only preflight, staging guards, inactive-slot adapter and anti-downgrade policy exist in source, but **staging is not exposed**, the persistent downgrade floor is not implemented, boot-health confirmation is incomplete, and physical power-loss testing is pending. Consult `docs/PROJECT_STATUS.md`, `docs/REDONE_OTA_RELEASE_READINESS.md`, and `hardware/boot-recovery-lab/SECURE-OTA-GATE.md` for checkpoint evidence.

---

**Related references:** `docs/user-guides/`, `docs/PROCESS_WORKFLOW_ARCHITECTURE.md`, `docs/PHONE_LOCAL_FIRMWARE_MANAGEMENT.md`, `docs/REDONE-RECOVERY-DIAGNOSTICS.md`, `docs/OTA_USER_SCENARIO.md`, `docs/LICENSING.md`, `docs/SAFETY.md`.
