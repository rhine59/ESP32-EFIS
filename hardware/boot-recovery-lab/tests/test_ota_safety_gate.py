"""Source-level regression guard until a signed OTA protocol is implemented."""
from pathlib import Path
import re
import unittest

SOURCE = Path(__file__).resolve().parents[1] / 'main' / 'ota_http.c'

class OTASafetyGate(unittest.TestCase):
    def test_hash_is_read_only_and_bounded(self):
        source = SOURCE.read_text()
        match = re.search(r'static esp_err_t hash_firmware\(httpd_req_t \*req\) \{(.*?)\n\}\n', source, re.S)
        self.assertIsNotNone(match)
        body = match.group(1)
        self.assertIn('require_auth(req)', body)
        self.assertIn('destination->size', body)
        self.assertIn('mbedtls_sha256_update', body)
        self.assertIn('transferEnabled\\\":false', body)
        self.assertNotIn('esp_ota_begin(', body)
        self.assertNotIn('esp_ota_write(', body)
        self.assertNotIn('esp_partition_write(', body)
        self.assertNotIn('esp_ota_set_boot_partition(', body)

    def test_signed_preflight_is_atomic_and_read_only(self):
        source = SOURCE.read_text()
        match = re.search(r'static esp_err_t signed_preflight\(httpd_req_t \*req\) \{(.*?)\n\}\n', source, re.S)
        self.assertIsNotNone(match)
        body = match.group(1)
        for required in ('require_auth(req)', 'redone_verify_release_envelope',
                         'mbedtls_sha256_update', 'destination->size',
                         'imageHashMatches', 'transferEnabled'):
            self.assertIn(required, body)
        for forbidden in ('esp_ota_begin(', 'esp_ota_write(',
                          'esp_partition_write(', 'esp_ota_set_boot_partition('):
            self.assertNotIn(forbidden, body)

    def test_mutating_endpoints_fail_closed(self):
        source = SOURCE.read_text()
        for function in ('upload', 'verify_image', 'activate_image'):
            match = re.search(r'static esp_err_t ' + function + r'\(httpd_req_t \*req\) \{(.*?)#if 0', source, re.S)
            self.assertIsNotNone(match, function)
            self.assertIn('require_auth(req)', match.group(1))
            self.assertIn('return reject_untrusted_firmware(req);', match.group(1))
        self.assertIn('HTTPD_403_FORBIDDEN', source)

if __name__ == '__main__':
    unittest.main()
