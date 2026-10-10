# RedOne local firmware management — milestone 1

Date: 2026-10-10

## Scope
The Lollipop iPhone EFIS Wi-Fi screen verifies RedOne using GET http://192.168.4.1/status and now displays installed firmware, running slot, next update slot, previous firmware (if reported), and rollback eligibility.

## Status response
Required legacy fields: `device`, `version`, `running`, `next`. Optional forward-compatible fields: `previousVersion` (string), `rollbackAvailable` (boolean), `rollbackReason` (string), `updateReady` (boolean). Missing optional fields mean **unknown**, never permission to install or roll back. Bench firmware explicitly returns false for readiness and rollback; this is not a production security assertion.

## Safety gates
The upgrade and rollback buttons remain disabled in milestone 1. Do not enable until the local protocol authenticates the device and requester, validates signed images and compatibility/security versions, proves maintenance mode and supply voltage, and completes physical A/B boot and rollback tests. The existing bench `/update` endpoint is NOT production safe: it uses a static lab token and directly selects/reboots a candidate. Never expose it beyond the isolated bench network or invoke it from the customer app.

## Milestone 2 — boot-state telemetry
The bench `/status` response now advertises `apiVersion: 1` and `bootState`, derived from `esp_ota_get_state_partition()` for the running application. Values include `new`, `pending_verify`, `valid`, `invalid`, `aborted`, `undefined`, and `unknown` if the state cannot be read. The iPhone displays these fields when present and supports older firmware where they are absent. This is read-only telemetry, **not authentication** and not authorization to update. The legacy lab `/update` endpoint remains unsafe for production and is not used by the phone.

## Milestone 3 — local file selection
The iPhone app now provides a Files picker for a local firmware binary when RedOne is verified. It checks that the selected item is a regular file between 1 KB and 16 MB, reads its bytes, and displays its name, byte count and SHA-256 digest. This is an inspection aid, NOT image-signature verification, compatibility verification or device authentication. Files are not uploaded or installed. The transfer, activation and rollback controls remain disabled. Before production, move hashing to bounded streaming I/O, retain the security-scoped source safely, validate a signed release manifest and verify device compatibility before enabling transfer.

## Next milestones
1. Implement a versioned authenticated local management API with firmware metadata, partition health and rollback eligibility derived from ESP-IDF OTA state.
2. Add signed firmware package selection, compatibility checks, transfer progress, and staged activation with explicit confirmation.
3. Add rollback request, recovery and fault-injection tests; validate interrupted transfers, failed boot, and configuration/SMUX compatibility.
4. Test on physical RedOne and document production acceptance evidence.

## Validation
`xcodebuild -project ios/EFISService/EFISService.xcodeproj -scheme EFISService -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build -quiet` passed on 2026-10-10. Physical device and ESP-IDF firmware build remain unvalidated for this change.
