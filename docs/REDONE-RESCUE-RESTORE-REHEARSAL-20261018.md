# RedOne OTA metadata rescue — offline byte-for-byte rehearsal

**18 October 2026. PASS offline; physical restore and recovery boot remain NOT AUTHORISED.**

The read-only/in-memory `hardware/boot-recovery-lab/tools/recovery_rescue_rehearsal.py` takes the verified fresh 16 MiB physical flash backup and its independently read 8 KiB OTA metadata snapshot. It refuses wrong lengths, differing snapshots, non-Partition-A selection, or invalid factory/A image magic.

It creates an **in-memory copy**, simulates erasing only flash range `0xf000`–`0x10fff`, verifies no OTA slot remains selected, restores the snapshot into that range and verifies that the full-image SHA-256 exactly matches the original. It confirms no byte outside the 8 KiB metadata region changed. **It never connects to the board, calls esptool, writes a file intended for flashing, or changes any device flash.**

Results with live backup:

- Full backup SHA-256 `cca94c604a405a8aa137f3978de4ec4531c7d9cec6ff5542f295f7da1f80a7b3`.
- OTA metadata SHA-256 `9286d32b483e20b5a2e2217aead6e76c8378be80762174844a4c383497e081d9`.
- After simulated erase: no selected OTA slot; after simulated restore: `ota_0` selected.
- All non-metadata bytes unchanged; full-image SHA-256 restored exactly.
- Tests cover valid round trip, mismatch, truncated backup and corrupted image header.

Reproduce offline:

```sh
python3 hardware/boot-recovery-lab/tools/recovery_rescue_rehearsal.py \
  hardware/board-backups/redone-pre-recovery-20261018-fullflash.bin \
  hardware/board-backups/redone-pre-recovery-20261018-otadata.bin
```

**Remaining safety distinction:** this does **not** prove a host-side write can safely restore the OTA region after a real interrupted recovery test, nor that recovery USB `bootA` works on hardware. No spare/disposable ESP32-S3 has been identified for a physical rescue rehearsal. Do not use a host-side write, change boot metadata, or run the factory recovery boot without an independently reviewed, separately authorised physical plan. Partition B remains NO-GO.
