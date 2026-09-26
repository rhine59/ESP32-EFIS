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


## Ownership and licence transfer

A registered EFIS must support a controlled transfer when the aircraft/instrument is sold.

### Transfer modes

1. **Transfer device and transferable licence** — normal sale. The seller starts a transfer for a specific EFIS Device ID. The service records the pending transfer, issues a short-lived one-time transfer code or invitation, and the buyer accepts it while signed into their own account. On acceptance, ownership of the device changes atomically and every entitlement explicitly marked transferable moves with it.
2. **Transfer device only** — used where an entitlement is non-transferable or the seller elects to retain a separately portable entitlement. The service must clearly show what will and will not move before confirmation.
3. **Administrative recovery transfer** — for lost account access, deceased owner, dealer/manufacturer intervention or other exceptional cases. This requires stronger evidence and an audited privileged workflow; it must not be an ordinary customer bypass.

### Safety and security rules

- Device ID never changes because ownership changes.
- Seller must be authenticated and currently own the device.
- Buyer must accept the transfer; knowing a Device ID alone is never sufficient.
- Require re-authentication for transfer confirmation; add MFA when available.
- Transfer tokens are random, single-use, short-lived and stored hashed server-side.
- Do not expose seller/buyer personal details beyond what is necessary.
- A pending transfer can be cancelled by the seller until accepted.
- Acceptance is atomic: the device cannot belong to two customer accounts.
- Record immutable audit events for initiation, cancellation, acceptance and administrative intervention.
- Payment-provider customer/payment instruments never transfer to the buyer.
- Historical invoices/payment records remain with the original purchaser subject to retention/privacy rules.
- Installed signed licence remains usable during a reasonable sale/transfer window; normal EFIS startup must not require Internet access.
- After acceptance, issue a fresh signed licence bound to the same Device ID and the buyer's current entitlement state. The old installed licence enters a **bounded ownership-transfer grace period** rather than being invalidated immediately. During the grace period the EFIS remains fully usable offline while the buyer completes account registration and installs the replacement signed licence. At grace expiry, the superseded licence follows the product's defined post-expiry behaviour; safety/fail-obvious core instrument behaviour must never be corrupted or misleading.

The exact duration is configurable server-side and shown clearly to seller and buyer. Initial product default: **30 days from buyer acceptance of the transfer**. Installing the buyer's replacement signed licence ends the transfer grace state early. The grace period must not be shortened retrospectively for an already accepted transfer.
- Refund, chargeback, subscription and non-transferable-feature policy must be explicit per entitlement.
- A factory reset or licence reset does not itself change registered ownership.

### Client UX

Web, iOS and Android instrument-detail pages should expose **Sell / Transfer EFIS**. The seller sees the Device ID, transferable entitlements, exclusions and consequences before confirming. The buyer uses **Accept transferred EFIS**, entering/scanning the one-time code or following an authenticated invitation. Both receive a final transfer receipt/status.

This workflow is account/licensing administration only; it must never alter flight data, calibration or instrument safety configuration as a side effect.
