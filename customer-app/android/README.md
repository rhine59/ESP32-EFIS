# EFIS Customer — Android

Native Kotlin/Jetpack Compose customer companion. Initial skeleton uses mock data until authenticated API contracts are frozen.

Production authentication/session tokens should use Android Keystore-backed secure storage. No card PAN/CVV storage. Checkout uses provider-hosted/SDK flows including Google Pay where enabled.
