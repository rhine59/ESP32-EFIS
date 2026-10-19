from pathlib import Path
import unittest
SRC=(Path(__file__).resolve().parents[1]/'main/ota_http.c').read_text()
class BootHealthEndpoint(unittest.TestCase):
    def test_authenticated_read_only(self):
        body=SRC.split('static esp_err_t boot_health(',1)[1].split('static esp_err_t status(',1)[0]
        self.assertIn('require_auth(req)',body)
        self.assertIn('redone_boot_may_confirm(',body)
        self.assertIn('esp_ota_get_state_partition(',body)
        self.assertIn('esp_ota_get_next_update_partition(',body)
        self.assertNotIn('esp_ota_mark_app_valid_cancel_rollback(',body)
        self.assertNotIn('esp_ota_set_boot_partition(',body)
        self.assertNotIn('esp_partition_write(',body)
        self.assertIn('"/boot-health"',SRC)
        self.assertIn('"blocker', body)
        self.assertIn('"device-live-read-only', body)
        self.assertIn('"updateReady\\\":false', body)
    def test_unavailable_hardware_evidence_never_claimed_good(self):
        body=SRC.split('static esp_err_t boot_health(',1)[1].split('static esp_err_t status(',1)[0]
        for item in ('firmware_self_test_ok = false','required_sensors_ok = false',
                     'display_ok = false','power_ok = false','rollback_path_ok = false',
                     'operator_ground_confirmation = false'):
            self.assertIn(item,body)
if __name__=='__main__': unittest.main()
