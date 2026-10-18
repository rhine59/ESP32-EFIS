import importlib.util
import struct
import tempfile
import unittest
import zlib
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'tools'
spec=importlib.util.spec_from_file_location('recovery_rescue_dry_run',P/'recovery_rescue_dry_run.py')
import sys
sys.path.insert(0,str(P))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class TestRescue(unittest.TestCase):
    def test_reject_short_backup(self):
        with tempfile.TemporaryDirectory() as d:
            f=Path(d)/'b';f.write_bytes(b'\xff'*16)
            with self.assertRaises(ValueError):m.plan(f)
    def test_valid_snapshot_never_authorizes_writes(self):
        with tempfile.TemporaryDirectory() as d:
            b=bytearray(b'\xff'*m.FLASH_LENGTH)
            b[m.FACTORY_OFFSET]=0xe9;b[m.OTA_A_OFFSET]=0xe9
            for index,seq in enumerate((4,5)):
                off=m.OTADATA_OFFSET+index*4096
                struct.pack_into('<I',b,off,seq)
                struct.pack_into('<I',b,off+24,2)
                struct.pack_into('<I',b,off+28,zlib.crc32(b[off:off+4],0xffffffff)&0xffffffff)
            f=Path(d)/'b';f.write_bytes(b)
            ota=f.with_name('otadata');ota.write_bytes(b[m.OTADATA_OFFSET:m.OTADATA_OFFSET+m.OTADATA_LENGTH])
            result=m.plan(f,ota)
            self.assertTrue(result['offline_snapshot_usable'])
            self.assertFalse(result['write_authorized'])
            self.assertFalse(result['recovery_boot_authorized'])
            self.assertFalse(result['rescue_path_physically_validated'])
if __name__=='__main__':unittest.main()
