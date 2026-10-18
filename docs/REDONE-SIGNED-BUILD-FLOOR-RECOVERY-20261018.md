# RedOne signed release minimum-build validation in factory recovery

**Offline source and build checkpoint, 18 October 2026. No device writes.**

The factory recovery signed-envelope verifier now requires the `minimum_allowed_version` field, **after successful Ed25519 verification**, to be a canonical `build:<int32>` claim. The parser rejects empty strings, leading zeros, signs, non-digits and integer overflow; it also rejects a signed minimum greater than the candidate release's signed `build` value. On success the verified metadata carries the parsed `signed_minimum_build` integer alongside the original claim. Existing signed legacy `0.0.0` metadata will be rejected until a publisher signs a compatible new manifest; do not edit a signed manifest in place.

This change does **not** compare the signed minimum against a trusted hardware-protected installed build floor: the backend remains unimplemented. It does **not** enable staging, flash writes, OTA boot selection or Partition B. Source-level tests are not substitutes for device-side positive/negative signed-envelope tests. The recovery firmware was rebuilt successfully using pinned ESP-IDF 5.4.4 and fits the factory partition. The newly built binary is **not deployed**; the physical board retains the previously tested recovery firmware.
