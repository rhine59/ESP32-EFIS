#!/usr/bin/env python3
"""Generate a PRIVATE bench credential bundle; NEVER flashes the device.

CAUTION: generated NVS image represents a full NVS partition and would
REPLACE all existing NVS data if flashed. Do not flash on provisioned boards.
"""
import argparse
import csv
import os
from pathlib import Path
import secrets
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True, help='Private output directory')
    parser.add_argument('--idf-path', type=Path, default=Path.home()/'.espressif/v5.4.4/esp-idf')
    args = parser.parse_args()
    out = args.output.expanduser().resolve()
    out.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(out, 0o700)
    if any(out.iterdir()):
        parser.error('Output directory must be empty to prevent overwriting credentials')
    password = secrets.token_urlsafe(24)
    token = secrets.token_urlsafe(36)
    with tempfile.TemporaryDirectory(prefix='redone-nvs-') as temp:
        csv_path = Path(temp)/'credentials.csv'
        with csv_path.open('w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['key', 'type', 'encoding', 'value'])
            writer.writerow(['lab_auth', 'namespace', '', ''])
            writer.writerow(['ap_password', 'data', 'string', password])
            writer.writerow(['token', 'data', 'string', token])
        generator = args.idf_path/'components/nvs_flash/nvs_partition_generator/nvs_partition_gen.py'
        if not generator.is_file():
            parser.error('ESP-IDF NVS generator missing')
        image = out/'bench-nvs-DO-NOT-FLASH.bin'
        idf_python = Path.home()/'.espressif/tools/python/v5.4.4/venv/bin/python'
        if not idf_python.is_file():
            parser.error('Pinned ESP-IDF Python missing')
        subprocess.run([str(idf_python), str(generator), 'generate', str(csv_path), str(image), '0x6000'], check=True)
    os.chmod(image, 0o600)
    instructions = out/'PRIVATE-CREDENTIALS.txt'
    instructions.write_text('BENCH ONLY - KEEP PRIVATE - NEVER COMMIT\n'
                            f'Wi-Fi password: {password}\nX-Lab-Token: {token}\n'
                            'The generated NVS image replaces the WHOLE NVS partition.\n'
                            'DO NOT flash it to a device with existing NVS data.\n')
    os.chmod(instructions, 0o600)
    print(f'Created private credential bundle in {out}')
    print('No secrets displayed. No hardware modified.')
    print('WARNING: full NVS image is NOT safe to flash over existing device NVS.')


if __name__ == '__main__':
    main()
