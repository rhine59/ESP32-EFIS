import importlib.util
from pathlib import Path
import sys
import unittest

path = Path(__file__).resolve().parents[1] / 'tools/physical_fault_evidence.py'
spec = importlib.util.spec_from_file_location('physical_fault_evidence', path)
m = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = m
spec.loader.exec_module(m)


class PhysicalEvidence(unittest.TestCase):
    def test_missing_evidence_no_go(self):
        result = m.assess({})
        self.assertEqual(len(result['missing']), len(m.REQUIRED_SCENARIOS))
        self.assertFalse(result['record_complete_for_independent_review'])
        self.assertEqual(result['decision'], 'NO-GO')

    def test_original_redone_cannot_be_test_board(self):
        result = m.assess({'board': {'mac': '3c:0f:02:d6:1f:dc', 'disposable': True}})
        self.assertFalse(result['separate_test_board_identified'])

    def test_complete_claims_never_authorise_hardware(self):
        record = {'board': {'mac': 'aa:bb:cc:dd:ee:ff', 'disposable': True, 'test_only_keys': True},
                  'scenarios': {name: {'result': 'PASS', 'log_sha256': 'a' * 64,
                                       'reviewer': 'independent reviewer'} for name in m.REQUIRED_SCENARIOS}}
        result = m.assess(record)
        self.assertTrue(result['record_complete_for_independent_review'])
        self.assertFalse(result['logs_authenticity_verified'])
        self.assertFalse(result['safe_to_flash_redone'])
        self.assertFalse(result['safe_to_provision_efuses'])

    def test_unreviewed_or_invalid_log_is_missing(self):
        result = m.assess({'scenarios': {'signed_valid_image': {
            'result': 'PASS', 'log_sha256': 'not-a-hash', 'reviewer': ''}}})
        self.assertIn('signed_valid_image', result['missing'])


if __name__ == '__main__':
    unittest.main()
