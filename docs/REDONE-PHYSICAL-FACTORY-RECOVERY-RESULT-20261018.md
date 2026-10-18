# RedOne single-board physical factory recovery test — 18 October 2026

**Physical entry and return to Partition A: PASS. Recovery diagnostics: FAIL — stack overflow. Partition B: NO-GO.**

With explicit user approval, the Mac executed an ESP32-S3 ROM-bootloader operation erasing **only** the OTA selection partition `0xf000` length `0x2000`. The esptool identity check reported MAC `3c:0f:02:d6:1f:dc`, and erase completed successfully. No other region was intentionally erased or flashed.

The USB `status` response from the running factory recovery reported `running=recovery selected=recovery`; both OTA images were recognised. The factory bootloader log independently confirmed `Defaulting to factory image` and `Loaded app from partition at offset 0x20000`.

**Critical defect:** Sending the recovery USB `test` command emitted diagnostic results, then the device reported `***ERROR*** A stack overflow in task main has been detected` and rebooted into factory recovery. Diagnostics cannot be considered safe. Do not repeat `test` until the firmware defect is investigated and fixed. The diagnostic report showed memory/flash, Wi-Fi and NVS as PASS, with physical peripherals and power marked SKIP; the stack overflow invalidates any claim that the full diagnostic flow passed.

After recovery restarted, the reviewed USB `bootA` command reported `Selecting ota_0; restarting`. The bootloader then logged `Loaded app from partition at offset 0x120000`; the normal `efis_boot_lab` application started, printed `Running partition: ota_0`, and resumed heartbeats. Its compiled banner said `IMAGE B` but **that label is not the physical OTA partition**.

A fresh read-only post-return 8 KiB OTA metadata snapshot was saved privately as `hardware/board-backups/redone-after-factory-return-otadata-20261018.bin` (SHA-256 `8ba3b110139f45443d4f268d1a3373ef99a1718b71d51664531b83ee2d4b91a3`). It contains one CRC-valid sequence-1 OTA selection record pointing to `ota_0`; the other sector is erased/undefined, as expected after the factory transition and `bootA` rewrite. The original full 16 MiB backup and pre-test metadata snapshot remain unchanged and private.

**Additional observation:** The normal application printed `New image pending validation; confirming healthy after startup checks`. This is a runtime message from the deployed binary and must be separately audited against current source/rollback policy; do not infer production-grade health validation.

**Next steps:** Stop destructive tests. Investigate and fix the factory recovery `test` main-task stack overflow in source, add regression coverage, rebuild and verify the recovery binary offline. Replacing the installed factory partition would itself require a separate physical flash authorization and a new backup. No Partition B activation or security eFuse changes are authorised. The device is not certified for flight reliance.
