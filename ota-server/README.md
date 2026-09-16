# ESP32 EFIS OTA image server

This directory provides the **distribution** side of the ESP32 EFIS remote-update design. GitHub remains the authoritative source/release history; this container serves only deliberately published firmware images and the device-facing manifest.

It is intentionally a static HTTP origin built on nginx. **TLS terminates at the Synology reverse proxy (or another trusted HTTPS proxy). The container is now bound to NAS loopback only (`127.0.0.1:8080`) and port 8080 must never be forwarded/exposed to the Internet.** The public device-facing service is HTTPS port 443 only.

See `../docs/PHONE_NETWORK_AND_PUBLIC_OTA.md` for the complete iPhone-hotspot path, instrument connection dialog and public Synology setup.

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

The container listens only on `127.0.0.1:8080`. In DSM **Control Panel → Login Portal → Advanced → Reverse Proxy**, create an HTTPS reverse proxy from a dedicated public hostname such as `efis-updates.your-domain.example:443` to `http://127.0.0.1:8080`. Attach a valid TLS certificate for that exact hostname.

Create public DNS for the hostname and, where the Internet connection permits inbound hosting, configure the router/firewall so only TCP 443 reaches the Synology HTTPS reverse proxy. Do **not** expose 8080, DSM administration ports or Docker management interfaces. If the site is behind CGNAT, use a deliberately configured trusted HTTPS tunnel/reverse-proxy service instead of opening the origin container.

The ESP32 firmware will eventually be configured with the stable HTTPS URL:

```text
https://efis-updates.your-domain.example/efis/manifest.json
```

## Phone hotspot path

For field maintenance the EFIS is intended to join an iPhone Personal Hotspot in Wi-Fi station mode. The phone supplies Internet connectivity; it does not receive or flash the firmware itself:

```text
ESP32 EFIS → iPhone Personal Hotspot → Internet → HTTPS :443
          → Synology reverse proxy → 127.0.0.1:8080 → OTA container
```

Wi-Fi remains off during normal instrument operation and is enabled only by explicit maintenance/update action. The instrument stores hotspot credentials locally in NVS and must never send them to this server.

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

For a genuine public-access test, repeat from a network outside the NAS LAN (for example cellular data) and verify public port 8080 is not reachable.

## Diagnostics

```bash
docker compose ps
docker compose logs --tail=100 efis-ota
docker compose logs -f efis-ota
docker inspect --format='{{json .State.Health}}' esp32-efis-ota
curl -v http://127.0.0.1:8080/healthz
```

If HTTPS works externally but the container health check fails, diagnose the container/origin. If local HTTP works but HTTPS fails, diagnose Synology reverse proxy, DNS, certificate, router/firewall or CGNAT/tunnel configuration.

## Security and safety

This server is deliberately **read-only from the network**: there is no upload API, web administration interface or repository credential in the container. Releases are copied in through the filesystem/deployment process. Do not put GitHub tokens, signing private keys or Wi-Fi credentials in this image.

SHA-256 protects against corruption but does **not** prove publisher identity. The planned EFIS production design additionally requires signed application images; the private signing key must remain outside this repository/server image. HTTPS certificate validation and signed-image verification are separate protections.

Approved manifest/binary files may be publicly readable; secrecy of their URL is not a security control. If authenticated downloads are introduced later, use short-lived/device-scoped credentials rather than repository tokens.

A release becoming available on this server must never cause unattended installation. The EFIS OTA client remains an explicit maintenance-mode function with A/B rollback and first-boot confirmation as specified in `../docs/REMOTE_UPDATES.md`.

## Validation status

**IMPLEMENTED AS HOSTING INFRASTRUCTURE / NOT DEPLOYMENT-VALIDATED.** Docker/Compose/nginx configuration and publication tooling are in source control. Loopback-only origin binding and the public HTTPS reverse-proxy design are implemented/documented, but they have not yet been built or externally tested on the Synology server. No physical ESP32 OTA/network client is validated yet. Successful container operation validates hosting only, not ESP32 rollback or hardware behaviour.
