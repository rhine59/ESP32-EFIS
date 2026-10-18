# RedOne resumable flash backup integrity hardening — 18 October 2026

The read-only `hardware/boot-recovery-lab/tools/backup_flash_chunks.py` now writes a private JSON manifest (`chunks-manifest.json`, mode 0600) after every successful 1 MiB read. It binds each saved chunk to the configured ESP32-S3 MAC, flash layout, offset, size and SHA-256 checksum. On resume, all recorded chunks are checked before any serial access. Unexpected, unmanifested, missing, modified or malformed chunks fail closed. The manifest is atomically replaced and synced; a stale temporary manifest aborts instead of being overwritten. A new full backup is assembled only after all sixteen chunks pass verification.

**Important:** Existing `redone-pre-recovery-20261018-fullflash.bin.chunks` predates the manifest and cannot be resumed by the new utility. This is intentional. The verified full 16 MiB backup remains untouched and independently validated. For future backups choose a **new output filename** and empty corresponding `.chunks` directory. The manifest is a local integrity record, not a digital signature; it does not defend against a malicious actor modifying both chunk data and manifest, nor guarantee a stable live flash state across independent reads.

No device flash writes or physical recovery boot were performed. The physical rescue path remains untested. Partition B remains NO-GO.
