# RedOne local licence gateway

This is the authenticated LAN fallback for the Synology-hosted RedOne licence API.

It is **not** a replacement for the canonical public HTTPS endpoint. The iOS app tries public HTTPS first. If that fails, Bonjour discovers `_redone-license._tcp`; the app connects to the advertised gateway only after validating the gateway's pinned TLS identity.

The gateway private key remains on the Synology and is never committed. The app contains only the corresponding certificate/public-key pin. A DSM certificate renewal therefore does not affect local fallback.

The gateway proxies only the RedOne phone API to the loopback-bound service. It must not expose DSM, Docker, signer, database or administration endpoints.

Deployment requirements:
- generate a dedicated local gateway key/certificate on the Synology;
- publish only the gateway TCP port on the LAN;
- advertise `_redone-license._tcp` with Bonjour/mDNS;
- configure the proxy allow-list to `/api/phone/` and `/healthz` only;
- embed the certificate/public-key SHA-256 pin in the signed iOS application;
- rotate identity through an app release with overlapping old/new pins.
