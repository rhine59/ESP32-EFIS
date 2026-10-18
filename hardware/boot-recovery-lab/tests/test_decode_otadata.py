import importlib.util
import struct
import unittest
import zlib
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'tools/decode_otadata.py'
spec=importlib.util.spec_from_file_location('decode_otadata',P)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

def entry(seq,state=2,valid_crc=True):
    b=bytearray(b'\xff'*4096)
    struct.pack_into('<I',b,0,seq)
    struct.pack_into('<I',b,24,state)
    crc=zlib.crc32(b[:4],0xffffffff)&0xffffffff
    struct.pack_into('<I',b,28,crc if valid_crc else crc^1)
    return bytes(b)

class TestDecode(unittest.TestCase):
    def test_latest_valid(self):
        d=m.decode(entry(4)+entry(5))
        self.assertEqual(d['selected_slot_from_valid_metadata'],0)
        self.assertFalse(d['running_partition_confirmed'])
    def test_bad_crc_ignored(self):
        self.assertEqual(m.decode(entry(4)+entry(5,valid_crc=False))['selected_slot_from_valid_metadata'],1)
    def test_aborted_ignored(self):
        self.assertEqual(m.decode(entry(4)+entry(5,state=4))['selected_slot_from_valid_metadata'],1)
    def test_empty_fail_closed(self):
        self.assertIsNone(m.decode(b'\xff'*8192)['selected_slot_from_valid_metadata'])
    def test_wrong_length(self):
        with self.assertRaises(ValueError):m.decode(b'\xff'*16)

if __name__=='__main__':unittest.main()
