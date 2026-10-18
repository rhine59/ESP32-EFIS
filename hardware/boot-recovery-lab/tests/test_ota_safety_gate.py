"""Source-level regression guard until a signed OTA protocol is implemented."""
from pathlib import Path
import re
import unittest

SOURCE = Path(__file__).resolve().parents[1] / 'main' / 'ota_http.c'

class OTASafetyGate(unittest.TestCase):
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
