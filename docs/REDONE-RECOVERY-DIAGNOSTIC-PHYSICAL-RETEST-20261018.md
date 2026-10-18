# RedOne recovery diagnostics — physical retest after stack fix

**18 October 2026 — PASS: corrected diagnostics run without crash; return to OTA A PASS.**

The operator explicitly approved repeating the factory recovery entry test on the sole ESP32-S3. Before entry, a read-only 8 KiB OTA selection snapshot was captured privately at `hardware/board-backups/redone-before-retest-otadata-20261018.bin`, showing CRC-valid sequence 1 selecting `ota_0`. The factory image previously flashed and independently read back matched the compiled image SHA-256 `cf5e7172e77fb8704179f1eacf1692d75882bd7fc81f67ad431f97f1af477648` in its full 814560-byte image prefix.

The host erased only the 8 KiB OTA metadata partition at `0xf000`–`0x10fff`, after confirming board MAC `3c:0f:02:d6:1f:dc`. The factory recovery USB console responded to `status` with `running=recovery selected=recovery` and recognised both OTA slots.

The USB `test` command printed its complete schema-1 JSON diagnostics without the previous main-task stack overflow. Results: **3 PASS** (`memory_flash`, `wifi`, `nvs`), **7 SKIP** (`power`, `display_backlight`, `encoder_button`, `bmi088`, `bmp585`, `rm3100`, `can_smux`), **0 FAIL**. Skipped checks are **not** validated; this is a software bench test only. A subsequent `status` command returned normal recovery state, confirming the main task survived the diagnostic call.

The recovery USB `bootA` command reported `Selecting ota_0; restarting`. The bootloader independently reported `Loaded app from partition at offset 0x120000`, the normal application reported `Running partition: ota_0`, and five normal heartbeats were observed. A new private read-only OTA snapshot `hardware/board-backups/redone-after-diagnostic-retest-otadata-20261018.bin` confirms one CRC-valid sequence-1 entry selecting `ota_0`; the second OTA metadata sector is erased. No Partition B selection, NVS, eFuse or other firmware write was performed during this retest.

**Result:** physical factory entry, recovery USB status, diagnostic command stability, return-to-A, and metadata selection all passed. This closes the observed USB `test` main-task stack overflow regression. It does **not** prove all diagnostics or flight readiness, and Partition B remains NO-GO pending its independent security/health gates. RedOne is not certified for flight reliance.
