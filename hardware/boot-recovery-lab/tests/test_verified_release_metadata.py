from pathlib import Path
import unittest
BASE=Path(__file__).resolve().parents[1]
ENVELOPE=(BASE.parent.parent/'firmware/recovery/components/redone_crypto/redone_envelope.c').read_text()
HTTP=(BASE/'main/ota_http.c').read_text()
class VerifiedMetadata(unittest.TestCase):
    def test_only_populate_after_signature(self):
        self.assertLess(ENVELOPE.index('result=redone_verify_release_signature('),
                        ENVELOPE.index('verified->build=build->valueint'))
        self.assertIn('if (result != 0) memset(verified, 0, sizeof(*verified));', ENVELOPE)
        self.assertIn('redone_verify_release_metadata(', ENVELOPE)
    def test_staging_uses_verified_digest(self):
        body=HTTP.split('static esp_err_t signed_staging_dry_run(',1)[1].split('static esp_err_t upload(',1)[0]
        self.assertIn('redone_verify_release_metadata(', body)
        self.assertIn('verified_release.sha256', body)
        self.assertNotIn('cJSON_ParseWithLengthOpts(', body)
if __name__=='__main__': unittest.main()
