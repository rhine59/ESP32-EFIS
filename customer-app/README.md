# EFIS Customer Mobile Apps

Native customer companion apps. They are account/licensing clients, not flight instruments.

- ios/EFISCustomer: SwiftUI, iOS 17+
- android/: Kotlin + Jetpack Compose

Shared functions: account access, instrument registration, licence status, provider-hosted payment, licence retrieval/offline activation and re-provisioning. No raw card PAN/CVV or private signing key is stored in either app. See docs/CUSTOMER_ACCOUNT_AND_APPS.md.


## Current OTA architecture

The iOS and Android prototypes now model the adopted multi-node/offline workflow: download/cache a complete signed release set while online, show offline readiness, connect to Horizon's local maintenance Wi-Fi at the aircraft, and transfer the cached set to Horizon. Horizon remains the update/security authority and delivers EIU/future-node firmware over AEF-CAN according to the release-set dependency order. The phone never signs firmware or directly programs the EIU.

Account authentication is now integrated: iOS is physically validated and Android is build-tested against the same account API with OS secure storage. OTA transfer/cryptographic release handling and the remaining server-backed licence operations still require end-to-end device validation.
