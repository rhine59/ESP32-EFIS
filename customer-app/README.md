# EFIS Customer Mobile Apps

Customer companion apps for iPhone/iPad and Android. These apps manage the **owner account and licensing relationship**; they are not flight instruments and do not provide primary/supplementary flight indications.

## Shared product scope

- create/sign in to EFIS owner account;
- view registered instruments and licence status;
- register an EFIS by permanent Device ID / short registration code;
- show optional secondary hardware fingerprint;
- purchase/manage licence entitlement through provider-hosted checkout;
- retrieve a signed licence for online installation;
- display an offline activation/registration response for transfer to an EFIS without Internet access;
- view account/payment history without storing card PAN/CVV;
- request licence reset/re-provisioning subject to server policy;
- view support, firmware availability and non-secret device status later.

The mobile apps never contain the licence-signing private key and never collect/store raw payment-card details. Apple Pay/Google Pay/PayPal/card checkout is provider-hosted/tokenized.

## Architecture

Both native apps consume the same versioned HTTPS API exposed by `efis-account`. Device/licence/payment rules remain server-side so iOS, Android and the web portal cannot diverge.

Initial repositories live here as native skeletons:

- `customer-app/ios/EFISCustomer/` — SwiftUI, iOS 17+
- `customer-app/android/` — Kotlin + Jetpack Compose

See `docs/CUSTOMER_ACCOUNT_AND_APPS.md`.
