#!/usr/bin/env python3
"""Create an 8-KiB OTA selection image from a live otadata backup.

Writes only a local file; use esptool separately after checking the device.
ESP-IDF OTA select CRC is zlib.crc32(seq_bytes, 0xffffffff).
"""
import argparse
import struct
import zlib
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('backup',type=Path)
parser.add_argument('slot',choices=['ota_0','ota_1'])
parser.add_argument('output',type=Path)
a=parser.parse_args()
data=bytearray(a.backup.read_bytes())
if len(data)!=8192: raise SystemExit('otadata must be exactly 8192 bytes')
valid=[]
for offset in (0,4096):
    seq,=struct.unpack_from('<I',data,offset)
    crc,=struct.unpack_from('<I',data,offset+28)
    if seq!=0xffffffff and crc==zlib.crc32(struct.pack('<I',seq),0xffffffff):
        valid.append((seq,offset))
if not valid: raise SystemExit('No valid OTA selection entry; refusing')
current=max(valid)[0]
# With two slots, odd seq selects ota_0 and even seq selects ota_1.
new_seq=current+1
if (new_seq-1)%2 != (0 if a.slot=='ota_0' else 1): new_seq+=1
if new_seq>=0xffffffff: raise SystemExit('OTA sequence overflow')
# Rewrite inactive entry; keep the current valid entry as fallback.
offset=4096 if max(valid)[1]==0 else 0
data[offset:offset+32]=b'\xff'*32
struct.pack_into('<I',data,offset,new_seq)
struct.pack_into('<I',data,offset+24,2) # ESP_OTA_IMG_VALID
struct.pack_into('<I',data,offset+28,zlib.crc32(struct.pack('<I',new_seq),0xffffffff))
a.output.write_bytes(data)
print(f'Generated {a.output} with {a.slot} seq={new_seq}, retained previous selection')
