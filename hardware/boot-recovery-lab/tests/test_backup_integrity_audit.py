import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'tools'
spec=importlib.util.spec_from_file_location('backup_integrity_audit',P/'backup_integrity_audit.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class TestAudit(unittest.TestCase):
    def test_good_chunks_and_tamper_detection(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            chunks=root/'chunks';chunks.mkdir()
            backup=root/'backup.bin';ota=root/'ota.bin'
            image=bytearray(b'\xff'*m.FLASH_SIZE)
            image[m.OTA_START:m.OTA_END]=b'\x00'*(m.OTA_END-m.OTA_START)
            backup.write_bytes(image);ota.write_bytes(image[m.OTA_START:m.OTA_END])
            for i in range(16):
                (chunks/f'chunk-{i:02d}.bin').write_bytes(image[i*m.CHUNK_SIZE:(i+1)*m.CHUNK_SIZE])
            result=m.audit(backup,chunks,ota)
            self.assertTrue(result['integrity_pass'])
            self.assertFalse(result['flash_write_authorized'])
            (chunks/'chunk-02.bin').write_bytes(b'\x00'*m.CHUNK_SIZE)
            with self.assertRaises(ValueError):m.audit(backup,chunks,ota)
    def test_missing_chunk_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);chunks=root/'chunks';chunks.mkdir()
            backup=root/'backup';ota=root/'ota'
            backup.write_bytes(b'\xff'*m.FLASH_SIZE)
            ota.write_bytes(b'\xff'*(m.OTA_END-m.OTA_START))
            with self.assertRaises(FileNotFoundError):m.audit(backup,chunks,ota)
