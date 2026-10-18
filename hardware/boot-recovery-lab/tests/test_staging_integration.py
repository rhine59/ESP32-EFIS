"""Fail-closed source checks for experimental, unreachable staging route."""
from pathlib import Path
import re
import unittest

SOURCE = (Path(__file__).resolve().parents[1] / 'main' / 'ota_http.c').read_text()

class StagingIntegration(unittest.TestCase):
    def test_signed_staging_not_exposed(self):
        self.assertIn('static esp_err_t signed_staging_dry_run(', SOURCE)
        self.assertEqual(SOURCE.count('signed_staging_dry_run('), 1)
        self.assertNotIn('.handler=signed_staging_dry_run', SOURCE)
        self.assertNotIn('.handler=upload,', SOURCE.split('static esp_err_t upload(')[0])

    def test_staging_requires_verified_envelope_and_readback(self):
        start = SOURCE.index('static esp_err_t signed_staging_dry_run(')
        end = SOURCE.index('static esp_err_t upload(', start)
        body = SOURCE[start:end]
        for marker in ('require_auth(req)', 'redone_verify_release_envelope(',
                       'redone_esp_ota_storage_select(', 'redone_ota_staging_begin(',
                       'redone_ota_staging_write(', 'redone_ota_staging_finish(',
                       'redone_ota_staging_abort('):
            self.assertIn(marker, body)
        self.assertNotIn('esp_ota_set_boot_partition(', body)
        self.assertNotIn('esp_restart(', body)

if __name__ == '__main__':
    unittest.main()
