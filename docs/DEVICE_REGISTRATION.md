# Horizon initial registration and ownership claiming

Status: **ADOPTED DESIGN DIRECTION / IMPLEMENTATION PENDING**  
Date: 30 September 2026

## Goal

Associate a genuine MicroSky Horizon EFIS with a customer account while keeping normal EFIS startup independent of Internet, account, payment and licensing services. Registration establishes ownership/account association; it does not determine whether the flight display can start.

## Physical identity label

Fit a durable QR/data label to a non-prominent accessible part of the EFIS body/rear enclosure. Also print the human-readable immutable Device ID (for example `EFIS-00001247`) and product/model identification beside it.

The QR code is an identifier/onboarding pointer, **not proof of ownership by itself**. It must contain no password, Wi-Fi credential, licence private material, signing key, customer PII or reusable bearer secret.

Preferred QR payload is an HTTPS registration URL carrying only a public device identifier and format/version, for example conceptually:

`https://register.<future-domain>/v1/claim?device=EFIS-00001247&v=1`

Final production domain is deliberately not frozen here.

Provide the same QR on an owner/setup card inside the packaging for convenience, but the durable body label is authoritative for identifying the physical unit.

## Factory provisioning

Before sale each EFIS receives:

- immutable Device ID;
- cryptographic device identity/credential distinct from licence signing;
- manufacturing record: product, hardware revision, manufacture date/batch and claim state;
- no customer identity required at manufacture.

The device private credential never appears in the QR code.

## First-owner flow

1. Customer scans the EFIS QR with a phone.
2. Registration page/app opens and asks the customer to sign in or create a MicroSky account.
3. Backend validates that the Device ID is genuine and in a claimable state.
4. Customer is shown the product and Device ID and chooses **Claim this Horizon**.
5. System requires physical-possession confirmation. Preferred mechanism: on Horizon choose **LICENSE / REGISTRATION → REGISTER DEVICE** (or equivalent setup item), which opens a short registration window and displays a short-lived challenge/confirmation code.
6. Customer confirms the matching short-lived code on the phone. Alternative implementation may have the EFIS authenticate the challenge to the backend during a deliberately initiated maintenance Wi-Fi session.
7. Backend atomically binds the Device ID to the account, records ownership history/audit information and closes the claim token/window.
8. Phone shows **Registration complete** and the EFIS can show owner/registration status on its maintenance/status page.
9. Registration may then lead into licence acquisition/installation, warranty details and support, but these remain separate states.

Scanning a static QR alone must never be enough to steal/claim a unit.

## Offline behaviour

Horizon remains a supplementary/non-primary flight instrument and normal **START EFIS** must not require registration or network access. If the owner cannot get online at installation, registration can be deferred. Maintenance Wi-Fi is entered deliberately and does not silently reconnect during normal flight operation.

## Account/profile model

Minimum owner profile:

- account ID;
- display/name fields required for customer service;
- verified email;
- locale/units/preferences;
- owned Horizon Device IDs;
- licence/support/warranty associations;
- ownership role and sharing permissions;
- audit timestamps.

Do not store unnecessary aircraft/location information as a prerequisite to ownership.

A device has one primary owner at a time. Additional users may later be invited with explicit roles without changing primary ownership.

## Ownership transfer

Use the already adopted explicit transfer workflow rather than allowing a second account to rescan the static QR and take ownership. Seller initiates transfer; buyer accepts; backend changes ownership atomically and preserves audit history. Device-only/admin recovery remains available under the documented recovery policy. The static Device ID/QR remains unchanged across owners.

## Security rules

- Static QR = discovery/identification only.
- Physical possession must be proven with a short-lived challenge or device-authenticated claim.
- Claim challenges are single-use, expire quickly and are rate-limited.
- Never encode reusable credentials or PII in the QR.
- Device identity and licence signing remain separate trust domains.
- Account service cannot obtain licence private signing keys.
- Record claim/transfer/recovery security events.
- Registration reset must not change immutable Device ID.
- Factory/service recovery requires an auditable privileged process.
- Avoid exposing the QR prominently where casual photographs could capture it.

## UI direction

Boot menu remains focused on instrument operation. Registration belongs under LICENSE/maintenance rather than blocking boot.

Suggested maintenance view:

```
      DEVICE REGISTRATION

 Device: EFIS-00001247
 Status: NOT REGISTERED

 > REGISTER DEVICE
   REGISTRATION STATUS
   BACK
```

During a claim:

```
      REGISTER DEVICE

 Scan QR on EFIS body
 Sign in on your phone

 Confirmation code:
          482 731

 Expires in 04:32

 > CANCEL
```

The exact six-digit format and timeout are illustrative until threat modelling is complete.

## Production tests

Test at minimum: valid first claim; photographed/static QR without physical device; expired/replayed challenge; already-owned device; offline/deferred registration; interrupted claim; backend retry/idempotency; ownership transfer; factory/service recovery; account deletion/privacy handling; device identity corruption; and registration state surviving firmware OTA without changing Device ID.
