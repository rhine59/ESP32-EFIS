#!/usr/bin/env python3
"""Read-only chunked flash backup with per-chunk retry and fail-closed assembly."""
import argparse
import hashlib
import os
import subprocess
import sys
from pathlib import Path

SIZE=0x1000000
CHUNK=0x100000
EXPECTED_MAC='3c:0f:02:d6:1f:dc'

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--port',default='/dev/cu.usbmodem1101')
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--retries',type=int,default=4)
    a=p.parse_args()
    if a.retries<1 or a.retries>10: p.error('retries must be 1..10')
    if a.output.exists(): p.error('Output already exists; refusing overwrite')
    directory=a.output.parent/(a.output.name+'.chunks')
    directory.mkdir(mode=0o700,parents=True,exist_ok=True)
    os.chmod(directory,0o700)
    for index in range(SIZE//CHUNK):
        path=directory/f'chunk-{index:02d}.bin'
        if path.exists() and path.stat().st_size==CHUNK:
            print(f'Chunk {index+1}/16 already captured; reusing',flush=True)
            continue
        if path.exists(): path.unlink()
        for attempt in range(a.retries):
            cmd=[sys.executable,'-m','esptool','--chip','esp32s3','--port',a.port,'--baud','921600',
                 'read_flash','--no-progress',hex(index*CHUNK),hex(CHUNK),str(path)]
            try:
                result=subprocess.run(cmd,capture_output=True,text=True,timeout=85)
                log=result.stdout+'\n'+result.stderr
                if result.returncode==0 and EXPECTED_MAC in log and path.exists() and path.stat().st_size==CHUNK:
                    os.chmod(path,0o600)
                    print(f'Chunk {index+1}/16 verified; sha256={hashlib.sha256(path.read_bytes()).hexdigest()}',flush=True)
                    break
                print(f'Chunk {index+1}/16 attempt {attempt+1}: failed (exit {result.returncode})',flush=True)
            except subprocess.TimeoutExpired:
                print(f'Chunk {index+1}/16 attempt {attempt+1}: connection timeout',flush=True)
            if path.exists(): path.unlink()
        else:
            print('INCOMPLETE: no full backup assembled; no flash writes',flush=True)
            return 2
    tmp=a.output.with_name(a.output.name+'.assembling')
    if tmp.exists(): tmp.unlink()
    with tmp.open('xb') as f:
        os.chmod(tmp,0o600)
        for index in range(SIZE//CHUNK):
            f.write((directory/f'chunk-{index:02d}.bin').read_bytes())
    if tmp.stat().st_size!=SIZE:
        tmp.unlink();raise ValueError('Assembled backup wrong length')
    tmp.replace(a.output)
    print(f'COMPLETE {a.output} sha256={hashlib.sha256(a.output.read_bytes()).hexdigest()}',flush=True)
    return 0
if __name__=='__main__':sys.exit(main())
