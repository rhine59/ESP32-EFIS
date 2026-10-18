#!/usr/bin/env python3
"""Offline-only OTA metadata transition simulation; no device or flash writes."""
import argparse
import json
import struct
import zlib
from pathlib import Path
from decode_otadata import decode

SIZE=8192

def simulate(snapshot):
    if len(snapshot)!=SIZE:
        raise ValueError('OTA metadata must be exactly 8192 bytes')
    initial=decode(snapshot)
    if initial['selected_slot_from_valid_metadata']!=0:
        raise ValueError('Initial snapshot must select ota_0')
    # ESP-IDF factory selection erases the two 4 KiB OTA metadata sectors.
    factory=bytes([255])*SIZE
    erased=decode(factory)
    # On recovery boot, esp_ota_set_boot_partition(ota_0) rewrites first sector
    # with sequence 1, and NEW state if bootloader rollback is enabled.
    # Simulate both possible state policies; do not treat simulation as hardware proof.
    cases=[]
    for state in (0,0xffffffff):
        after=bytearray(factory)
        struct.pack_into('<I',after,0,1)
        struct.pack_into('<I',after,24,state)
        struct.pack_into('<I',after,28,zlib.crc32(after[:4],0xffffffff)&0xffffffff)
        result=decode(after)
        cases.append({'state':'NEW' if state==0 else 'UNDEFINED',
                      'selected_slot':result['selected_slot_from_valid_metadata'],
                      'ota_a_selected':result['selected_slot_from_valid_metadata']==0})
    return {'initial_slot':initial['selected_slot_from_valid_metadata'],
            'factory_after_erase_slot':erased['selected_slot_from_valid_metadata'],
            'factory_fallback_expected':True,
            'return_to_a_cases':cases,
            'offline_simulation_only':True,
            'physical_test_authorized':False,
            'host_flash_write_authorized':False}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('snapshot',type=Path)
    a=p.parse_args()
    print(json.dumps(simulate(a.snapshot.read_bytes()),indent=2))
if __name__=='__main__':main()
