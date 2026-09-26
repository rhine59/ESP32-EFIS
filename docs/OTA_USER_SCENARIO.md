# ESP32 EFIS — OTA user software scenario

**Status:** definitive interaction implemented in Swift simulation; physical ESP32 OTA remains pending.  
**Date:** 16 September 2026

## Definitive user model

Administrator publication and instrument activation are separate controls. A firmware binary is first **STAGED** on the Docker OTA server, then explicitly **PUBLISHED** by the administrator. Only the published manifest is consumable by EFIS units.

On the instrument, **Automatically download next update** defaults ON. This means discovery/download/verification may occur while the EFIS is deliberately in its maintenance/network-update context. It never means automatic activation or reboot.

```text
Admin: STAGE -> review -> PUBLISH
                         |
EFIS:              discover release
                    /          \
              auto download   manual Download
                    \          /
                  verified inactive slot
                         |
                 UPDATE READY
                         |
                 ACTIVATE & REBOOT
                         |
                  first-boot test
                    /       \
                  pass      fail
                   |          |
                 accept    rollback
```

## Simulator

`simulator/ESP32EFISSimulator/OTAFlowView.swift` implements this user-facing policy. The page is permanently labelled **OTA USER-FLOW SIMULATION** and performs no real networking, flash writes or reboot.

The maintenance page exposes the persistent auto-download preference. With it ON, checking a published update proceeds to simulated download and stops at **Update ready**. With it OFF, the user sees **Update available** and must select **Download**. Both paths converge on the same verified state:

```text
SOFTWARE UPDATE READY
Version <candidate>
Downloaded and verified

[ ACTIVATE & REBOOT ]
        Later
```

There is no auto-activation mode. Selecting **Later** leaves activation for a future maintenance session in the production design.

## Activation and rollback

`ACTIVATE & REBOOT` is the explicit boundary between having a verified dormant candidate and attempting to run it. The production ESP32 implementation will select the inactive OTA slot and reboot. The new image remains pending until mandatory first-boot self-test succeeds. Failure, crash or reset before confirmation must restore the previous known-good image.

The simulator's **Simulate first-boot failure** switch exercises the user-visible rollback path. This is behavioural simulation, not evidence that ESP-IDF rollback has been hardware validated.

## User-facing rules

- software update functions belong to maintenance, not normal flight operation;
- only an administrator-published release is offered;
- auto-download may fetch/verify a candidate but may not activate it;
- manual mode requires Download;
- activation always requires local **ACTIVATE & REBOOT**;
- current software remains recoverable while writing the inactive slot;
- no normal-looking flight page is presented while first-boot verification is incomplete;
- failure explicitly reports restoration of previous known-good software;
- no synthetic sensor value may become a fallback flight-data source.

## Relationship to Docker OTA server

The private Docker admin UI owns staging/publishing. The public nginx origin exposes only the current manifest and versioned binaries. A new upload is invisible to EFIS units until Publish is deliberately selected. Republish of a retained older release provides administrative withdrawal/rollback of what is advertised.

## Validation status

**IMPLEMENTED — SWIFT USER-FLOW SIMULATION / NOT PHYSICAL OTA VALIDATION.** Still required are the real A/B partition table, maintenance Wi-Fi, HTTPS client, manifest parser, OTA writer, signed-image verification, boot-slot selection, pending-verify self-test, mark-valid/rollback calls, interruption testing and USB recovery testing.

## Running the simulator

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
cd simulator
xcodegen generate
open ESP32EFISSimulator.xcodeproj
```

Exercise: auto-download ON success, auto-download OFF/manual Download, `Later`, successful Activate & Reboot, and simulated first-boot failure/rollback. Repository implementation is not by itself an Xcode compile/runtime validation claim.


## Boot-time Wi-Fi connection dialog

When boot offers **Check for update**, the update path must include an explicit Wi-Fi connection dialog before any network request. The EFIS must not silently enable/reconnect Wi-Fi during normal instrument operation.

Recommended boot/update sequence:

```text
EFIS BOOT
   |
   +-- Start EFIS
   +-- Full electrical test
   +-- Check for firmware update
             |
             v
       WI-FI CONNECTION
       Saved network: <SSID>       [Connect]
       Scan for networks           [Scan]
       Enter network manually      [Manual]
       Forget saved network        [Forget]
       Cancel / Continue without update
             |
             v
       CONNECTING...
       Wi-Fi -> DNS/Internet -> TLS -> OTA server
             |
          success?
          /    \
        no      yes
        |        |
   show fault   CHECK FOR UPDATE
   + Retry          |
   + Change Wi-Fi   +-- Up to date -> Start EFIS
   + Start EFIS     +-- Update available
                             |
                         Download
                             |
                    verify inactive slot
                             |
                    ACTIVATE & REBOOT
```

The dialog shall support an iPhone Personal Hotspot and ordinary WPA2/WPA3 Personal networks supported by the ESP32. It should show SSID and connection state but never display a stored password after entry. Credentials may be stored in NVS only after deliberate connection/save behaviour and must never be logged or sent to the OTA server.

Failure must be recoverable: inability to establish Wi-Fi, Internet, TLS or OTA-server connectivity must **not prevent the existing known-good EFIS firmware from starting**. The dialog should identify the failed layer and offer **Retry**, **Change Wi-Fi**, and **Start EFIS**.

Firmware activation remains separate from networking. A successful Wi-Fi connection only permits Check/Download; a verified candidate still requires the explicit local **ACTIVATE & REBOOT** action.
