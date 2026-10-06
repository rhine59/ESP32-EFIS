# EFIS Account Service

Prototype container service for customer accounts, EFIS registration and licence entitlements.

## Security boundary

This service does **not** store card numbers/CVV and does **not** contain the private licence-signing key. Card/wallet entry must use provider-hosted/tokenized checkout (Stripe, PayPal/Braintree, Adyen etc.). Provider webhooks must be signature-verified before production use. Apple Pay/Google Pay/PayPal/cards are payment adapters, not changes to the EFIS licence protocol.

Primary device identity is a provisioned EFIS Device ID. ESP32 MAC may be retained as a secondary fingerprint only.

## Run

Copy `.env.example` to `.env`, replace every CHANGE_ME with strong random values, then:

```bash
docker compose -f account-service/compose.yml --env-file account-service/.env up -d --build
curl http://127.0.0.1:8091/healthz
```

The service binds to NAS loopback only. Publish it only through an authenticated TLS reverse proxy.

## Current prototype API

- `GET /healthz`
- `POST /v1/users`
- `POST /v1/devices`
- `GET /v1/devices/{device_id}/entitlements`
- `POST /internal/payment-event` — normalized internal prototype endpoint, **not a public production webhook**

## Still required before production

Login/session or OIDC, email verification/password reset/MFA, CSRF/rate limiting, admin RBAC, migrations/backups, verified payment-provider webhook adapters, device challenge authentication, private licence signer integration, privacy/retention controls, tests and security review.


## Customer web portal

The container now includes a responsive owner portal at `/` with account registration/sign-in, session-backed dashboard, registered-instrument display and EFIS Device ID registration. Payment and licence-generation controls remain deliberately inactive until verified provider-webhook and private signer integrations are implemented.

Production hardening still requires CSRF protection, rate limiting, email verification/password reset/MFA, session expiry/revocation, admin RBAC and end-to-end security tests before public exposure.

## Synology deployment

The Lollipop account authority runs as `account-service` plus PostgreSQL and binds only to NAS loopback `127.0.0.1:8091`. Create `account-service/.env` on the Synology from `.env.example` using long random `POSTGRES_PASSWORD` and `SESSION_SECRET` values; `.env` is secret runtime state and must not be committed. Build/start with `docker compose --env-file .env up -d --build`, then require `GET http://127.0.0.1:8091/healthz` to return `{"status":"ok"}`.

The phone registration URL is a separate public HTTPS boundary. For the current development deployment configure DSM Reverse Proxy as HTTPS `granvillehouse.synology.me:8450` -> HTTP `127.0.0.1:8091`; the phone opens `/register`. Do not expose port 8091 directly. Production replaces the development port with the canonical default-443 Lollipop account hostname/route.

### Validated development route

As of 2026-10-06 the development route `https://granvillehouse.synology.me:8450/register` is deployed and externally reachable. `/healthz` returns HTTP 200 with normal TLS certificate validation. DSM terminates HTTPS on 8450 and proxies only to the loopback account origin on 8091; port 8091 remains private.
