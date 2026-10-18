import importlib.util
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[3]
path=ROOT/'hardware/boot-recovery-lab/tools/trusted_floor_design_audit.py'
spec=importlib.util.spec_from_file_location('floor_design_audit',path)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
class FloorDesignAudit(unittest.TestCase):
    def test_current_board_fails_closed(self):
        result=module.assess(ROOT)
        self.assertEqual(result['decision'],'NO-GO')
        self.assertFalse(result['trusted_build_floor_provider_implemented'])
        self.assertFalse(result['safe_to_provision_efuses'])
        self.assertFalse(result['safe_to_flash_partition_b'])
    def test_policy_guardrails_exist(self):
        checks=module.assess(ROOT)['checks']
        for key in ('floor_requires_hardware_attestation','floor_rejects_failed_read','floor_rejects_decrement','floor_verifies_advance_by_readback','release_policy_requires_hardware_attestation','release_policy_requires_running_build'):
            self.assertTrue(checks[key],key)
