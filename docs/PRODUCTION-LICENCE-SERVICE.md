# RedOne production licence service deployment

**Status:** release gate — production Internet host/domain not yet provisioned.

## Customer network contract

EFIS Service must work without customer network configuration. The production API therefore requires one stable public DNS hostname, publicly trusted TLS, HTTPS on TCP 443, and identical behaviour over normal Wi-Fi and cellular. No split DNS, NAT-loopback dependency, private IP, custom certificate, VPN, router change, Private Relay/Limit IP Address Tracking change, or user-entered service URL is permitted.

## Do not deploy the simulator service

`license-service/` is a development harness. It has one synthetic device, an in-memory entitlement and a development signing key. `efis-web-simulator/` is also development-only. Neither is a production customer API.

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

1. Provision Internet hosting and a dedicated production DNS hostname.
2. Provision managed PostgreSQL with encrypted backups and restore testing.
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
