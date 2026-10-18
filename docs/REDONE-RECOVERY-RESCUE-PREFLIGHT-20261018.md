# Physical RedOne recovery rescue preparation — 18 October 2026

**Result: offline snapshot preflight PASS; physical recovery boot and flash rescue NOT AUTHORISED.** No flash erase/write or eFuse change was performed.

## Live OTA metadata backup

- Read a fresh 8,192-byte OTA selection snapshot from physical board address `0xf000` into ignored local `hardware/board-backups/redone-pre-recovery-20261018-otadata.bin`, permissions `0600`.
- SHA-256 `9286d32b483e20b5a2e2217aead6e76c8378be80762174844a4c383497e081d9`.
- Decoder confirms latest valid selection `ota_0`, matching earlier live bootloader and application observations.
- Previous full-flash backup SHA-256 `e1a901cd87a961fe28c946981ddb909bd6e014873cbd9c67357c535f7ec7aa80` is intact but its embedded OTA metadata is **stale** and cannot be used as the current boot-selection snapshot.

## Full-flash snapshot caveat

A new 16 MiB read was started, then stopped because serial transfer was progressing very slowly. The incomplete file was removed. **No fresh full-flash backup was completed**; this remains a mandatory precondition before any physical recovery boot. The older complete backup remains available and ignored by Git. Do not infer that the existing full backup reflects all current flash state.

## Offline rescue planner

`hardware/boot-recovery-lab/tools/recovery_rescue_dry_run.py` accepts an exact 16 MiB backup and a separate fresh 8 KiB OTA snapshot (`--live-otadata`). It checks lengths, current OTA selection and image headers and reports hashes without revealing NVS contents. It **never** connects to the device, writes flash or authorises a restore. Reproduce:

```sh
python3 hardware/boot-recovery-lab/tools/recovery_rescue_dry_run.py \
  hardware/board-backups/esp32s3-3c0f02d61fdc-20261018-fullflash.bin \
  --live-otadata hardware/board-backups/redone-pre-recovery-20261018-otadata.bin
```

All offline checks passed. `write_authorized`, `recovery_boot_authorized` and `rescue_path_physically_validated` remain `false`. A possible host-side recovery of OTA metadata would entail an explicit, safeguarded 8 KiB flash write after physical identity confirmation and separate approval; no executable write procedure has been validated.

## Remaining gates

1. Complete and verify a fresh 16 MiB full-flash backup immediately before physical test.
2. Review and rehearse a safe, identity-checked OTA-metadata-only rescue procedure on an expendable device or simulator.
3. Establish reliable USB console monitoring and a supervised return-to-A checklist.
4. Obtain separate explicit approval for the factory boot's OTA metadata erase.

**NO-GO** for physical recovery boot, flash restore and Partition B deployment.
