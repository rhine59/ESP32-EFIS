# EFIS Licensing — Complete Architecture and Use-Case Flows

**Status:** authoritative licensing architecture and process-flow specification.  
**Scope:** customer, phone/web, account/entitlement, signing, EFIS installation, offline operation, lifecycle, recovery and validation.

This document complements `LICENSING.md`. It describes how all actors interact and distinguishes the production architecture from the current simulator implementation.

## 1. Architectural principles

Licensing is a commercial entitlement mechanism, **not a flight-safety dependency**. A network, account, payment or licensing-service failure must never prevent normal startup of an already usable EFIS.

The immutable **Device ID** is the licensing identity. Knowledge of a Device ID or its QR code is not proof of ownership.

The EFIS is the final trust decision point. Phone/web clients transport an opaque signed licence; they do not create, sign or authorize one.

Licences use **Ed25519 signatures over deterministic CBOR**. The EFIS holds public verification keys only. Licence private signing keys remain in the isolated signer boundary. OTA and licence signing use separate keys and trust domains.

## 2. Components and trust boundaries

| Component | Responsibility | Must not contain/do |
|---|---|---|
| EFIS | Immutable identity, trust anchors, local verification, protected licence storage, status | Licence signing private key; customer password |
| iPhone/Android/Web client | Customer UX, scan identity/challenge, authenticate customer, retrieve/cache/transport signed licence | Sign licences; treat Device ID as ownership proof |
| Account service | Accounts, ownership, device registration, entitlements, lifecycle, audit | Publicly expose signing key |
| Entitlement/payment layer | Establish commercial right after verified payment/policy | Store raw PAN/CVV |
| Licence signer | Validate authorized issuance request and sign deterministic licence payload | Public customer endpoint |
| Payment provider | Payment credentials and payment authorization | EFIS/device control |
| OTA service | Firmware distribution | Licence signing |
| Audit/diagnostics | Non-secret lifecycle/security events | Passwords, signing keys, device secrets |

Production services should be independently authenticated and least-privileged. The current simulator broker is a development-only shortcut around customer/account infrastructure.

## 3. Core data objects

### Device identity
Production example: `EFIS-00001247`. It is provisioned once and survives licence reset, Wi-Fi reset, firmware update, factory reset and ownership transfer. A missing/corrupt identity faults; firmware never generates a replacement.

### QR activation identity
Canonical development form:

`efis://device/<Device-ID>`

This QR is **identification only**. Production offline registration should extend the exchange with a short-lived challenge/nonce so a photographed/static Device-ID QR cannot serve as device authentication.

### Entitlement
Server-side commercial state describing what an authenticated owner is entitled to receive. It is not itself the portable licence installed on the EFIS.

### Signed licence
A versioned CBOR envelope containing `v`, `alg=Ed25519`, `kid`, exact deterministic-CBOR `payload`, and `sig`. The payload binds product, immutable Device ID, unique licence ID, issuance identifier/time, class/features and optional validity/transfer/support policy.

### Phone cache
The phone stores the already-signed opaque envelope in OS secure storage (Apple Keychain / Android equivalent). Cache possession does not make the phone a signer.

## 4. End-to-end architecture

```text
 Customer
    |
    v
 Phone / Web Client ----------------------+
    | customer authentication             |
    | device registration / ownership     |
    v                                     |
 Account + Entitlement Service            |
    | verified entitlement                |
    +--> Payment Provider                 |
    |    (when purchase required)         |
    |                                     |
    v                                     |
 Private Licence Signer                   |
    | Ed25519 signed deterministic CBOR   |
    v                                     |
 Phone secure cache                       |
    | opaque signed envelope              |
    | local maintenance transport         |
    v                                     |
 EFIS ------------------------------------+
    | immutable Device ID
    | trusted public key(s)
    | verify signature/schema/product/device/policy
    v
 Protected persistent licence store
    |
    v
 ACTIVE / VALID locally, including offline boot
```

The EFIS never trusts the phone's statement that a licence is valid. It verifies the original signed bytes itself.

## 5. Use case A — factory provisioning

1. Manufacturing allocates a globally unique Device ID.
2. Device ID is written to protected persistent identity storage.
3. Production device-authentication credential is provisioned.
4. Licence public trust anchor/key set is provisioned.
5. Manufacturing record links serial/Device ID and non-secret audit metadata.
6. Read-back test verifies identity and trust data.
7. Device boots showing its permanent Device ID.
8. Missing/corrupt identity causes an explicit identity fault.

**Invariant:** reset/update/transfer operations never change Device ID.

## 6. Use case B — customer purchase and first entitlement

1. Customer authenticates to account service.
2. Customer registers/adopts a device using the approved ownership/device challenge.
3. Account service verifies the challenge; Device-ID knowledge alone is insufficient.
4. Customer selects product/features.
5. Payment provider performs checkout.
6. Verified, replay-safe webhook confirms payment.
7. Account service changes entitlement to `ACTIVE`.
8. Account service requests issuance from the private signer.
9. Signer validates authorized request and entitlement snapshot.
10. Signer creates deterministic CBOR payload and Ed25519 signature.
11. Signed licence is returned to authorized client/service.
12. Issuance and entitlement transition are audit recorded.

Payment failure leaves entitlement inactive and does not produce a valid licence.

## 7. Use case C — direct online EFIS Get/Refresh

```text
LICENSE -> Get/Refresh -> maintenance Wi-Fi
        -> device challenge/authentication
        -> entitlement service
        -> signed licence
        -> EFIS local cryptographic verification
        -> candidate storage
        -> atomic commit
        -> ACTIVE
```

The current valid licence is retained until the candidate is fully verified and committed. TLS protects transport, but trust still comes from the licence signature. Network failure reports a maintenance error and does not block START EFIS.

## 8. Use case D — phone-mediated online acquisition

1. EFIS displays Device ID/activation QR.
2. Phone scans QR or user enters Device ID manually.
3. Phone authenticates customer and device/ownership through production account APIs.
4. Account service checks active entitlement.
5. Signer issues or returns the authorized signed licence.
6. Phone checks response/request correlation and stores the opaque envelope in secure storage.
7. Phone UI may show server-provided entitlement status.
8. EFIS has not yet trusted or installed anything.

**Current development implementation:** simulator QR -> iOS scanner -> restricted simulator broker -> challenge/HMAC licence service -> signed DEVELOPMENT envelope -> iPhone Keychain. The broker and shared simulator credential are not production architecture.

## 9. Use case E — phone-to-EFIS local installation

1. Phone already holds a signed envelope.
2. Customer establishes the supported local maintenance connection to the EFIS.
3. Phone sends Device ID plus opaque signed envelope.
4. EFIS compares target Device ID.
5. EFIS parses the bounded envelope.
6. EFIS selects trusted public key by `kid`.
7. EFIS verifies Ed25519 signature over the exact payload bytes.
8. Only after signature success does it validate schema, product, immutable Device ID and applicable policy/time state.
9. Candidate is written separately from the current valid licence.
10. Candidate is atomically committed.
11. EFIS reports `VALID/ACTIVE`.
12. Non-secret installation event is logged.

A successful HTTP/local-transfer response alone is never evidence of a valid licence; EFIS-side verification and post-install status are authoritative.

## 10. Use case F — completely offline aircraft installation

Precondition: the phone acquired/cached the signed licence earlier while it had service connectivity, and the EFIS already possesses the required trusted public key.

1. Aircraft/EFIS has no Internet.
2. Phone connects locally to EFIS maintenance interface.
3. Phone transfers cached signed envelope.
4. EFIS performs all signature/schema/product/Device-ID checks locally.
5. EFIS atomically installs it.
6. EFIS can restart with no Internet.
7. Boot reloads the stored envelope and re-verifies it locally.
8. Licence remains `VALID`; no account/licence-server call is needed.

This flow has passed in the simulator regression harness. Physical Wi-Fi/NVS/power-loss validation remains pending.

## 11. Use case G — offline activation when phone has no cached licence

Production flow:

1. EFIS shows immutable Device ID plus a short-lived registration challenge/QR.
2. Customer uses another Internet-connected phone/web device.
3. Customer authenticates.
4. Service validates ownership, entitlement and challenge.
5. Signer creates a response/licence bound to the device and required activation state.
6. Signed artefact is carried back to the aircraft by supported local service/USB mechanism.
7. EFIS verifies locally and atomically installs.

Large cryptographic payloads are not entered with the rotary control.

## 12. Use case H — normal boot with installed licence

1. Read immutable Device ID.
2. Read committed licence.
3. Reject malformed/bounded-parser violations.
4. Verify Ed25519 signature using locally trusted key.
5. Validate schema/product/Device ID.
6. Evaluate time/expiry/grace only using trustworthy time.
7. Expose licence status.
8. Continue normal boot independently of Internet availability.

If trustworthy wall-clock time is unavailable, the EFIS must not invent an expiry decision.

## 13. Use case I — refresh/replacement

1. Preserve current valid licence.
2. Acquire/import replacement as a candidate.
3. Fully verify candidate.
4. Write candidate separately.
5. Atomically replace committed licence only after success.
6. On interruption/restart, discard orphan candidate and retain old committed valid licence.

The simulator regression harness proves this interrupted-replacement behavior.

## 14. Use case J — invalid/tampered/wrong-device licence

- Tampered payload -> signature verification fails -> reject.
- Altered signature -> verification fails -> reject.
- Correctly signed licence for another Device ID -> signature succeeds, Device-ID binding fails -> reject.
- Wrong product/schema -> reject.
- Malformed/oversize input -> reject before unsafe processing.
- Existing valid licence remains installed.

These principal simulator cases are regression-tested.

## 15. Use case K — no entitlement / payment problem

If account-side entitlement is inactive, refunded, revoked under policy, or payment is incomplete, issuance/refresh is refused. A failed refresh does **not** erase an already installed valid offline licence unless an explicitly designed licence policy encoded in that licence requires it. Offline revocation cannot be instantaneous by assumption.

## 16. Use case L — corrupt persistent licence

1. Boot reads committed artefact.
2. Structural/signature verification fails.
3. Status becomes `INVALID` and fault is logged.
4. Device identity is preserved.
5. Firmware never silently regenerates a licence.
6. Customer may install a newly verified signed licence.

Simulator corrupt-store detection and recovery pass.

## 17. Use case M — Licence Reset

1. User explicitly selects Licence Reset and confirms.
2. Installed licence/candidate state is deleted.
3. Immutable Device ID remains.
4. Trust anchors remain.
5. Wi-Fi/calibration/ownership are unaffected unless separately requested.
6. Status becomes `NOT INSTALLED`.
7. Device is ready for a future valid installation.

Reset is not factory identity destruction.

## 18. Use case N — firmware update

Firmware update preserves the committed licence and immutable identity. New firmware must remain compatible with supported licence schema/key sets or migrate them rollback-safely. OTA signing and licence signing remain separate. An update cannot silently make a legitimately licensed instrument unusable.

## 19. Use case O — ownership transfer / sale

1. Seller authenticates and initiates transfer for Device ID.
2. Server verifies current ownership.
3. Single-use, short-lived transfer credential/invitation is created.
4. Buyer authenticates independently and accepts.
5. Server atomically transfers device ownership and transferable entitlements.
6. Device ID remains unchanged.
7. Signer issues buyer licence.
8. Existing seller-era licence enters the defined transfer grace (currently 30 days from acceptance).
9. Buyer installs replacement; successful buyer licence ends grace early.
10. Payment instruments and seller account credentials never transfer.

Pending transfer may be cancelled before buyer acceptance. Device cannot simultaneously belong to two accounts.

## 20. Use case P — key rotation

1. Generate new Ed25519 signing key in controlled key storage.
2. Give it a new `kid`.
3. Deliver new public key in validated firmware before using the private key for issuance.
4. Maintain old and new public keys during overlap.
5. Begin signing new licences with new `kid`.
6. Remove old trust only after compatibility/migration policy permits.

Never silently fall back to unsigned licences or another algorithm.

## 21. Use case Q — signer/account/payment outage

Existing locally valid licence continues to operate. New purchase/refresh may be delayed. Entitlement/payment state changes must be idempotent and retryable. Signer outage must not cause the public account tier to gain access to private signing material.

## 22. Use case R — lost/replaced phone

The phone cache is a convenience transport copy, not the source of entitlement truth. Customer signs in on replacement phone, proves ownership under account policy, and retrieves a fresh/current signed licence. Loss of phone does not alter immutable EFIS identity or an already installed valid licence.

## 23. Use case S — no phone available

Direct EFIS online Get/Refresh remains an architectural option. Offline service/USB transfer is the other fallback. The product must not make ownership of one particular phone a permanent prerequisite for operating an already licensed EFIS.

## 24. Use case T — support/admin recovery

Exceptional recovery is privileged and audited. Support may inspect non-secret identity/licence status and account records. Administrative ownership recovery requires defined evidence and RBAC. Support cannot mint unsigned licences or casually bypass ownership/payment policy; signer access remains isolated.

## 25. Use case U — expiry/subscription/grace

Before commercial release, policy must freeze subscription expiry, refunds/chargebacks, revocation, non-transferable features and post-grace behavior. Time-dependent enforcement is permitted only when the EFIS has trustworthy time. Any loss of licensed features must remain fail-obvious and must never create misleading flight indications.

## 26. Current simulator implementation mapping

| Production concept | Current implementation | Status |
|---|---|---|
| Immutable device identity | `EFIS-SIM-0001` | simulated |
| Activation QR | `efis://device/EFIS-SIM-0001` | implemented |
| Phone scanner | AVFoundation iOS scanner | build-validated; physical camera pending |
| Customer/account ownership | restricted development broker | **not production** |
| Device authentication | simulator challenge + HMAC | implemented development slice |
| Entitlement | DEVELOPMENT/ACTIVE | implemented development slice |
| Signer | Ed25519 service, runtime volume key | development only |
| Wire format | deterministic CBOR + Ed25519 | implemented |
| Phone secure cache | Apple Keychain ThisDeviceOnly | simulator runtime PASS |
| Phone->EFIS transfer | local HTTP simulator endpoint | end-to-end PASS |
| EFIS verification | signature/schema/product/device | PASS |
| Atomic storage | temp + rename Docker volume model | PASS at simulator level |
| Offline restart | local re-verification | PASS |
| Protected ESP32 NVS | production requirement | pending hardware |
| Physical local Wi-Fi transport | production requirement | pending hardware |
| Power interruption/brownout | production requirement | pending hardware |
| Factory secure provisioning | production requirement | pending hardware |

## 27. Failure matrix

| Failure | Required behavior |
|---|---|
| Internet/DNS/TLS unavailable | Existing licence unaffected; START EFIS unaffected |
| Account service unavailable | Existing licence unaffected; refresh deferred |
| Signer unavailable | Entitlement retained; issuance safely retryable |
| Payment webhook duplicate | Idempotent; no duplicate entitlement |
| Invalid signature | Reject candidate; retain current valid licence |
| Wrong Device ID/product | Reject |
| Interrupted install | Retain prior committed licence; discard orphan candidate |
| Corrupt stored licence | Show INVALID; preserve identity; allow replacement |
| Missing/corrupt Device ID | Identity fault; never regenerate |
| Phone lost | Re-authenticate/retrieve on another client; EFIS licence unaffected |
| No trustworthy clock | Do not invent expiry decision |

## 28. Security invariants

- Private licence signing key never enters EFIS, phone app, Git, public web tier or Docker image.
- Device-ID QR is not an authentication secret.
- Customer password never enters EFIS.
- Raw payment credentials never enter EFIS services.
- EFIS verifies every candidate independently.
- Current valid licence is not destroyed by a failed refresh.
- Trust anchors and Device ID survive Licence Reset.
- Licence and OTA trust domains remain separate.
- All imported licence bytes are hostile until bounded parsing and verification succeed.
- Production APIs require authentication, authorization, replay protection and rate limiting.

## 29. Validation status and remaining gates

**Passed in current simulator/service contract:** signed acquisition; Keychain persistence; QR generation; iOS scanner build; phone transfer; independent EFIS verification; offline transfer; offline restart persistence; tamper/bad-signature/wrong-device rejection; no-entitlement preservation; interrupted replacement; reset invariants; corrupt-store detection/recovery.

**Not yet established by simulator evidence:** physical camera scan; production account/ownership/payment flow; production signer/HSM/key recovery; physical ESP32 protected/encrypted NVS; physical maintenance Wi-Fi; real flash atomicity; brownout/power-loss installation recovery; factory provisioning; trustworthy time policy; commercial subscription/revocation/grace behavior.

No simulator result should be described as physical or production security validation.

## 30. Phone purchase and licence-management client

The iPhone service client now exposes a development implementation of the customer licence-management surface. It can load the registered-device/account state, display ownership, entitlement, current plan and transferability, list available licence products, initiate a simulated purchase, automatically retrieve/cache the resulting signed entitlement, and retain the existing Transfer to EFIS workflow.

The current purchase endpoint is deliberately **simulation only** and takes no payment. Product names/prices are development fixtures rather than an adopted commercial price list. Production purchase must replace this with authenticated account ownership plus a real payment-provider checkout flow and verified webhook before entitlement becomes ACTIVE. The phone must never treat its own button press or payment-provider redirect as proof of payment; only the server-side verified payment event may activate entitlement.

## 2026-10-05 validated iPhone licence lifecycle checkpoint

The EFIS Service iPhone application now presents licensing as four permanently accessible tabs: Licence, Purchase, Manage and Transfer. This replaces the earlier single long form and avoids critical lifecycle actions being obscured by the iOS floating tab bar.

Every licence action uses a common activity banner at the top of the active tab. Blue means information or an operation in progress, green means successful completion, amber means a warning or pending user state, and red means failure. Significant account state takes precedence over a generic account-loaded message; in particular a pending ownership transfer is shown as an amber warning.

Annual renewal cancellation and re-enablement were exercised end-to-end. Cancelling renewal leaves the current entitlement ACTIVE and changes renewal to CANCELLED. Re-enabling changes renewal to AUTO. Controls are state-aware so only the applicable action is offered.

Ownership transfer initiation and cancellation were exercised end-to-end. A pending transfer leaves the current entitlement ACTIVE, exposes Cancel Pending Transfer as the primary transfer action, and suppresses starting another transfer until the pending operation is cancelled.

Signed licences are cached in Apple Keychain. Runtime simulator testing must use a normally signed iOS Simulator build; builds made with CODE_SIGNING_ALLOWED=NO are compile-validation only and can fail Keychain access with OSStatus -34018.

Phone-to-EFIS transfer now has an explicit acknowledgement contract. HTTP success alone is insufficient. The phone requires the receiver response to contain result=INSTALLED and an installed licence with status=VALID. The EFIS receiver reaches that response only after Device-ID checking, signed-envelope verification, atomic persistence and activation. The phone then reports `Licence verified and installed on EFIS`; the returned licence ID is shown separately in the licence details rather than making the activity banner excessively tall.

Live validation used EFIS-SIM-0001. After phone transfer, the receiver reported licence VALID, class DEVELOPMENT and signing key sim-dev-1. The simulator container was then restarted while its simulated network state was offline; the same licence ID reloaded as VALID, proving persistence across restart without licence-service access.

## Zero-configuration mobile service endpoint — 5 October 2026

The RedOne customer app must not ask the user to configure a licence-service URL or change network settings. Release builds obtain the public licence API endpoint from the application build configuration (`EFISLicenceServiceURL`). The endpoint must be a publicly routable, publicly trusted HTTPS service on TCP 443 and work unchanged on ordinary Wi-Fi and cellular networks.

Debug builds may continue to use and expose the Synology development endpoint for simulator testing. That endpoint and any LAN/NAT-loopback workarounds are development-only and are prohibited from becoming release dependencies.

A Release build is not production-ready until a real `EFISLicenceServiceURL` is supplied and validated over unrelated Wi-Fi and cellular with normal iOS privacy settings enabled.
