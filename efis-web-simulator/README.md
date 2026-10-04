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
