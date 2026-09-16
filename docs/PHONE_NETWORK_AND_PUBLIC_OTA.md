# ESP32 EFIS — phone network pairing and public OTA access

**Status:** user workflow and simulator implemented; physical ESP32 Wi-Fi client and public Synology deployment not yet validated  
**Date:** 16 September 2026

## Purpose

Provide the ESP32 EFIS with a temporary Internet path for maintenance without adding a cellular modem to the instrument. The intended field path is:

```text
ESP32 EFIS
  │ Wi-Fi station mode
  ▼
iPhone Personal Hotspot
  │ cellular / Internet
  ▼
public DNS
  │ HTTPS :443
  ▼
Synology reverse proxy + valid TLS certificate
  │ HTTP on NAS loopback only
  ▼
127.0.0.1:8080
  │
  ▼
esp32-efis-ota nginx container
  ├── /healthz
  ├── /efis/manifest.json
  └── /efis/releases/<version>/esp32-efis-<version>.bin
```

The phone is a network gateway, not an OTA controller. The EFIS itself retrieves the manifest and firmware over HTTPS after the user explicitly enters maintenance/update mode. No automatic installation is permitted merely because the hotspot becomes available.

## Instrument connection configuration

The physical 480×480 instrument must provide a maintenance-only **Network Connection** dialog. It is not shown during normal flight display operation.

Recommended top-level sequence:

```text
MAINTENANCE
  └── NETWORK CONNECTION
        ├── Phone hotspot
        ├── Update server
        ├── Test connection
        ├── Save
        └── Forget network
```

### Phone hotspot page

The user enables Personal Hotspot on the iPhone, then the EFIS scans for Wi-Fi networks. The rotary encoder selects the phone SSID. The password is entered with a rotary character editor: rotate to choose a character, press to accept, long-press for back/delete, and select DONE to finish. Password characters are masked by default with a temporary reveal option.

The final instrument presentation should be compact and explicit:

```text
NETWORK CONNECTION

Phone hotspot
  SSID      Richard’s iPhone
  Password  ••••••••••••

Update server
  efis-updates.example.net

[ TEST ]     [ SAVE ]

Wi-Fi: OFF / CONNECTING / CONNECTED
Server: NOT TESTED / REACHABLE / FAILED
```

The simulator implements the same logical fields using native text entry because it is intended to test the workflow rather than emulate rotary text entry.

### Configuration stored on the EFIS

Production firmware should persist in NVS:

- hotspot SSID;
- hotspot password;
- OTA manifest HTTPS URL or approved hostname/profile;
- configuration schema version.

The password must never be logged, rendered unmasked by default, included in diagnostics, committed to Git, placed in the OTA manifest, or sent to the OTA server. A **Forget Phone Configuration** action must erase the stored SSID/password.

For the first hardware implementation, use WPA2/WPA3 Personal as supported by ESP-IDF and the selected iPhone hotspot mode. Do not support open Wi-Fi for OTA maintenance.

## Connection test

`TEST` is deliberately separate from `SAVE` and from `INSTALL`.

The production test should report each layer separately:

1. **Phone** — ESP32 associates with the configured hotspot and receives an IP address.
2. **Internet/DNS** — DNS for the configured OTA hostname resolves.
3. **TLS** — HTTPS connection validates the server certificate chain and hostname.
4. **OTA server** — `/healthz` returns success and the manifest endpoint returns syntactically valid metadata for `ESP32-EFIS`.

A failed test must identify the failing layer without exposing secrets. Typical messages are `PHONE NOT FOUND`, `HOTSPOT PASSWORD REJECTED`, `NO INTERNET`, `DNS FAILED`, `TLS CERTIFICATE FAILED`, `SERVER UNREACHABLE`, and `INVALID MANIFEST`.

The test must not download or install firmware.

## Maintenance-only Wi-Fi policy

Wi-Fi is normally OFF. It may be enabled only after explicit entry into maintenance/network/update mode. Leaving maintenance mode stops Wi-Fi unless an update is already in a protected transfer/verification state. The EFIS must not silently reconnect to the phone during normal instrument operation.

A lost phone/cellular connection during download is handled as a failed transfer to the inactive OTA slot; the currently running known-good application remains untouched. A completed image is not selected for boot until all transport/image checks pass.

## Public Synology OTA endpoint

The OTA origin container is intentionally not public itself. `ota-server/compose.yml` binds nginx to:

```text
127.0.0.1:8080:8080
```

Only the Synology reverse proxy should expose the service.

### Required public infrastructure

1. Own/control a DNS hostname, for example `efis-updates.example.net`.
2. Create a public DNS A/AAAA record pointing to the Internet-facing address used by the Synology site.
3. Obtain a valid TLS certificate for that exact hostname in DSM (Let's Encrypt or another trusted CA).
4. In DSM **Control Panel → Login Portal → Advanced → Reverse Proxy**, create:
   - source protocol: `HTTPS`
   - source hostname: `efis-updates.example.net`
   - source port: `443`
   - destination protocol: `HTTP`
   - destination hostname: `127.0.0.1`
   - destination port: `8080`
5. Attach the hostname's TLS certificate to the reverse-proxy virtual host.
6. Router/firewall: allow/forward TCP 443 to the Synology HTTPS service as appropriate for the installation. **Do not expose or forward 8080.**
7. Keep DSM administration ports and Docker management interfaces out of this public path.

If the ISP uses CGNAT or inbound 443 cannot be forwarded, use a deliberately configured HTTPS tunnel/reverse-proxy service instead. The security invariant remains the same: the device sees a stable trusted HTTPS hostname, while the container itself has no public management interface.

### External validation

Test from a device that is **not on the home LAN** (for example a phone using cellular with Wi-Fi disabled):

```bash
curl -fsS https://efis-updates.example.net/healthz
curl -fsS https://efis-updates.example.net/efis/manifest.json
curl -fI https://efis-updates.example.net/efis/releases/0.4.1/esp32-efis-0.4.1.bin
```

Also verify that `http://PUBLIC-IP:8080` is not reachable from the Internet.

## Public versus private firmware files

The initial distribution service is read-only and can safely be designed so manifest and approved firmware binaries are publicly downloadable. Public readability is not the trust mechanism. The production trust chain must be HTTPS certificate validation plus signed application-image verification on the EFIS. Knowledge of the URL must never be treated as proof that an image is genuine.

If private download authorization is added later, use short-lived/device-scoped credentials. Never embed a GitHub personal access token or signing private key in the EFIS.

## Simulator implementation

`simulator/ESP32EFISSimulator/NetworkSetupView.swift` now provides a software model of:

- hotspot SSID/password configuration;
- masked/reveal password UI;
- HTTPS manifest URL;
- staged Phone → Internet → OTA Server test;
- Save and Forget actions;
- persistent simulator configuration using `@AppStorage`;
- unmistakable simulator-only warning.

The simulator intentionally performs no real Wi-Fi association or HTTP request. It validates the user interaction and state model only.

## Production firmware implementation boundary

Physical firmware still needs `maintenance_wifi.c/.h` (or equivalent) to implement ESP-IDF station-mode scanning/association, NVS credential storage, connection-state reporting and shutdown on leaving maintenance mode. OTA HTTPS remains the responsibility of the update manager described in `REMOTE_UPDATES.md`.

The network module must expose state to the UI and updater but must not alter attitude, altitude or heading validity. Loss of Internet connectivity is an update/maintenance fault, not a flight-data source.

## Validation status

**USER WORKFLOW IMPLEMENTED IN SWIFT SIMULATOR / NETWORK ARCHITECTURE DOCUMENTED / PHYSICAL NETWORKING NOT IMPLEMENTED OR VALIDATED.**

Before this can be marked operational, validate on real ESP32-S3 hardware with an actual iPhone hotspot, cellular Internet, public DNS/TLS endpoint, hotspot loss, cellular loss, wrong password, TLS failure, DNS failure, server outage, power interruption and recovery. Public Synology exposure must also be externally tested from outside the LAN.
