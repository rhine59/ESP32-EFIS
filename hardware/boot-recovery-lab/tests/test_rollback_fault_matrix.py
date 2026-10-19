import importlib.util
from pathlib import Path
import unittest

script = Path(__file__).resolve().parents[1] / 'tools/rollback_fault_matrix.py'
spec = importlib.util.spec_from_file_location('rollback_fault_matrix', script)
m = importlib.util.module_from_spec(spec)
import sys
sys.modules[spec.name] = m
spec.loader.exec_module(m)


class RollbackFaultMatrix(unittest.TestCase):
    def test_interrupted_stage_does_not_change_active(self):
        s = m.transition(m.State(), 'power_cut_during_stage')
        self.assertEqual(s.active, 'ota_0')
        self.assertFalse(s.candidate_verified)

    def test_unverified_candidate_refused(self):
        with self.assertRaises(ValueError):
            m.transition(m.State(), 'activate')

    def test_pending_failure_models_rollback(self):
        s = m.transition(m.transition(m.State(), 'stage_complete'), 'activate')
        self.assertEqual(s.active, 'ota_1')
        self.assertTrue(s.pending)
        for event in ('boot_health_failed', 'power_cut_during_pending_boot'):
            rolled_back = m.transition(s, event)
            self.assertEqual(rolled_back.active, 'ota_0')
            self.assertFalse(rolled_back.pending)

    def test_cannot_confirm_without_physical_gates(self):
        s = m.transition(m.transition(m.State(), 'stage_complete'), 'activate')
        with self.assertRaises(ValueError):
            m.transition(s, 'confirm_boot')

    def test_simulation_never_authorises_hardware(self):
        result = m.audit()
        self.assertEqual(len(result['scenarios']), 6)
        self.assertFalse(result['safe_to_flash_partition_b'])
        self.assertFalse(result['hardware_rollback_verified'])
        self.assertEqual(result['decision'], 'NO-GO')


if __name__ == '__main__':
    unittest.main()
