# ESP32 EFIS — phone network pairing and public OTA access

**Status:** workflow/simulator implemented; physical ESP32 Wi-Fi and public Synology deployment unvalidated  
**Date:** 16 September 2026

## Network path

```text
ESP32 EFIS --Wi-Fi--> iPhone Personal Hotspot --cellular--> Internet
   -> public HTTPS :443 -> Synology TLS reverse proxy -> 127.0.0.1:8080 -> read-only OTA nginx
```

The phone is only a network gateway. It does not receive/flash firmware. The private OTA administrator is a separate service on `127.0.0.1:8090` and is never part of the EFIS device path.

## Instrument connection configuration

The physical 480×480 maintenance UI provides **Network Connection** with hotspot SSID, masked password, HTTPS update-server profile/manifest URL, Test, Save and Forget. The production rotary encoder will provide character entry; Swift uses native text entry to test workflow.

Persist in NVS: SSID, password, approved manifest URL/profile and schema version. Password must never be logged, included in diagnostics/manifest, committed, sent to OTA server or shown unmasked by default. Forget erases stored credentials. Support secured WPA2/WPA3 Personal as available; do not use open Wi-Fi for OTA.

## Connection test

Test is separate from Save, Download and Activate. Report layers independently: phone association/IP, Internet/DNS, TLS certificate/hostname validation, and OTA `/healthz` + syntactically compatible manifest. Failure messages must identify the layer without exposing credentials.

The Test action itself never downloads or activates firmware.

## Maintenance/network policy

Wi-Fi remains maintenance-oriented and normally off during flight presentation. Entering the network/update maintenance context permits association and, if the user preference **Automatically download next update** is ON, discovery/download/verification of the administrator-published release.

This is the only intended automatic OTA activity. **Auto-download never selects the boot partition, activates firmware or reboots the EFIS.** A completed candidate remains dormant until local `ACTIVATE & REBOOT`.

With auto-download OFF, the user explicitly selects Download. Loss of hotspot/cellular service during transfer leaves the running known-good application untouched and the incomplete inactive-slot candidate unusable.

## Public Synology endpoint

`ota-server/compose.yml` binds nginx to NAS loopback `127.0.0.1:8080`. Create a public DNS hostname (for example `efis-updates.example.net`), a valid TLS certificate, and a DSM HTTPS :443 reverse proxy to `http://127.0.0.1:8080`. Router/firewall exposes only TCP 443 where inbound hosting is possible. Never expose 8080, 8090, DSM admin or Docker management.

If behind CGNAT, use a deliberately configured trusted HTTPS tunnel/reverse proxy while preserving the stable trusted device-facing hostname.

External test from outside the LAN:

```bash
curl -fsS https://efis-updates.example.net/healthz
curl -fsS https://efis-updates.example.net/efis/manifest.json
```

Also verify public `:8080` and `:8090` are unreachable.

## Public versus private

Published manifest/binaries may be publicly readable. URL secrecy is not trust. Production trust is TLS certificate validation plus signed application verification. Never embed GitHub PATs or signing private keys in the EFIS. Private admin access should use LAN/VPN/SSH or a properly authenticated private reverse proxy.

## Simulator

`NetworkSetupView.swift` models SSID/password, password masking, manifest URL, staged Phone → Internet → OTA Server test, Save/Forget and persistence. `OTAFlowView.swift` separately models auto/manual download and explicit activation. Neither performs real networking/flashing.

## Physical implementation boundary

ESP32 firmware still requires maintenance Wi-Fi station scanning/association, NVS credential storage, connection reporting/shutdown, HTTPS manifest/download handling and integration with the A/B update manager. Network state must never alter attitude/altitude/heading validity.

## Validation

**SWIFT WORKFLOW IMPLEMENTED / PHYSICAL NETWORKING AND PUBLIC DEPLOYMENT UNVALIDATED.** Bench validation requires real ESP32-S3 + iPhone hotspot + cellular Internet + public DNS/TLS, plus wrong password, hotspot/cellular loss, DNS/TLS/server failure, interrupted downloads and recovery. See `OTA_USER_SCENARIO.md`, `OTA_IMAGE_ADMIN.md` and `REMOTE_UPDATES.md`.
