import importlib.util
import struct
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'tools/ota_build_readiness.py'
spec = importlib.util.spec_from_file_location('ota_build_readiness', SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def table(layout):
    out = bytearray()
    for name, kind, subtype, offset, size in layout:
        out.extend(b'\xaa\x50' + struct.pack('<BBII', kind, subtype, offset, size)
                   + name.encode().ljust(16, b'\0') + b'\0' * 4)
    return bytes(out) + b'\xff' * 32


LAYOUT = [('otadata', 1, 0, 0xf000, 0x2000),
          ('recovery', 0, 0, 0x20000, 0x100000),
          ('ota_0', 0, 16, 0x120000, 0x300000),
          ('ota_1', 0, 17, 0x420000, 0x300000)]


class OfflineBuildReadiness(unittest.TestCase):
    def assess(self, image=b'\xe9' + b'\0' * 100, layout=LAYOUT):
        with tempfile.TemporaryDirectory() as tmp:
            binary, partition = Path(tmp) / 'image.bin', Path(tmp) / 'partitions.bin'
            binary.write_bytes(image)
            partition.write_bytes(table(layout))
            return module.assess(binary, partition)

    def test_compatible_never_authorises_flash(self):
        result = self.assess()
        self.assertTrue(result['compatible_for_offline_review'])
        self.assertFalse(result['physical_write_authorized'])
        self.assertFalse(result['partition_b_activation_authorized'])
        self.assertEqual(result['decision'], 'NO-GO')

    def test_wrong_recovery_layout_rejected(self):
        layout = [(*row[:3], 0x30000, row[4]) if row[0] == 'recovery' else row for row in LAYOUT]
        self.assertFalse(self.assess(layout=layout)['compatible_for_offline_review'])

    def test_oversized_binary_rejected(self):
        self.assertFalse(self.assess(image=b'\xe9' + b'\0' * 0x300000)['fits_both_ota_slots'])

    def test_non_esp_image_rejected(self):
        self.assertFalse(self.assess(image=b'\0' * 100)['compatible_for_offline_review'])

    def test_missing_ota_partition_rejected(self):
        self.assertFalse(self.assess(layout=LAYOUT[:-1])['compatible_for_offline_review'])


if __name__ == '__main__':
    unittest.main()
