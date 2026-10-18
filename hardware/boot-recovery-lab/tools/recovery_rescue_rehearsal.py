#!/usr/bin/env python3
"""Offline-only recovery metadata rescue rehearsal on an in-memory copy of a backup."""
import argparse
import hashlib
import json
from pathlib import Path
from decode_otadata import decode

FLASH_SIZE = 0x1000000
OTA_OFFSET = 0xf000
OTA_SIZE = 0x2000
FACTORY_OFFSET = 0x20000
A_OFFSET = 0x120000

def rehearse(backup_bytes, snapshot_bytes):
    if len(backup_bytes) != FLASH_SIZE or len(snapshot_bytes) != OTA_SIZE:
        raise ValueError('Expected exactly 16 MiB backup and 8 KiB metadata snapshot')
    before = decode(snapshot_bytes)
    if before['selected_slot_from_valid_metadata'] != 0:
        raise ValueError('Refusing snapshot that does not select Partition A')
    if backup_bytes[OTA_OFFSET:OTA_OFFSET + OTA_SIZE] != snapshot_bytes:
        raise ValueError('Snapshot differs from full backup; do not proceed')
    if backup_bytes[FACTORY_OFFSET] != 0xe9 or backup_bytes[A_OFFSET] != 0xe9:
        raise ValueError('Factory/Partition A image header mismatch')
    # Only mutate private in-memory bytes. No device, esptool or output flash image.
    work = bytearray(backup_bytes)
    original_hash = hashlib.sha256(work).hexdigest()
    work[OTA_OFFSET:OTA_OFFSET + OTA_SIZE] = b'\xff' * OTA_SIZE
    erased = decode(work[OTA_OFFSET:OTA_OFFSET + OTA_SIZE])
    if erased['selected_slot_from_valid_metadata'] is not None:
        raise AssertionError('Erase simulation did not invalidate OTA selection')
    work[OTA_OFFSET:OTA_OFFSET + OTA_SIZE] = snapshot_bytes
    restored = decode(work[OTA_OFFSET:OTA_OFFSET + OTA_SIZE])
    restored_hash = hashlib.sha256(work).hexdigest()
    return {
        'backup_sha256': original_hash,
        'metadata_sha256': hashlib.sha256(snapshot_bytes).hexdigest(),
        'erased_ota_selection': erased['selected_slot_from_valid_metadata'],
        'restored_ota_selection': restored['selected_slot_from_valid_metadata'],
        'all_non_metadata_bytes_unchanged': (work[:OTA_OFFSET] == backup_bytes[:OTA_OFFSET] and
            work[OTA_OFFSET + OTA_SIZE:] == backup_bytes[OTA_OFFSET + OTA_SIZE:]),
        'full_image_hash_restored': restored_hash == original_hash,
        'offline_rehearsal_pass': restored['selected_slot_from_valid_metadata'] == 0 and restored_hash == original_hash,
        'physical_rescue_tested': False,
        'physical_write_authorized': False,
        'physical_recovery_boot_authorized': False,
    }

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('full_backup', type=Path)
    p.add_argument('otadata_snapshot', type=Path)
    args = p.parse_args()
    print(json.dumps(rehearse(args.full_backup.read_bytes(), args.otadata_snapshot.read_bytes()), indent=2))
if __name__ == '__main__':
    main()
