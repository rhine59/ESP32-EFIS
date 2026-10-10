# Lollipop — iPhone companion app

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

Generate the **Lollipop** Xcode project with `cd ios/EFISService && xcodegen generate`, then open `ios/EFISService/Lollipop.xcodeproj` and use the **Lollipop** scheme. The source directory remains `ios/EFISService/EFISService/` for compatibility. The bundle identifier remains `uk.co.thingies.EFISService` to preserve installed-app identity and data. Minimum supported iOS version is 17.

The development service URL is configurable in the app. No device credential or licence-signing key is present in the phone application.

For the current Synology simulation, the phone talks only to the simulator's restricted development broker at `/api/phone/entitlement` (reverse-proxied on the simulator endpoint). That broker holds the simulator-side device credential, calls the internal licence service, and returns only the already-signed DEVELOPMENT entitlement. The raw licence service and its simulator test endpoints remain host-bound and are not exposed to the phone.

This broker is explicitly `simulation_only`; the iPhone client rejects a response that is not marked as such. It is not the production customer API. Production replaces it with authenticated account ownership/device-registration flows over HTTPS.

## Acceptance criteria

- Phone cannot sign a licence.
- A returned signed envelope can be cached and survives app relaunch through Keychain.
- Cached licence metadata identifies the intended immutable Device ID.
- Entitlement refusal is shown without destroying an existing cached licence.
- Local transfer is a separate explicit user action.
- Transfer does not imply activation: the EFIS verifies and installs the envelope.
