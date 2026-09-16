# ESP32 EFIS — OTA user software scenario

**Status:** interactive user-flow simulation implemented in Swift; ESP32 network/flash OTA remains unimplemented and hardware validation remains pending.  
**Date:** 16 September 2026

## Purpose

Define and exercise exactly what the user sees and controls when updating ESP32 EFIS software. OTA is a maintenance function, never an automatic flight-time action. The user must explicitly check, review and confirm an update.

## Implemented simulator

`simulator/ESP32EFISSimulator/OTAFlowView.swift` implements the complete proposed interaction as a deterministic SwiftUI state machine. The simulator app now has two tabs: **Instruments** and **Software Update**. The OTA page is permanently marked **OTA USER-FLOW SIMULATION** and performs no network request, flash write or device reboot.

The simulated release is current `0.4.0` → candidate `0.4.1`, hardware profile `s3-n16r2-v1`, from the HTTPS OTA server. These are UI fixtures, not a released firmware claim.

## Normal user path

```text
Maintenance
  ↓ user: Check for Update
Checking manifest/compatibility
  ↓
Update available
  ↓ user: Review Update
Confirm installation
  ↓ user: Install
Downloading to inactive slot
  ↓
Verifying complete image
  ↓
Restarting into candidate
  ↓
First-boot self-test / pending verification
  ↓ pass
Update complete / candidate becomes known-good
```

The user may choose **Not Now** before review or **Cancel** before installation. Once simulated download begins, the UI deliberately removes casual cancel controls: the real implementation must handle interruption safely through A/B OTA rather than encouraging power-off during a flash operation.

## Rollback path

The simulator includes **Simulate first-boot failure**. When enabled before installation, the same download and verification path runs, but first-boot verification fails:

```text
Candidate pending verification
  ↓ self-test failure
Restoring previous software
  ↓
Previous software restored
```

The installed version remains `0.4.0`. This represents the required ESP-IDF A/B rollback behavior; it does not claim that physical rollback has been tested.

## User-facing rules

The production 480×480 maintenance UI should preserve these rules even if its visual layout differs from the iPhone/iPad simulator:

- software update is entered deliberately from maintenance/settings;
- checking for an update never installs it;
- current and available versions are visible before confirmation;
- compatibility is checked before Install is offered;
- Install requires an explicit local action;
- download clearly says the current firmware remains recoverable;
- verification and restart are unmistakable states;
- first boot is not presented as successful until self-test confirmation completes;
- rollback explicitly reports that the previous known-good software is being/restored;
- no normal-looking flight page is shown while update verification is incomplete;
- no synthetic sensor data is used as a fallback during OTA.

## Relationship to the OTA server

The previously implemented `ota-server/` provides the proposed static HTTPS distribution origin. The real ESP32 client will eventually retrieve `/efis/manifest.json`, validate product/hardware/version metadata, download the versioned `.bin` to the inactive OTA slot and verify the image. The Swift simulation does not contact that server yet.

## Validation status

**IMPLEMENTED — SWIFT USER-FLOW SIMULATION / NOT ESP32 OTA VALIDATION.**

What can now be reviewed without hardware: wording, state ordering, explicit confirmation, progress presentation, successful-install path and rollback/failure communication.

Still required before field use: ESP32 A/B partition table, maintenance Wi-Fi, HTTPS manifest client, compatibility parser, OTA writer, image/signature verification, boot-slot selection, `ESP_OTA_IMG_PENDING_VERIFY` handling, application self-test, mark-valid/mark-invalid calls, real interruption testing and USB recovery testing.

## Running it

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
cd simulator
xcodegen generate
open ESP32EFISSimulator.xcodeproj
```

Run on an iPhone or iPad simulator and select **Software Update**. Exercise both the normal path and the first-boot-failure path.

## Acceptance criteria for this stage

The software-only user scenario is acceptable when both paths can be completed without ambiguous state changes; no installation occurs without explicit confirmation; rollback retains the previous version; and every page remains clearly identified as simulation. Xcode compilation/runtime review is still required after this commit; repository implementation alone is not a compile-validation claim.
