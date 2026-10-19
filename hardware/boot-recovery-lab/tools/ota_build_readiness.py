#!/usr/bin/env python3
"""Offline OTA binary/partition compatibility check; NEVER authorises flashing."""
import argparse
import hashlib
import json
import struct
from pathlib import Path


def assess(binary: Path, partition_table: Path) -> dict:
    image = binary.read_bytes()
    raw = partition_table.read_bytes()
    partitions = {}
    for offset in range(0, len(raw), 32):
        entry = raw[offset:offset + 32]
        if len(entry) != 32 or entry[:2] == b'\xff\xff':
            break
        if entry[:2] != b'\xaa\x50':
            continue  # ESP-IDF partition table MD5 record
        kind, subtype, address, size = struct.unpack_from('<BBII', entry, 2)
        name = entry[12:28].split(b'\0', 1)[0].decode('ascii')
        if name in partitions:
            raise ValueError('Duplicate partition name: ' + name)
        partitions[name] = dict(kind=kind, subtype=subtype, offset=address, size=size)
    expected = {
        'recovery': (0, 0, 0x20000, 0x100000),
        'ota_0': (0, 16, 0x120000, 0x300000),
        'ota_1': (0, 17, 0x420000, 0x300000),
        'otadata': (1, 0, 0xf000, 0x2000),
    }
    layout_ok = all(
        name in partitions and tuple(partitions[name][key] for key in ('kind', 'subtype', 'offset', 'size')) == values
        for name, values in expected.items()
    )
    image_header_ok = len(image) >= 24 and image[0] == 0xe9
    fits_ota = all(name in partitions and len(image) <= partitions[name]['size'] for name in ('ota_0', 'ota_1'))
    return {
        'audit': 'offline-build-only',
        'image_bytes': len(image),
        'image_sha256': hashlib.sha256(image).hexdigest(),
        'partition_table_sha256': hashlib.sha256(raw).hexdigest(),
        'esp_image_header_present': image_header_ok,
        'expected_partition_layout': layout_ok,
        'fits_both_ota_slots': fits_ota,
        'compatible_for_offline_review': image_header_ok and layout_ok and fits_ota,
        'physical_write_authorized': False,
        'partition_b_activation_authorized': False,
        'decision': 'NO-GO',
        'warning': 'Do not use idf.py flash: this build configuration maps the application to factory recovery.',
    }


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary', type=Path, default=root / 'build-secure-ota/efis_boot_lab.bin')
    parser.add_argument('--partition-table', type=Path, default=root / 'build-secure-ota/partition_table/partition-table.bin')
    args = parser.parse_args()
    print(json.dumps(assess(args.binary, args.partition_table), indent=2))


if __name__ == '__main__':
    main()
