# RedOne Licence Network Architecture and Disaster Recovery

## Purpose

This is the canonical design and rebuild reference for the current Synology-hosted RedOne licence path. Git is the source of truth for application, container and rebuild logic. Secrets and private keys are deliberately not stored in Git.

The phone normally uses the canonical public HTTPS Synology endpoint. On the hosting LAN, if the router cannot loop that public address back inside, the phone automatically falls back to an authenticated local gateway. No router configuration is required.

## Logical architecture

    iPhone EFIS Service App
       |-- normal --> granvillehouse.synology.me:8449 --> DSM reverse proxy --> 127.0.0.1:8093
       |
       `-- connectivity failure only
              --> mDNS _redone-license._tcp.local
              --> redone-license.local:9443
              --> pinned TLS identity
              --> redone-local-license-gateway
              --> allow-list /healthz and /api/phone/*
              --> 127.0.0.1:8093

The current 8093 broker is development architecture. The routing/trust pattern is independent of that implementation and can later point at the production phone API.

## iPhone route selection

LicenceViewModel always tries the configured canonical service first. Local fallback is attempted only for URLError connectivity failures; HTTP/application errors are not silently rerouted.

Before sending licence/account data locally, RedOneLocalGateway.isAvailable() calls /healthz through an ephemeral pinned-TLS URLSession. The local service is accepted only when redone-license.local resolves, TCP/TLS port 9443 succeeds, the leaf-certificate SHA-256 is compiled into the signed app, and /healthz identifies redone-local-gateway. Only then is the original phone API operation retried locally.

## Discovery

The gateway publishes service type _redone-license._tcp.local, instance RedOne Licence, port 9443, version 1, TLS name redone-license.local and server redone-license.local. The gateway derives the NAS LAN interface address dynamically. The NAS address is not hard-coded into the phone or gateway discovery design.

## Trust model

mDNS is untrusted discovery. A malicious LAN device can advertise the same service name. Authentication is therefore provided by a dedicated RedOne gateway TLS identity, not by discovery or subnet membership.

The private key exists only at /volume1/docker/redone-local-license-gateway/tls/tls.key. The app pins the SHA-256 digest of the gateway leaf certificate and cancels the TLS challenge if it does not match. There is no ATS bypass, hostname-ignore path, arbitrary self-signed trust, or trust based merely on being local.

The identity is deliberately separate from the DSM/public Let's Encrypt certificate, so DSM certificate renewal cannot break local fallback.

## Gateway isolation

The gateway runs in Docker with host networking for mDNS and the LAN listener, an unprivileged UID/GID, dropped capabilities, no-new-privileges and a read-only TLS mount. It exposes TCP 9443, proxies only /api/phone/*, provides /healthz, and returns 404 for all other paths. It does not expose DSM, Docker administration, signer or database endpoints.

## Repository components

- local-license-gateway/gateway.py: TLS proxy, API allow-list and mDNS advertisement.
- local-license-gateway/Dockerfile: reproducible Python/zeroconf image.
- local-license-gateway/compose.yml: runtime isolation and host networking.
- local-license-gateway/README.md: component summary.
- ios/EFISService/EFISService/LicenceService.swift: pinned TLS session and local gateway definition.
- ios/EFISService/EFISService/LicenceViewModel.swift: public-first fallback policy.
- scripts/rebuild-local-license-gateway.sh: recreates runtime files, identity if missing, image and container.
- scripts/test-local-license-gateway.sh: strict TLS, allow-list and account smoke test.
- scripts/rebuild-synology.sh: rebuild entry point for the Synology licence services and gateway.

## Fresh Synology rebuild

1. Restore or clone this repository to /volume1/docker/ESP32-EFIS.
2. Restore the persistent data/secrets required by the licence/simulator stack.
3. If available, restore the old local gateway TLS directory to /volume1/docker/redone-local-license-gateway/tls and keep tls.key mode 0600.
4. Run scripts/rebuild-synology.sh /volume1/docker/ESP32-EFIS.
5. If no gateway identity existed, the rebuild script creates one and prints its SHA-256 digest.
6. A newly generated identity is NOT automatically trusted by installed apps. Add the new digest to RedOneLocalGateway.certificatePins, build/sign a new app, and validate it before relying on local fallback.
7. Run scripts/test-local-license-gateway.sh and scripts/test-license-harness.sh.
8. Verify mDNS from another LAN machine.
9. Test a physical iPhone on the hosting Wi-Fi.
10. Test the same phone away from the hosting LAN/cellular to validate the public path independently.

On Synology:

    cd /volume1/docker/ESP32-EFIS
    ./scripts/rebuild-synology.sh
    REDONE_GATEWAY_HOST=<NAS-LAN-IP> ./scripts/test-local-license-gateway.sh
    ./scripts/test-license-harness.sh

On macOS, verify discovery with dns-sd -B _redone-license._tcp local. and dns-sd -L "RedOne Licence" _redone-license._tcp local. Do not use curl -k for acceptance testing.

## Certificate backup and rotation

Securely back up the gateway TLS directory outside Git. The private key must never be committed.

Normal rotation is overlap-first: generate a replacement identity; calculate its leaf SHA-256; release an app containing old and new pins; allow clients to update; replace the gateway identity; validate; then remove the old pin in a later app release.

If the NAS and all private-key backups are lost, generate a new identity. Existing apps containing only the old pin will correctly reject it and require an updated app. This fail-closed behaviour is intentional.

## Required backup set

In Git: source, Docker/Compose definitions, gateway, iOS routing/pinning, rebuild/test scripts, architecture and runbooks.

Secure backup outside Git: gateway TLS key/certificate, licence/account persistent database data, signing private keys, and service credentials/secrets. A backup is not considered valid until a restore test has been performed.

## Acceptance checklist

- gateway remains Up without restart loop;
- /healthz passes with strict TLS;
- / returns 404;
- /api/phone/account passes through gateway;
- mDNS advertises the non-loopback NAS address;
- wrong/unpinned TLS identity is rejected by the app;
- Debug and Release iOS builds pass;
- physical iPhone loads the account on hosting Wi-Fi without router/DNS changes;
- public route is independently tested away from the hosting LAN;
- no fixed NAS address exists in iOS production routing;
- no external tunnel or FRITZ!Box-specific feature is required.

## Current boundary

This makes the network route rebuildable and secure for the current Synology-only phase. It does not make the development licence backend production-ready; the gates in PRODUCTION-LICENCE-SERVICE.md still apply.

The current pin is a leaf-certificate pin. It is secure but couples certificate rotation to an app rollout. A future improvement may pin a stable dedicated gateway public key, provided it remains fail-closed and key custody/rotation are documented and tested.

## Xcode project recovery

The iOS Xcode project bundle is generated output, not source of truth. After a fresh clone or disaster recovery, install XcodeGen and run `./scripts/generate-xcode-projects.sh`. This regenerates both `ios/EFISService/EFISService.xcodeproj` and `simulator/ESP32EFISSimulator.xcodeproj` from their tracked `project.yml` files. Do not preserve or manually back up `.xcodeproj`, `xcuserdata` or `.xcuserstate` files; any setting required to reproduce the product must be represented in `project.yml` or another tracked source file.

### Docker container naming rule

All Docker Compose projects in this repository MUST use the Git repository name `esp32-efis` (the Docker-safe lowercase form of the Git repository name `ESP32-EFIS`) as the Compose project name. Do not set individual `container_name` values. Compose therefore generates container names beginning `esp32-efis-`, followed by the service name and replica number. This is a permanent repository convention and applies to all existing and future Compose stacks and rebuild/deployment scripts.
