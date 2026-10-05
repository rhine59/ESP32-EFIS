# EFIS Service — iPhone prototype

SwiftUI prototype for the customer/service phone workflow around ESP32-EFIS licensing.

## Responsibility boundary

The phone **does not generate or sign licences** and never contains the Ed25519 licence-signing private key. It authenticates a device/customer workflow, requests a signed entitlement from the licence service, caches the returned signed envelope, and later transfers that envelope to the EFIS.

Initial development flow:

1. Enter or scan the immutable EFIS Device ID.
2. Connect to the development entitlement service.
3. Authenticate the device challenge.
4. Request the signed DEVELOPMENT entitlement.
5. Cache the opaque signed licence envelope in the iPhone Keychain.
6. Show licence ID, class and Device ID.
7. Transfer the already-signed envelope to the EFIS local service. The transport is represented by a protocol in this first prototype so it can later share the phone OTA local connection.
8. The EFIS remains responsible for Ed25519 verification, schema/product checks, Device-ID binding and atomic installation.

Account login, payment and production ownership registration are intentionally interfaces/future work, not mocked as production security.

## Xcode

Create/open an iOS SwiftUI target named **EFISService**, then add the Swift files in `ios/EFISService/EFISService/`. Minimum target iOS 17 is suitable for the prototype.

The development service URL is configurable in the app. Do not ship a production build with a development device secret. The current HMAC secret is simulator-only and exists solely to exercise the already-deployed development service.

## Acceptance criteria

- Phone cannot sign a licence.
- A returned signed envelope can be cached and survives app relaunch through Keychain.
- Cached licence metadata identifies the intended immutable Device ID.
- Entitlement refusal is shown without destroying an existing cached licence.
- Local transfer is a separate explicit user action.
- Transfer does not imply activation: the EFIS verifies and installs the envelope.
