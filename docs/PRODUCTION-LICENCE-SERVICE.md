# RedOne production licence service deployment

**Status:** Synology-hosted deployment adopted for the current project phase; external managed hosting is deferred.

## Customer network contract

EFIS Service must work without customer network configuration. The production API therefore requires one stable public DNS hostname, publicly trusted TLS, HTTPS on TCP 443, and identical behaviour over normal Wi-Fi and cellular. No split DNS, NAT-loopback dependency, private IP, custom certificate, VPN, router change, Private Relay/Limit IP Address Tracking change, or user-entered service URL is permitted.

## Synology deployment boundary

The services remain hosted on the project Synology for the current phase. `license-service/` and `efis-web-simulator/` are development harnesses and must not be mistaken for the hardened customer API; the Synology deployment must evolve to use the account/entitlement and private signer boundaries described below.

`account-service/` is a prototype foundation, not yet a production security boundary. It requires authenticated mobile sessions/API tokens, email verification/recovery, authorization on every device/entitlement operation, database migrations/backups, rate limiting, audit retention, payment-provider webhook verification, and integration with an isolated licence signer before Internet exposure.

## Production topology

```text
iPhone EFIS Service
        |
        | HTTPS :443
        v
public licence API / WAF / rate limiting
        |
        +--> account + ownership + entitlement service --> PostgreSQL
        |
        +--> private signing service --> protected Ed25519 key custody

RedOne EFIS verifies signed licence offline using provisioned public trust keys.
```

The signer is never public. The public API cannot read/export the private signing key. Production and development databases, keys and credentials are separate.

## Release configuration

Release iOS builds read `EFISLicenceServiceURL` from application configuration. The app accepts only HTTPS and either the default port or explicit 443. Debug builds may use the Synology simulator endpoint.

A release build with no valid production endpoint is intentionally non-operational for licence network actions; it must not silently fall back to the Synology development service.

## Go-live gates

1. Provide a stable public HTTPS hostname/path to the Synology-hosted customer API without requiring client/router configuration; an outbound tunnel/reverse-proxy is acceptable for this phase and avoids NAT-loopback dependence.
2. Run PostgreSQL on the controlled Synology deployment with encrypted backups and restore testing; managed PostgreSQL may be adopted later.
3. Establish production secrets/key custody and signer isolation/rotation.
4. Implement authenticated customer/mobile API and authorization tests.
5. Implement verified payment webhook adapters and idempotency.
6. Add rate limiting, structured audit/security logging and monitoring/alerts.
7. Run migrations and seed only controlled production configuration.
8. Deploy `/healthz` and readiness checks without leaking secrets.
9. Configure the Release `EFISLicenceServiceURL`.
10. Validate from unrelated Wi-Fi and cellular with normal iOS privacy settings enabled.
11. Run licence issue/install/renew/transfer/recovery negative-path tests.
12. Only then enable TestFlight production-service testing.

## Required production endpoint contract

The public service must preserve the mobile workflow semantics documented in `LICENSING_ARCHITECTURE_AND_FLOWS.md`: account/device lookup, included-first-year activation, plans/purchase state, renewal state, ownership transfer, buyer acceptance, signed entitlement acquisition and auditable lifecycle state. Simulator-only test mutation/trust-bootstrap endpoints must not exist in production.

## Synology local/public routing decision

**Adopted:** the iOS app owns route selection; router-specific DNS and third-party tunnels are not dependencies.

The canonical service identity remains the public Synology HTTPS endpoint. Normal customers use that endpoint directly. When the app happens to be on the same LAN as the hosting Synology and the public route is unavailable because the site router does not provide NAT loopback, the app may automatically use a locally discovered Synology route. No user-entered IP address, DNS change or router configuration is permitted.

Routing order is:

1. try the canonical public HTTPS endpoint;
2. only on a connectivity failure, attempt local service discovery;
3. verify that the discovered endpoint is the expected RedOne service before sending account/licence requests;
4. use a cryptographically authenticated local TLS channel; never disable TLS/certificate checks and never trust a discovered endpoint merely because it is on the LAN;
5. prefer the canonical public endpoint again when it becomes reachable.

The local path is a hosting-site optimisation for the Synology LAN, not a configuration burden placed on RedOne customers. Local discovery must not hard-code the current NAS address (`192.168.1.99`) or depend on a FRITZ!Box feature.

### Rejected dependencies

- Cloudflare/other external tunnel products for the current phase;
- router-specific split DNS or NAT-loopback configuration;
- permanent `/etc/hosts` entries;
- asking users to disable iOS privacy/network features;
- accepting a private-IP HTTPS certificate mismatch;
- disabling TLS validation.

Before implementing local failover, define the authenticated discovery advertisement and local TLS identity/rotation mechanism. This security gate prevents a malicious device on an untrusted LAN from impersonating the licence service.

### 2026-10-05 physical-device acceptance

The Synology local fallback was validated on the physical iPhone 13 Pro Max with normal LAN settings. The canonical public development URL was unreachable from inside the LAN because the site router does not provide the required loopback path. The app then resolved the repository-managed `_redone-license._tcp` mDNS service, connected to `redone-license.local:9443`, accepted only the pinned dedicated gateway certificate, and successfully loaded the RedOne licence account.

No FRITZ!Box DNS/NAT change, split DNS, `/etc/hosts` entry, external tunnel product, fixed NAS address in the app, certificate-validation bypass, or user service-URL change was required.

The Synology gateway runs unprivileged, keeps its TLS private key on the NAS with restrictive permissions, exposes only the phone API and `/healthz`, and dynamically advertises the NAS LAN interface address. The app still tries the canonical public HTTPS service first and invokes the authenticated local route only after a connectivity failure.
