# Physical RedOne Wi-Fi OTA — issue resolution plan (19 October 2026)

**Decision: NO-GO for flash writes, boot-slot selection and physical rollback on the sole ESP32-S3.** The operator wants to repeat upgrade → activate → rollback on the real board. This request authorizes investigation and read-only Wi-Fi tests, **not** an irreversible security/eFuse operation or bypass of a known unsafe gate.

## Confirmed code findings

- The iOS Update EFIS page already reads authenticated physical status, and the physical Push / Verify / Activate / Rollback buttons are intentionally disabled. Its adjacent `RedOneDeploymentSimulator` is a separate local/Synology simulator, not physical hardware.
- The readiness CLI currently reports `physical_write_authorized=false` and `partition_b_activation_authorized=false`. Physical board was last confirmed booting OTA A; see `REDONE-LIVE-RUNNING-PARTITION-20261018.md`.
- On-device publisher signature enforcement, hardware-backed trusted monotonic floor, true pending-verify health confirmation, independently demonstrated A/B rollback, and power-interruption recovery are not all evidenced. The documented build has secure boot, flash encryption and hardware anti-rollback disabled. Do not treat HTTPS, SHA-256, green status or an app-side signature check as an on-device trust anchor.

## Resolution sequence

1. **Read-only physical connection:** Join `RedOne_<MAC>` from the phone, read authenticated EFIS status, confirm device identity, running slot, version, API, reported rollback and boot state. Compare to USB serial read-only partition/boot logs. Capture sanitized logs without tokens, credentials or Wi-Fi password.
2. **Separate physical and simulator UI:** Clearly mark simulator actions and display a physical NO-GO reason. This change is UI-only; it does not unlock writes.
3. **Trusted update transport:** Define and implement authenticated signed release metadata and binary verification **on the ESP32**, with negative tests for corrupt, unsigned, wrong-hardware and replayed images. Pin an appropriate publisher trust root on device.
4. **Version and recovery policy:** Design/test protected build-floor storage and secure-boot/anti-rollback behavior on a separate sacrificial ESP32-S3. Do not enable irreversible eFuses on the sole RedOne. Confirm factory recovery remains bootable across security epochs.
5. **Boot-health implementation:** Wire real sensor/display/power/identity/rollback evidence and ground confirmation to pending-verify state; prove fail-closed behavior across resets and watchdogs.
6. **Dedicated-board fault tests:** Exercise transfer interruption, staged readback, activation, failed first boot, automatic/manual rollback, lost Wi-Fi and recovery. Record actual partition hashes and before/after selection. Repeat after power cuts.
7. **Physical RedOne authorisation:** Once independent tests and backup/recovery verification pass, request narrowly scoped operator approval for the exact image, inactive partition and write operation; only then enable phone-app physical actions.

## Verification status

This report records blockers and the safe implementation order; it is **not** evidence that the remaining hardware/security gates have been resolved. Until those gates are closed, the full physical upgrade/activate/rollback test cannot safely be completed.
