# EFIS Customer Mobile Apps

Native customer companion apps. They are account/licensing clients, not flight instruments.

- ios/EFISCustomer: SwiftUI, iOS 17+
- android/: Kotlin + Jetpack Compose

Shared functions: account access, instrument registration, licence status, provider-hosted payment, licence retrieval/offline activation and re-provisioning. No raw card PAN/CVV or private signing key is stored in either app. See docs/CUSTOMER_ACCOUNT_AND_APPS.md.
