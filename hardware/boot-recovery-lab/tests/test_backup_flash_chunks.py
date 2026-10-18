import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'tools'
spec=importlib.util.spec_from_file_location('backup_flash_chunks',P/'backup_flash_chunks.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class TestChunkTrust(unittest.TestCase):
    def test_legacy_chunks_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);(root/'chunk-00.bin').write_bytes(b'x')
            with self.assertRaisesRegex(ValueError,'legacy'):
                m.load_manifest(root)
    def test_resume_manifest_and_corruption(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);p=root/'chunk-00.bin';p.write_bytes(b'a'*m.CHUNK)
            manifest=m.manifest_template()
            manifest['chunks']['0']={'offset':0,'length':m.CHUNK,'sha256':m.sha(p.read_bytes())}
            m.save_manifest(root/m.MANIFEST_NAME,manifest)
            loaded=m.load_manifest(root)
            self.assertTrue(m.trusted_chunk(p,0,loaded))
            p.write_bytes(b'b'*m.CHUNK)
            with self.assertRaisesRegex(ValueError,'differs'):
                m.trusted_chunk(p,0,loaded)
    def test_identity_tamper_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);data=m.manifest_template();data['mac']='00:00:00:00:00:00'
            m.save_manifest(root/m.MANIFEST_NAME,data)
            with self.assertRaisesRegex(ValueError,'identity'):
                m.load_manifest(root)
    def test_orphan_chunk_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);p=root/'chunk-00.bin';p.write_bytes(b'a'*m.CHUNK)
            with self.assertRaisesRegex(ValueError,'Unmanifested'):
                m.trusted_chunk(p,0,m.manifest_template())
