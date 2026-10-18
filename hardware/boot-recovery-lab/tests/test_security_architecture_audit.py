import json
import subprocess
import sys
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

class SecurityArchitectureAudit(unittest.TestCase):
    def test_source_audit_does_not_claim_deployment_readiness(self):
        result = subprocess.run([sys.executable, str(ROOT/'tools/security_architecture_audit.py')],
                                check=True, capture_output=True, text=True)
        data = json.loads(result.stdout)
        self.assertEqual(data['audit'], 'source-only')
        self.assertIs(data['safe_for_physical_partition_b'], False)
        self.assertTrue(data['checks']['factory_recovery_partition_declared'])
        self.assertTrue(data['checks']['ota_a_partition_declared'])
        self.assertTrue(data['checks']['ota_b_partition_declared'])
        for name in ('secure_boot_enabled','flash_encryption_enabled',
                     'application_anti_rollback_enabled','bootloader_anti_rollback_enabled'):
            self.assertFalse(data['checks'][name])

if __name__ == '__main__': unittest.main()
