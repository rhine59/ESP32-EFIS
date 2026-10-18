#!/usr/bin/env python3
"""Local-only, operator-initiated bench provisioning over physically attached USB.

Run this script ON THE MAC, not through a remote execution service. No
credentials are passed as command-line arguments or written to a log.
"""
import argparse
from pathlib import Path
import sys
import time


def load_credentials(path):
    values = {}
    for line in path.read_text().splitlines():
        for key in ('Wi-Fi password', 'X-Lab-Token'):
            if line.startswith(key + ': '):
                values[key] = line[len(key) + 2:]
    password, token = values.get('Wi-Fi password', ''), values.get('X-Lab-Token', '')
    if not (16 <= len(password) <= 63 and 32 <= len(token) <= 64):
        raise ValueError('Missing or invalid private credentials')
    return password, token


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', default='/dev/cu.usbmodem1101')
    parser.add_argument('--credentials', type=Path, default=Path(__file__).resolve().parent.parent / 'private-credentials/PRIVATE-CREDENTIALS.txt')
    args = parser.parse_args()
    if not args.credentials.is_file():
        parser.error('Private credentials missing: generate them offline first')
    password, token = load_credentials(args.credentials)
    try:
        import serial
    except ImportError:
        parser.error('pyserial required: use the pinned ESP-IDF Python environment')
    print('WARNING: physically connected BENCH hardware only. NVS keys will change.')
    print('Do not use on an aircraft or through a remotely shared terminal.')
    if input('Type PROVISION to confirm: ').strip() != 'PROVISION':
        print('Cancelled without writing'); return
    with serial.Serial(args.port, 115200, timeout=0.5, dsrdtr=False, rtscts=False) as port:
        port.dtr = False
        port.rts = False
        time.sleep(1)
        port.reset_input_buffer()
        port.write(b'provision\n')
        time.sleep(0.4)
        port.write(password.encode('ascii') + b'\n')
        time.sleep(0.4)
        port.write(token.encode('ascii') + b'\n')
        deadline = time.monotonic() + 8
        result = None
        while time.monotonic() < deadline:
            line = port.readline().decode('utf-8', errors='replace')
            if 'Bench credentials saved without NVS erase' in line:
                result = True; break
            if 'Provisioning failed' in line or 'Provisioning rejected' in line:
                result = False; break
    if result is True:
        print('PASS: Device acknowledged NVS credential commit. Reboot board to enable AP.')
    else:
        print('UNCONFIRMED: Device did not acknowledge successful provisioning.')
        sys.exit(1)


if __name__ == '__main__':
    main()
