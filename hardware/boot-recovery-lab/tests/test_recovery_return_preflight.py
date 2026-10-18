import importlib.util
import tempfile
import unittest
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'tools/recovery_return_preflight.py'
spec=importlib.util.spec_from_file_location('recovery_return_preflight',P)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class TestPreflight(unittest.TestCase):
    def test_fail_closed_when_missing_evidence(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d);paths=[]
            for name in ('backup','factory','build','source','idf'):
                f=p/name;f.write_bytes(b'');paths.append(f)
            result=m.audit(*paths)
            self.assertFalse(result['all_offline_checks_pass'])
            self.assertFalse(result['safe_to_execute_factory_boot'])
    def test_complete_offline_evidence_never_authorizes_boot(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d);backup=p/'backup';factory=p/'factory';build=p/'build';source=p/'source';idf=p/'idf'
            payload=b'ABC'+b'\xff'*(m.RECOVERY_SIZE-3)
            backup.write_bytes(b'\xff'*m.RECOVERY_OFFSET+payload)
            factory.write_bytes(payload);build.write_bytes(b'ABC')
            source.write_text('!strcmp(command,"bootA") boot_slot(0) esp_ota_set_boot_partition(p)')
            idf.write_text('partition->subtype == ESP_PARTITION_SUBTYPE_APP_FACTORY esp_partition_erase_range(find_partition, 0, find_partition->size)')
            result=m.audit(backup,factory,build,source,idf)
            self.assertTrue(result['all_offline_checks_pass'])
            self.assertFalse(result['safe_to_execute_factory_boot'])
            self.assertFalse(result['return_to_a_physically_tested'])
if __name__=='__main__':unittest.main()
