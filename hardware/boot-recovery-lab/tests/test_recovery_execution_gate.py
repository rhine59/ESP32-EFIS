import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'tools'
sys.path.insert(0,str(P))
spec=importlib.util.spec_from_file_location('recovery_execution_gate',P/'recovery_execution_gate.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class TestExecutionGate(unittest.TestCase):
    def test_rejects_wrong_identity_and_missing_evidence(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            for name in ('flash','ota','factory'):(root/name).write_bytes(b'bad')
            result=m.gate(root/'flash',root/'ota',root/'factory','00:00:00:00:00:00')
            self.assertFalse(result['offline_evidence_pass'])
            self.assertFalse(result['physical_factory_boot_authorized'])
            self.assertFalse(result['host_flash_write_authorized'])
    def test_authorization_never_derived_from_evidence(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            for name in ('flash','ota','factory'):(root/name).write_bytes(b'bad')
            result=m.gate(root/'flash',root/'ota',root/'factory',m.EXPECTED_MAC)
            self.assertFalse(result['physical_factory_boot_authorized'])
            self.assertFalse(result['partition_b_authorized'])
