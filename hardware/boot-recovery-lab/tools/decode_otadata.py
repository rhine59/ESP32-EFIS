#!/usr/bin/env python3
"""Decode ESP-IDF v5.4 OTA select records from an offline 8 KiB dump. Read-only."""
import argparse
import json
import struct
import zlib
from pathlib import Path

STATES={0:'NEW',1:'PENDING_VERIFY',2:'VALID',3:'INVALID',4:'ABORTED',0xffffffff:'UNDEFINED'}

def decode(blob, slots=2):
    if len(blob)!=8192 or slots<1:
        raise ValueError('Expected exactly 8192 bytes and at least one OTA slot')
    entries=[]
    for off in (0,4096):
        seq=struct.unpack_from('<I',blob,off)[0]
        state=struct.unpack_from('<I',blob,off+24)[0]
        crc=struct.unpack_from('<I',blob,off+28)[0]
        expected=zlib.crc32(blob[off:off+4],0xffffffff)&0xffffffff
        valid=seq not in (0,0xffffffff) and state in (0,1,2,0xffffffff) and crc==expected
        entries.append({'sector_offset':off,'sequence':seq,'state':STATES.get(state,'UNKNOWN'),
                        'crc_matches':crc==expected,'selectable':valid,
                        'ota_slot':(seq-1)%slots if valid else None})
    candidates=[e for e in entries if e['selectable']]
    chosen=max(candidates,key=lambda e:e['sequence']) if candidates else None
    return {'entries':entries,'selected_slot_from_valid_metadata':chosen['ota_slot'] if chosen else None,
            'selected_entry_offset':chosen['sector_offset'] if chosen else None,
            'running_partition_confirmed':False,
            'note':'Metadata selection is not independent running-firmware telemetry; no boot operation performed.'}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('dump',type=Path)
    p.add_argument('--slots',type=int,default=2)
    args=p.parse_args()
    print(json.dumps(decode(args.dump.read_bytes(),args.slots),indent=2))

if __name__=='__main__':main()
