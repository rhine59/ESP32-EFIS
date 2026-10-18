import importlib.util
import struct
import sys
import unittest
import zlib
from pathlib import Path
P = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(P))
spec = importlib.util.spec_from_file_location('recovery_rescue_rehearsal', P / 'recovery_rescue_rehearsal.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class TestRescueRehearsal(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.image = bytearray(b'\xff' * m.FLASH_SIZE)
        cls.image[m.FACTORY_OFFSET] = 0xe9
        cls.image[m.A_OFFSET] = 0xe9
        for index, seq in enumerate((4, 5)):
            off = m.OTA_OFFSET + index * 4096
            struct.pack_into('<I', cls.image, off, seq)
            struct.pack_into('<I', cls.image, off + 24, 2)
            struct.pack_into('<I', cls.image, off + 28, zlib.crc32(cls.image[off:off+4], 0xffffffff))
        cls.snapshot = bytes(cls.image[m.OTA_OFFSET:m.OTA_OFFSET + m.OTA_SIZE])

    def test_roundtrip_is_byte_exact_and_never_authorizes_writes(self):
        result = m.rehearse(bytes(self.image), self.snapshot)
        self.assertTrue(result['offline_rehearsal_pass'])
        self.assertTrue(result['all_non_metadata_bytes_unchanged'])
        self.assertFalse(result['physical_write_authorized'])
        self.assertFalse(result['physical_rescue_tested'])

    def test_rejects_mismatched_snapshot(self):
        snapshot = bytearray(self.snapshot)
        snapshot[-1] ^= 1
        with self.assertRaises(ValueError):
            m.rehearse(bytes(self.image), bytes(snapshot))

    def test_rejects_truncated_backup(self):
        with self.assertRaises(ValueError):
            m.rehearse(bytes(self.image[:-1]), self.snapshot)

    def test_rejects_corrupt_image_header(self):
        bad = bytearray(self.image)
        bad[m.A_OFFSET] = 0
        with self.assertRaises(ValueError):
            m.rehearse(bytes(bad), self.snapshot)
