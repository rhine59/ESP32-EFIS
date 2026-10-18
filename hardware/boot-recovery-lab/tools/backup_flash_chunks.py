#!/usr/bin/env python3
"""Read-only RedOne flash backup with authenticated, fail-closed chunk resumability."""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

SIZE=0x1000000
CHUNK=0x100000
EXPECTED_MAC='3c:0f:02:d6:1f:dc'
MANIFEST_NAME='chunks-manifest.json'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def manifest_template():
    return {'schema':1,'chip':'esp32s3','mac':EXPECTED_MAC,'flash_size':SIZE,
            'chunk_size':CHUNK,'chunks':{}}

def save_manifest(path, data):
    tmp=path.with_name(path.name+'.tmp')
    if tmp.exists():
        raise ValueError('Unresolved manifest temporary file; inspect before proceeding')
    with tmp.open('x') as f:
        os.chmod(tmp,0o600)
        json.dump(data,f,sort_keys=True,indent=2)
        f.flush();os.fsync(f.fileno())
    tmp.replace(path)

def load_manifest(directory):
    path=directory/MANIFEST_NAME
    if not path.exists():
        if any(directory.iterdir()):
            raise ValueError('Untrusted legacy chunks exist without a manifest; use a NEW output path')
        return manifest_template()
    data=json.loads(path.read_text())
    expected=manifest_template()
    if not isinstance(data,dict) or any(data.get(k)!=v for k,v in expected.items() if k!='chunks') or not isinstance(data.get('chunks'),dict):
        raise ValueError('Chunk manifest device identity or layout mismatch')
    return data

def trusted_chunk(path, index, manifest):
    record=manifest['chunks'].get(str(index))
    if record is None:
        if path.exists():
            raise ValueError(f'Unmanifested chunk {index}: refusing reuse or overwrite')
        return False
    if not isinstance(record,dict) or record.get('offset')!=index*CHUNK or record.get('length')!=CHUNK or not re.fullmatch('[a-f0-9]{64}',str(record.get('sha256',''))):
        raise ValueError(f'Invalid manifest record for chunk {index}')
    if not path.is_file() or path.is_symlink() or path.stat().st_size!=CHUNK or sha(path.read_bytes())!=record['sha256']:
        raise ValueError(f'Chunk {index} differs from authenticated manifest; aborting')
    return True

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--port',default='/dev/cu.usbmodem1101')
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--retries',type=int,default=4)
    a=p.parse_args()
    if not 1<=a.retries<=10:p.error('retries must be 1..10')
    if a.output.exists():p.error('Output already exists; refusing overwrite')
    directory=a.output.parent/(a.output.name+'.chunks')
    directory.mkdir(mode=0o700,parents=True,exist_ok=True)
    os.chmod(directory,0o700)
    manifest=load_manifest(directory)
    manifest_path=directory/MANIFEST_NAME
    # Verify ALL recorded chunks before contacting the board, not just the next chunk.
    for i in range(SIZE//CHUNK):
        trusted_chunk(directory/f'chunk-{i:02d}.bin',i,manifest)
    for i in range(SIZE//CHUNK):
        path=directory/f'chunk-{i:02d}.bin'
        if trusted_chunk(path,i,manifest):
            print(f'Chunk {i+1}/16 authenticated and reused',flush=True)
            continue
        for attempt in range(a.retries):
            cmd=[sys.executable,'-m','esptool','--chip','esp32s3','--port',a.port,'--baud','921600',
                 'read_flash','--no-progress',hex(i*CHUNK),hex(CHUNK),str(path)]
            try:
                result=subprocess.run(cmd,capture_output=True,text=True,timeout=85)
                log=result.stdout+'\n'+result.stderr
                if result.returncode==0 and EXPECTED_MAC in log and path.is_file() and not path.is_symlink() and path.stat().st_size==CHUNK:
                    os.chmod(path,0o600)
                    manifest['chunks'][str(i)]={'offset':i*CHUNK,'length':CHUNK,'sha256':sha(path.read_bytes())}
                    save_manifest(manifest_path,manifest)
                    print(f'Chunk {i+1}/16 captured and recorded',flush=True)
                    break
                print(f'Chunk {i+1}/16 attempt {attempt+1}: failed',flush=True)
            except subprocess.TimeoutExpired:
                print(f'Chunk {i+1}/16 attempt {attempt+1}: timeout',flush=True)
            if path.exists():path.unlink()
        else:
            print('INCOMPLETE: no full backup assembled',flush=True)
            return 2
    tmp=a.output.with_name(a.output.name+'.assembling')
    if tmp.exists():raise ValueError('Existing assembly file; refusing overwrite')
    with tmp.open('xb') as f:
        os.chmod(tmp,0o600)
        for i in range(SIZE//CHUNK):
            path=directory/f'chunk-{i:02d}.bin'
            if not trusted_chunk(path,i,manifest):raise ValueError('Missing authenticated chunk')
            f.write(path.read_bytes())
        f.flush();os.fsync(f.fileno())
    if tmp.stat().st_size!=SIZE:
        raise ValueError('Assembled backup wrong length')
    tmp.replace(a.output)
    print(f'COMPLETE {a.output} sha256={sha(a.output.read_bytes())}',flush=True)
    return 0
if __name__=='__main__':sys.exit(main())
