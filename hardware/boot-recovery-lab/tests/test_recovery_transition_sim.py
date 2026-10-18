import importlib.util
import struct
import sys
import unittest
import zlib
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'tools';sys.path.insert(0,str(P))
spec=importlib.util.spec_from_file_location('recovery_transition_sim',P/'recovery_transition_sim.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class TestTransitions(unittest.TestCase):
    def test_both_return_states_select_a(self):
        data=bytearray(b'\xff'*8192)
        struct.pack_into('<I',data,0,5)
        struct.pack_into('<I',data,24,2)
        struct.pack_into('<I',data,28,zlib.crc32(data[:4],0xffffffff)&0xffffffff)
        result=m.simulate(data)
        self.assertIsNone(result['factory_after_erase_slot'])
        self.assertTrue(all(x['ota_a_selected'] for x in result['return_to_a_cases']))
        self.assertFalse(result['physical_test_authorized'])
    def test_invalid_input_fails_closed(self):
        with self.assertRaises(ValueError):m.simulate(b'\xff'*8192)
        with self.assertRaises(ValueError):m.simulate(b'\xff'*8)
if __name__=='__main__':unittest.main()
