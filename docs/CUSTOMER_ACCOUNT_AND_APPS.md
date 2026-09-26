# Customer account, licensing and mobile applications

**Status: architecture adopted; account/web prototype implemented; mobile skeletons staged; production security/payment/licence signer pending.**

## Customer ecosystem

```text
 Web portal ─────┐
 iPhone app ─────┼── HTTPS ──> efis-account ──> PostgreSQL
 Android app ────┘                  │
                                    ├── payment-provider adapter
                                    │    cards / Apple Pay / Google Pay / PayPal
                                    │
                                    └── private efis-license-signer
                                                 │
                                           signed licence
                                                 │
                                                EFIS
```

The permanent provisioned **EFIS Device ID** is the primary commercial identity. The ESP32 factory/base MAC may be retained as a secondary hardware fingerprint but is not the licence key.

## Customer functions

Web, iOS and Android clients should provide the same account functions: registration/sign-in, instrument registration, licence status, purchase/manage entitlement, signed-licence retrieval, offline activation assistance, licence reset/re-provision request, payment/account history and support.

Normal EFIS operation never depends on these clients or on Internet/account/payment availability once a valid signed licence is installed.

## Payment boundary

Support provider-hosted/tokenized card entry plus PayPal, Apple Pay and Google Pay. Additional regional methods may be added through adapters. Raw PAN/CVV must never traverse or persist in EFIS services/apps. Store only provider references, transaction state, amount/currency and entitlement/audit metadata.

## Licence flow

Online: EFIS maintenance menu -> Wi-Fi -> device authentication -> account entitlement -> signed licence -> local signature verification -> protected NVS.

Offline: EFIS displays Device ID plus short challenge/registration code -> customer uses web/mobile account -> server authorizes entitlement and returns a signed/encoded activation response -> transfer by USB/service or practical manual mechanism -> EFIS verifies locally.

Private licence-signing material remains isolated from public web/mobile/API tiers. OTA signing and licence signing use separate keys.

## Mobile implementation stages

1. Native navigation/account/device-list UI with mock service.
2. Versioned account API client and secure OS credential/token storage.
3. Device registration/challenge workflow.
4. Provider-hosted checkout handoff and verified entitlement refresh.
5. Signed licence retrieval/offline activation UX.
6. Reset/re-provision/support functions.
7. Accessibility, localization, privacy, security and store-release hardening.

No mobile build or store readiness is claimed until native toolchains/tests have been run.
