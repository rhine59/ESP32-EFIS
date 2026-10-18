#!/usr/bin/env python3
"""Read-only evidence gate for RedOne physical factory recovery; never authorizes execution."""
import argparse
import hashlib
import json
from pathlib import Path
from decode_otadata import decode

EXPECTED_MAC='3c:0f:02:d6:1f:dc'
EXPECTED_BACKUP_SHA='cca94c604a405a8aa137f3978de4ec4531c7d9cec6ff5542f295f7da1f80a7b3'
EXPECTED_OTA_SHA='9286d32b483e20b5a2e2217aead6e76c8378be80762174844a4c383497e081d9'
EXPECTED_FACTORY_SHA='5ec003355adea49738eace6bf7b262b90a5f6fa9a90b3fc156604faf24ac42fa'

def sha(data):return hashlib.sha256(data).hexdigest()

def gate(backup, ota, factory, board_mac):
    image=Path(backup).read_bytes()
    metadata=Path(ota).read_bytes()
    recovery=Path(factory).read_bytes()
    checks={
      'board_mac_matches':board_mac.lower()==EXPECTED_MAC,
      'full_backup_exact_size':len(image)==0x1000000,
      'full_backup_known_sha256':sha(image)==EXPECTED_BACKUP_SHA,
      'ota_snapshot_exact_size':len(metadata)==0x2000,
      'ota_snapshot_known_sha256':sha(metadata)==EXPECTED_OTA_SHA,
      'ota_snapshot_matches_backup':len(image)>=0x11000 and image[0xf000:0x11000]==metadata,
      'factory_partition_exact_size':len(recovery)==0x100000,
      'factory_partition_known_sha256':sha(recovery)==EXPECTED_FACTORY_SHA,
      'factory_partition_matches_backup':len(image)>=0x120000 and image[0x20000:0x120000]==recovery,
      'factory_and_a_headers_present':len(image)>0x120000 and image[0x20000]==0xe9 and image[0x120000]==0xe9,
    }
    checks['ota_selects_a']=len(metadata)==0x2000 and decode(metadata)['selected_slot_from_valid_metadata']==0
    return {'checks':checks,'offline_evidence_pass':all(checks.values()),
      'independent_physical_rescue_validation':False,
      'physical_factory_boot_authorized':False,
      'host_flash_write_authorized':False,
      'partition_b_authorized':False,
      'reason':'Offline evidence cannot validate rescue on hardware or provide explicit operator authorization'}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('backup',type=Path)
    p.add_argument('otadata',type=Path)
    p.add_argument('factory',type=Path)
    p.add_argument('--board-mac',required=True)
    args=p.parse_args()
    result=gate(args.backup,args.otadata,args.factory,args.board_mac)
    print(json.dumps(result,indent=2))
    if not result['offline_evidence_pass']:raise SystemExit(2)
if __name__=='__main__':main()
