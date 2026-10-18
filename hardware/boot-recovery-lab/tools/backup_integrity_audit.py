#!/usr/bin/env python3
"""Offline integrity audit of RedOne's chunked backup; no device access or writes."""
import argparse
import hashlib
import json
from pathlib import Path

FLASH_SIZE=0x1000000
CHUNK_SIZE=0x100000
OTA_START=0xf000
OTA_END=0x11000
FACTORY_START=0x20000
FACTORY_END=0x120000

def digest(data):
    return hashlib.sha256(data).hexdigest()

def audit(backup, chunk_dir, ota, factory=None):
    image=Path(backup).read_bytes()
    snapshot=Path(ota).read_bytes()
    if len(image)!=FLASH_SIZE or len(snapshot)!=OTA_END-OTA_START:
        raise ValueError('Invalid full backup or OTA snapshot length')
    if image[OTA_START:OTA_END]!=snapshot:
        raise ValueError('Current OTA snapshot differs from full backup')
    if factory is not None:
        factory_data=Path(factory).read_bytes()
        if len(factory_data)!=FACTORY_END-FACTORY_START or image[FACTORY_START:FACTORY_END]!=factory_data:
            raise ValueError('Factory recovery differs from independently read image')
    chunk_hashes=[]
    for i in range(FLASH_SIZE//CHUNK_SIZE):
        path=Path(chunk_dir)/f'chunk-{i:02d}.bin'
        content=path.read_bytes()
        if len(content)!=CHUNK_SIZE or content!=image[i*CHUNK_SIZE:(i+1)*CHUNK_SIZE]:
            raise ValueError(f'Chunk {i} missing, truncated or different from assembled backup')
        chunk_hashes.append(digest(content))
    return {'full_backup_sha256':digest(image), 'otadata_sha256':digest(snapshot),
            'factory_independently_compared':factory is not None,
            'verified_chunk_count':len(chunk_hashes), 'chunk_sha256':chunk_hashes,
            'integrity_pass':True,'physical_boot_authorized':False,
            'flash_write_authorized':False}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('backup',type=Path)
    p.add_argument('chunk_directory',type=Path)
    p.add_argument('otadata',type=Path)
    p.add_argument('--factory',type=Path)
    args=p.parse_args()
    print(json.dumps(audit(args.backup,args.chunk_directory,args.otadata,args.factory),indent=2))
if __name__=='__main__':main()
