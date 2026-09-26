# Customer account, licensing and mobile applications

Status: architecture adopted; account/web prototype implemented; native mobile prototypes staged; production security/payment/licence signer pending.

## Ecosystem
Web portal, iPhone app and Android app use the same versioned HTTPS API from efis-account. efis-account owns users, provisioned EFIS Device IDs and entitlements; PostgreSQL stores account/device/audit metadata; payment adapters handle provider-hosted card, Apple Pay, Google Pay and PayPal checkout; a separate private efis-license-signer issues signed licences. Normal EFIS operation remains offline-capable after licence installation.

The permanent EFIS Device ID is the primary commercial identity. ESP32 MAC is secondary fingerprint only.

## Mobile scope
Both apps provide account sign-in, registered instrument list, Device ID registration, licence status, payment/entitlement management, signed licence retrieval, offline activation assistance, reset/re-provision request and support/update status. They never contain licence-signing private keys or store raw PAN/CVV.

## Delivery stages
1. Native account/device UI with mock service.
2. Authenticated API and Keychain/Android Keystore token storage.
3. Device registration/challenge.
4. Provider-hosted checkout and entitlement refresh.
5. Signed licence/offline activation.
6. Reset/re-provision/support.
7. Accessibility, privacy, security and App Store/Play release hardening.

No mobile build or store-readiness claim is made until native toolchains and tests have run.
