# EFIS Product Licensing

**Status:** architecture adopted; implementation and production security validation pending.

This document is the authoritative end-to-end product-licensing process for ESP32-EFIS. Licensing is a commercial entitlement mechanism, not a flight-safety dependency. Normal startup and safe/fail-obvious behaviour must not depend on Internet, account or payment availability.

## 1. Trust boundaries

The system separates four trust domains:

1. **EFIS device** — stores immutable Device ID, public licence-verification key, protected installed licence and local licence state.
2. **efis-account** — customer accounts, device ownership, entitlements, payment-provider references and audit history.
3. **efis-license-signer** — private service/worker permitted to use the licence-signing private key. It is not publicly exposed.
4. **Payment provider** — handles card/wallet credentials. Raw PAN/CVV never enters EFIS apps/services.

OTA signing and licence signing are separate trust domains and use separate keys.

## 2. Device identity and provisioning

Each production unit receives an immutable Device ID, e.g. `EFIS-00001247`. This is the primary licensing identity. ESP32 factory/eFuse MAC may be recorded only as a secondary fingerprint.

Provisioning must:
- allocate a unique Device ID;
- write it into protected persistent device identity storage;
- establish any device authentication credential required for online licence retrieval;
- provision the public licence-verification key/trust anchor;
- record manufacturing/provisioning audit metadata server-side;
- verify the Device ID can be read back correctly.

The Device ID survives licence reset, Wi-Fi reset, factory reset, firmware update and ownership transfer. If missing/corrupt, firmware reports an identity fault and logs it; it never invents a replacement.

Every normal boot displays the Device ID:

```text
        EFIS BOOT
     EFIS-00001247

      > START EFIS
        FULL TEST
        FAULT LOG
        LICENSE
        FIRMWARE UPDATE
```

## 3. Licence payload

A signed licence should contain, at minimum:
- schema/version;
- product identifier;
- Device ID;
- unique licence identifier;
- entitlement/features;
- issue time/sequence;
- licence type;
- optional expiry/support metadata;
- ownership-transfer/grace metadata where applicable;
- key/signature algorithm identifier;
- digital signature over a canonical representation.

Do not put customer passwords, payment credentials, private signing material or unnecessary personal data into the licence.

The exact serialization and cryptographic algorithm are implementation decisions to be frozen before signer development. Use a modern asymmetric signature scheme supported reliably on ESP32; private key never leaves controlled signer/key storage.

## 4. Customer purchase and entitlement

1. Customer creates/verifies an account.
2. Customer registers the EFIS Device ID using the approved device-registration/challenge flow.
3. Server proves/validates the registration rather than accepting knowledge of Device ID alone.
4. Customer selects a licence/product.
5. Checkout is created through the payment adapter.
6. Card/Apple Pay/Google Pay/PayPal data goes directly to the payment provider.
7. Provider sends a webhook.
8. Server verifies webhook authenticity, event identity and replay/idempotency.
9. Only a verified successful payment changes entitlement to active.
10. Account service requests a licence from the private signer.
11. Signer validates the authorized request and entitlement snapshot, signs a licence and returns the signed artefact.
12. Account/audit store records issuance without storing the signing private key.

## 5. Online installation from the EFIS

Physical rotary/push workflow:

```text
EFIS BOOT
  -> LICENSE
  -> Get / Refresh Licence
  -> Wi-Fi Connection
  -> authenticate device
  -> retrieve signed licence
  -> verify signature locally
  -> verify Device ID/product/schema/time/state
  -> store candidate
  -> atomic activation
  -> show ACTIVE
```

Rules:
- user account password is never entered/sent by the EFIS;
- device uses a provisioned credential/challenge mechanism;
- TLS protects transport, but licence signature is independently verified;
- invalid signature, wrong Device ID/product/schema or malformed licence is rejected;
- current valid licence is retained until the candidate has been fully verified and committed;
- licence is stored in protected/encrypted NVS in production;
- network failure never prevents START EFIS;
- Wi-Fi is maintenance-oriented and does not silently reconnect during normal flight display operation.

## 6. Installation through web/iPhone/Android

Customer clients show registered devices and entitlement state. They may request/retrieve a signed licence after authenticating the customer and satisfying device/entitlement policy.

Apps use normal OS secure token storage (Apple Keychain; Android Keystore-backed storage). They do not contain the signing key. A downloaded licence is already signed and untrusted until the target EFIS verifies it.

## 7. Offline activation

For an EFIS without usable Internet:

1. LICENSE screen shows Device ID and a short registration/challenge value.
2. Customer signs into web/iPhone/Android.
3. Customer selects **Offline Activation** and supplies/scans the challenge.
4. Account service validates device ownership and entitlement.
5. Private signer issues a signed response/licence bound to that Device ID and challenge/state.
6. Customer transfers it using the supported service/USB mechanism or a compact manual response.
7. EFIS verifies signature, Device ID, challenge/state, schema and entitlement locally.
8. Verified licence is atomically installed into protected storage.
9. EFIS reports ACTIVE and records a non-secret audit/fault-log event as appropriate.

Do not require rotary entry of a large cryptographic payload; prefer QR/service/USB or a deliberately compact challenge/response design.

## 8. Boot and runtime verification

Licence verification is local. At boot the firmware:
1. reads immutable Device ID;
2. reads installed licence;
3. validates structural integrity/schema;
4. verifies digital signature against embedded/provisioned public key;
5. confirms licence Device ID/product;
6. evaluates entitlement and any expiry/grace rules using trustworthy time only;
7. exposes licence status to the UI;
8. logs corruption/signature/state faults without secrets.

No network call is required for a valid offline licence.

If trustworthy wall-clock time is unavailable, firmware must not invent a timestamp or silently make an expiry decision based on false time. The time/expiry model must be explicitly designed before expiring subscriptions are shipped.

## 9. Firmware updates

Firmware updates normally preserve the installed valid licence. Licence storage/schema migration is versioned and rollback-safe. OTA compatibility testing includes old/current licence schemas. Firmware must not silently strand a legitimately licensed device.

## 10. Reset and replacement

LICENSE menu provides Status, Get/Refresh, Install/Replace and Reset.

Licence Reset:
- requires explicit user action and confirmation;
- removes installed licence/activation state;
- does not alter Device ID, device ownership, Wi-Fi credentials or calibration unless a separately confirmed operation says so;
- is audit/fault logged without secrets;
- leaves the device ready to install/retrieve a valid licence.

Corrupt/invalid licence is fail-obvious and replaceable; it does not cause identity regeneration.

## 11. Ownership transfer / sale

Seller chooses **Sell / Transfer EFIS** in web/iOS/Android. Seller re-authenticates and sees the Device ID, transferable entitlements, exclusions and consequences.

Normal transfer:
1. server verifies seller owns the Device ID;
2. seller initiates transfer;
3. server creates random, single-use, short-lived transfer credential stored hashed;
4. buyer signs into their own account and accepts invitation/code;
5. server atomically moves device ownership and transferable entitlements;
6. payment instruments never move;
7. historical purchase records remain with original purchaser subject to retention/privacy policy;
8. signer issues a fresh buyer licence for the unchanged Device ID;
9. both accounts receive transfer status/receipt.

Pending transfer can be cancelled before acceptance. Device cannot belong to two accounts.

### Transfer grace

Default grace is **30 days from buyer acceptance**. The seller-era installed licence continues to work offline during this bounded period so sale/registration cannot abruptly disable the instrument. The duration is server-configurable but cannot be shortened retrospectively after transfer acceptance.

Installing the buyer's replacement licence ends transfer grace early. Exact post-grace product behaviour must be frozen before commercialization and must never produce misleading flight indications.

Exceptional recovery transfers require privileged, audited administrative evidence/workflow and cannot bypass normal ownership controls casually.

## 12. Entitlement lifecycle

State model should distinguish at least:
`NONE -> PENDING_PAYMENT -> ACTIVE -> TRANSFER_PENDING -> TRANSFER_GRACE/SUPERSEDED`, plus product-specific `EXPIRED`, `REFUNDED`, `CHARGEBACK`, `REVOKED` where policy permits.

A server entitlement state and an already-installed offline licence are not identical. Revocation cannot be assumed instantaneous on an offline EFIS. Policies must reflect that technical reality.

Subscription, refund/chargeback, revocation and non-transferable-feature policies remain to be frozen before sale.

## 13. Audit requirements

Server audit events include account/device registration, entitlement creation/change, payment webhook outcome, licence issuance/reissue, reset request, transfer initiation/cancel/accept, administrative intervention and security-relevant failures.

Do not log passwords, card PAN/CVV, signing keys, Wi-Fi credentials, raw authentication secrets or unnecessary licence secrets.

EFIS persistent fault/diagnostic log records stable non-secret codes for identity/licence verification/storage failures and significant licence transitions, wear-consciously.

## 14. Failure behaviour

- Account/payment/licence server unavailable: existing valid licence and START EFIS continue.
- Wi-Fi/DNS/TLS failure: report maintenance error; START EFIS remains.
- Invalid downloaded signature: reject candidate, retain current valid licence.
- Wrong Device ID/product: reject.
- Storage failure: fail obvious; retain prior valid copy where technically possible.
- Missing/corrupt Device ID: identity fault; never fabricate.
- Signer unavailable: entitlement remains recorded; retry issuance safely/idempotently.
- Duplicate payment webhook: idempotent; never duplicate entitlement/payment effects.

## 15. Security requirements before production

- isolated signer and controlled key storage/rotation/recovery;
- authenticated, authorized account and device APIs;
- email verification, password reset, MFA/re-authentication for sensitive actions;
- CSRF/rate limiting/session expiry/revocation;
- signed and replay-resistant device challenge protocol;
- verified/idempotent payment webhooks;
- protected/encrypted device NVS;
- database migrations, encrypted backups and restore tests;
- privacy/retention/export/deletion policy;
- audit monitoring and administrative RBAC;
- licence signature test vectors and malformed-input/fuzz testing;
- penetration/security review.

## 16. Required tests

Test known-good and negative cases for provisioning, duplicate IDs, account registration, ownership proof, payment success/failure/replay, signer failure, valid/invalid/wrong-device licences, NVS corruption, power loss during replacement, offline installation, firmware migration/rollback, licence reset, transfer/cancel/accept, 30-day grace boundaries, buyer replacement, clock unavailable/incorrect, and recovery/admin flows.

Physical ESP32 tests are required. Simulator/API tests alone do not establish production readiness.

## 17. Current implementation status

**Implemented/staged:** account-service prototype, PostgreSQL account/device/entitlement model, web portal prototype, iOS/Android customer skeletons, Device ID architecture, payment-provider abstraction requirements, transfer/grace policy and this process specification.

**Pending:** production device provisioning mechanism, authenticated customer/device API, registration challenge, signer container/key management, signed licence format/crypto selection, verified payment adapters, online/offline installation firmware, protected NVS licence store, transfer implementation, security hardening and physical validation.
