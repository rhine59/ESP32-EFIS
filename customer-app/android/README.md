# Lollipop — Android

Native Kotlin/Jetpack Compose companion for RedOne, targeting Android 8 (API 26)+ and SDK 35. The Android app now follows the same user-facing process catalogue as the iOS Lollipop app and uses the same account-service authentication contract.

Authentication supports camera QR scan and `efisservice://login` deep links. A successful one-time challenge creates a 90-day server session. The raw session token is encrypted with AES-GCM using a non-exportable Android Keystore key; it is never stored as plaintext. Startup validates the token with `/v1/me`; sign-out calls `/v1/logout` and clears local state. Hard expiry requests a new five-minute single-use login email.

The home screen mirrors the iOS process catalogue: new EFIS setup, licence activation, transfer/receive, renewal, licence installation, replacement, recovery, firmware update, commissioning and diagnosis. Process screens expose the same workflow steps. Server-backed licence actions beyond the currently implemented account/session contract remain shared-service integration work; the Android client must not invent separate commercial rules.

Build from this directory with `gradle :app:assembleDebug`. The debug APK is `app/build/outputs/apk/debug/app-debug.apk`. Production release work still requires Play signing, Android App Links, production endpoint configuration, accessibility/privacy review and device testing.
