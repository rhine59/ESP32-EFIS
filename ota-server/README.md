# ESP32 EFIS OTA image server

This directory provides the **distribution** side of the ESP32 EFIS remote-update design. GitHub remains the authoritative source/release history; this container serves only deliberately published firmware images and the device-facing manifest.

It is intentionally a static HTTP origin built on nginx. **TLS is expected to terminate at the Synology reverse proxy (or another trusted HTTPS proxy). Do not expose port 8080 directly to the Internet and do not configure the ESP32 to use plain HTTP for production OTA.**

## Layout

```text
ota-server/
├── Dockerfile
├── compose.yml
├── nginx.conf
├── public/
│   └── efis/
│       ├── manifest.json
│       └── releases/
└── scripts/
    └── publish-release.sh
```

The Compose deployment bind-mounts `public/` read-only, so approved images can be published without rebuilding the container. The manifest is `no-store`; versioned `.bin` files are immutable/cacheable. Directory listing is disabled.

## Synology deployment

On the NAS, clone/pull the repository into a persistent project directory, then:

```bash
cd ESP32-EFIS/ota-server
docker compose build
docker compose up -d
docker compose ps
curl http://127.0.0.1:8080/healthz
curl http://127.0.0.1:8080/efis/manifest.json
```

The container listens on host port 8080. In DSM **Control Panel → Login Portal → Advanced → Reverse Proxy**, create an HTTPS reverse proxy from a dedicated hostname such as `efis-updates.your-domain.example` to `http://127.0.0.1:8080`. Attach a valid TLS certificate to that hostname. Firewall/router policy should expose HTTPS 443 only if updates are required outside the LAN; port 8080 remains an internal origin.

The ESP32 firmware will eventually be configured with the stable HTTPS URL:

```text
https://efis-updates.your-domain.example/efis/manifest.json
```

## Publishing an approved image

After building and approving a release, publish the ESP-IDF application binary with:

```bash
cd ota-server
./scripts/publish-release.sh 0.4.1 47 ../firmware/build/esp32_efis.bin https://efis-updates.your-domain.example
```

The script copies the binary to a versioned path, calculates SHA-256, and atomically replaces the manifest content through shell redirection. Review both the generated manifest and hash before deployment/commit. The source firmware build and release approval remain separate from this hosting step.

Test it from another machine:

```bash
curl -fsS https://efis-updates.your-domain.example/healthz
curl -fsS https://efis-updates.your-domain.example/efis/manifest.json
curl -fI https://efis-updates.your-domain.example/efis/releases/0.4.1/esp32-efis-0.4.1.bin
```

## Diagnostics

```bash
docker compose ps
docker compose logs --tail=100 efis-ota
docker compose logs -f efis-ota
docker inspect --format='{{json .State.Health}}' esp32-efis-ota
curl -v http://127.0.0.1:8080/healthz
```

If HTTPS works externally but the container health check fails, diagnose the container/origin. If local HTTP works but HTTPS fails, diagnose Synology reverse proxy, DNS, certificate and firewall configuration.

## Security and safety

This server is deliberately **read-only from the network**: there is no upload API, web administration interface or repository credential in the container. Releases are copied in through the filesystem/deployment process. Do not put GitHub tokens, signing private keys or Wi-Fi credentials in this image.

SHA-256 protects against corruption but does **not** prove publisher identity. The planned EFIS production design additionally requires signed application images; the private signing key must remain outside this repository/server image. HTTPS certificate validation and signed-image verification are separate protections.

A release becoming available on this server must never cause unattended installation. The EFIS OTA client remains an explicit maintenance-mode function with A/B rollback and first-boot confirmation as specified in `../docs/REMOTE_UPDATES.md`.

## Validation status

**IMPLEMENTED AS HOSTING INFRASTRUCTURE / NOT DEPLOYMENT-VALIDATED.** Docker/Compose/nginx configuration and publication tooling are now in source control. They have not yet been built or run on the Synology server, and no ESP32 OTA client exists yet. Successful container operation will validate hosting only, not ESP32 rollback or hardware behaviour.
