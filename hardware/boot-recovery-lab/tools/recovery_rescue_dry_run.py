#!/usr/bin/env python3
"""Offline-only RedOne recovery rescue planner; NEVER writes serial or flash."""
import argparse
import hashlib
import json
from pathlib import Path
from decode_otadata import decode

OTADATA_OFFSET=0xf000
OTADATA_LENGTH=0x2000
FACTORY_OFFSET=0x20000
FACTORY_LENGTH=0x100000
OTA_A_OFFSET=0x120000
OTA_A_LENGTH=0x300000
FLASH_LENGTH=0x1000000

def plan(backup, live_otadata=None):
    data=Path(backup).read_bytes()
    if len(data)!=FLASH_LENGTH:
        raise ValueError('Expected exact 16 MiB physical flash backup')
    ota=Path(live_otadata).read_bytes() if live_otadata else data[OTADATA_OFFSET:OTADATA_OFFSET+OTADATA_LENGTH]
    if len(ota)!=OTADATA_LENGTH:
        raise ValueError("Expected exact 8 KiB OTA metadata snapshot")
    selection=decode(ota)
    checks={
        'backup_exact_flash_size':True,
        'live_otadata_snapshot_supplied':live_otadata is not None,
        'otadata_selects_partition_a':selection['selected_slot_from_valid_metadata']==0,
        'factory_image_magic':data[FACTORY_OFFSET]==0xe9,
        'ota_a_image_magic':data[OTA_A_OFFSET]==0xe9,
    }
    return {
        'checks':checks,'backup_sha256':hashlib.sha256(data).hexdigest(),
        'otadata_sha256':hashlib.sha256(ota).hexdigest(),
        'otadata_offset':hex(OTADATA_OFFSET),'otadata_size':OTADATA_LENGTH,
        'selected_ota_slot':selection['selected_slot_from_valid_metadata'],
        'offline_snapshot_usable':all(checks.values()),
        'write_authorized':False,'recovery_boot_authorized':False,
        'rescue_path_physically_validated':False,
        'warning':'Restore of 8 KiB OTA metadata would be a flash erase/write requiring separate approval and board identity verification. Never restore full flash casually; NVS contains credentials.'}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('backup',type=Path)
    p.add_argument('--live-otadata',type=Path)
    a=p.parse_args()
    print(json.dumps(plan(a.backup,a.live_otadata),indent=2))
if __name__=='__main__':main()
