# Horizon EFIS Web Simulator

Containerised browser emulator for the Horizon boot/maintenance menus. Its purpose is to exercise OTA firmware and licensing services without physical ESP32 hardware.

## Scope

The simulator mirrors the rotary/push boot UX and uses a synthetic device identity. It deliberately does **not** emulate flight sensors or claim to validate flight firmware.

Current menu:

- START EFIS
- FULL TEST
- FAULT LOG
- LICENSE
- FIRMWARE UPDATE

LICENSE exercises status/install/reset flows. FIRMWARE UPDATE exercises Wi-Fi state, manifest checking, download, staged firmware and explicit ACTIVATE & REBOOT. A test panel can inject network/device states and inspect the event log.

## Run

```sh
docker compose up --build
```

Open `http://localhost:8093`.

## Service integration

Browser calls the simulator backend only. Configure upstream service URLs in Compose/environment; do not put admin/signing credentials in browser JavaScript.

- `OTA_BASE_URL`: public OTA origin. Manifest endpoint defaults to `/efis/manifest.json`.
- `LICENSE_BASE_URL`: customer/device licence service base URL. API paths are intentionally adapters/placeholders until the account/licence service contract is frozen.
- `SIM_ALLOW_MUTATIONS`: keep false against production services.

Default mode is safe mock mode and works without either upstream.

## Controls

Use the on-screen rotary buttons or keyboard: Up/Down = rotate, Enter = short press, Escape = back. State persists in the container only as test state and may be reset.

## Safety

Never configure the simulator with the private licence signing key, signer token, OTA admin session secret, payment secrets or real aircraft credentials. It is a client/service test harness, not an admin control plane.


## Multi-node offline OTA simulation

The simulator now exposes Horizon and EIU installed versions, release-set caching, local maintenance-network state, transfer/staging and dependency-ordered activation. The default mock release demonstrates EIU 1.7 -> 1.9 before Horizon 2.4 -> 2.5, with Horizon checking the required EIU capability before completing its own activation.

This models control flow only. It is not evidence of physical Wi-Fi, flash, A/B boot or CAN behaviour.


## Health check

The Compose service has a Docker health check against the simulator's internal `/api/state` endpoint. After startup, `docker compose ps` should report `(healthy)`. The check runs inside the container and does not depend on the Synology host-port assignment.


## Real OTA integration

When `OTA_BASE_URL` is set, firmware testing uses the real public OTA service rather than a synthetic manifest. The simulator requires maintenance Wi-Fi to be set online, retrieves `/efis/manifest.json`, validates the product and required fields, rejects the repository's unpublished CHANGE-ME/REPLACE placeholder, downloads the referenced firmware image, calculates SHA-256 over the received bytes, and refuses staging if the digest differs from the manifest. Only a verified cached image can be staged; activation remains a separate explicit action.

This path is intentionally read-only against the OTA server: it consumes the same public manifest/image interface as Horizon and does not need the OTA admin secret. A real release must be published before the live path can complete successfully.

For Synology deployment, set `OTA_BASE_URL` to an address reachable **from inside the simulator container**. Do not assume the NAS public hostname will hairpin back through the router; verify reachability from the container before relying on it.
