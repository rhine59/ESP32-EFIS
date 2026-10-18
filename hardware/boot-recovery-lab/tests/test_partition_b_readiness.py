import importlib.util
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / 'hardware/boot-recovery-lab/tools/partition_b_readiness.py'
spec = importlib.util.spec_from_file_location('partition_b_readiness', SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
class Readiness(unittest.TestCase):
    def test_no_evidence_means_not_ready(self):
        result = module.assess(ROOT, {})
        self.assertFalse(result['ready_for_real_partition_b_deployment'])
        self.assertIn('physical_interruption_matrix_passed', result['missing'])
    def test_partial_evidence_still_blocks(self):
        result = module.assess(ROOT, {'operator_authorised_physical_flash': True})
        self.assertFalse(result['ready_for_real_partition_b_deployment'])
    def test_all_evidence_must_be_boolean_true(self):
        result = module.assess(ROOT, {'physical_interruption_matrix_passed': 'true'})
        self.assertFalse(result['checks']['physical_interruption_matrix_passed'])
if __name__ == '__main__': unittest.main()
