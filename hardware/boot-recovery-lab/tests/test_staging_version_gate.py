from pathlib import Path
import unittest
SRC=(Path(__file__).resolve().parents[1]/'main/ota_http.c').read_text()
class StagingVersionGate(unittest.TestCase):
    def test_version_check_before_any_storage_write(self):
        body=SRC.split('static esp_err_t signed_staging_dry_run(',1)[1].split('static esp_err_t upload(',1)[0]
        for required in ('redone_verify_release_metadata(',
                         'redone_parse_signed_build_floor(',
                         'redone_ota_version_allowed(',
                         'trusted_floor_available = false',
                         'installed_floor = -1', 'running_build = -1'):
            self.assertIn(required,body)
        self.assertLess(body.index('redone_ota_version_allowed('),
                        body.index('redone_esp_ota_storage_select('))
        self.assertLess(body.index('redone_ota_version_allowed('),
                        body.index('redone_ota_staging_begin('))
    def test_write_routes_remain_disabled(self):
        for method in ('upload','verify_image','activate_image'):
            body=SRC.split(f'static esp_err_t {method}(',1)[1].split('}',1)[0]
            self.assertIn('return reject_untrusted_firmware(req);',body)
if __name__=='__main__': unittest.main()
