import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path
TOOL=Path(__file__).resolve().parents[1]/'tools/stage19_preflight.py'
spec=importlib.util.spec_from_file_location('stage19_preflight',TOOL)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class Stage19Tests(unittest.TestCase):
    def test_default_fails_closed(self):
        result=module.assess({})
        self.assertFalse(result['ready_to_request_separate_test_board_plan'])
        self.assertFalse(result['safe_to_provision_efuses'])
        self.assertFalse(result['safe_to_flash_partition_b'])
        self.assertEqual(len(result['missing_physical_evidence']),6)
    def test_all_evidence_never_authorises_mutation(self):
        result=module.assess({key:True for key in module.REQUIRED})
        self.assertTrue(result['ready_to_request_separate_test_board_plan'])
        self.assertFalse(result['safe_to_provision_efuses'])
        self.assertFalse(result['safe_to_flash_partition_b'])
    def test_command_line_reports_json(self):
        output=subprocess.check_output([sys.executable,str(TOOL)],text=True)
        self.assertEqual(json.loads(output)['audit'],'read-only')

if __name__=='__main__':unittest.main()
