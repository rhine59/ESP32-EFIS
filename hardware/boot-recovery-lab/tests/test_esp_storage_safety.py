"""Source guard for the isolated ESP-IDF backend; not hardware validation."""
from pathlib import Path
import unittest

BASE = Path(__file__).resolve().parents[1]
SOURCE = (BASE / 'main' / 'ota_esp_storage.c').read_text()
HTTP = (BASE / 'main' / 'ota_http.c').read_text()

class StorageSafety(unittest.TestCase):
    def test_only_inactive_ota_slots(self):
        for required in ('ESP_PARTITION_SUBTYPE_APP_OTA_0',
                         'ESP_PARTITION_SUBTYPE_APP_OTA_1',
                         'esp_ota_get_running_partition',
                         'esp_ota_get_next_update_partition',
                         'running->address == target->address'):
            self.assertIn(required, SOURCE)

    def test_readback_and_abort(self):
        for required in ('esp_ota_begin', 'esp_ota_write', 'esp_ota_end',
                         'esp_partition_read', 'mbedtls_sha256_update', 'esp_ota_abort'):
            self.assertIn(required, SOURCE)
        for forbidden in ('esp_ota_set_boot_partition', 'esp_restart(', 'esp_partition_erase_range'):
            self.assertNotIn(forbidden, SOURCE)

    def test_http_mutations_still_locked(self):
        for handler in ('upload', 'verify_image', 'activate_image'):
            start = HTTP.index('static esp_err_t ' + handler + '(')
            self.assertIn('return reject_untrusted_firmware(req);', HTTP[start:HTTP.index('#if 0', start)])
        self.assertEqual(HTTP.count('signed_staging_dry_run('), 1)
        self.assertNotIn('.handler=signed_staging_dry_run', HTTP)

if __name__ == '__main__':
    unittest.main()
