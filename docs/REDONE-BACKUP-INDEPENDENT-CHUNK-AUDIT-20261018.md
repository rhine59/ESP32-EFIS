# RedOne independent chunk integrity audit — 18 October 2026

**PASS (offline integrity); physical recovery boot remains NO-GO.**

The new read-only `hardware/boot-recovery-lab/tools/backup_integrity_audit.py` independently compares all sixteen original 1 MiB chunks with their exact offsets in the assembled 16 MiB backup. It also checks the separately captured 8 KiB OTA snapshot and optional independently captured 1 MiB factory recovery image. Wrong lengths, missing chunks and altered bytes fail closed. The audit does not access the device or authorise flash writes.

Observed full backup SHA-256: `cca94c604a405a8aa137f3978de4ec4531c7d9cec6ff5542f295f7da1f80a7b3`. Sixteen chunks matched; current OTA selection snapshot matched; separately captured factory recovery matched. All 40 boot-recovery-lab Python tests passed.

Run locally:

```sh
python3 hardware/boot-recovery-lab/tools/backup_integrity_audit.py \
  hardware/board-backups/redone-pre-recovery-20261018-fullflash.bin \
  hardware/board-backups/redone-pre-recovery-20261018-fullflash.bin.chunks \
  hardware/board-backups/redone-pre-recovery-20261018-otadata.bin \
  --factory /tmp/redone-live-factory-recovery-20261018.bin
```

**Caution:** the original chunked backup utility reuses previously existing chunks based only on file size, not stored hashes or chip identity. A subsequent backup run should therefore use a new output path and new chunk directory, or independently audit all reused chunks. The fresh full backup here was independently audited. Further development should add cryptographically authenticated resumability and board-identity binding.

No physical rescue or factory recovery boot was performed. A physical OTA metadata write remains untested and requires separate explicit approval; Partition B remains NO-GO.
