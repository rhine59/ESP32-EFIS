"""Guard against premature boot confirmation or unsafe console boot selection."""
from pathlib import Path
import unittest

SOURCE = (Path(__file__).resolve().parents[1] / 'main' / 'main.c').read_text()

class BootHealthGate(unittest.TestCase):
    def test_pending_image_is_not_auto_confirmed(self):
        self.assertIn('ESP_OTA_IMG_PENDING_VERIFY', SOURCE)
        self.assertNotIn('ESP_ERROR_CHECK(esp_ota_mark_app_valid_cancel_rollback())', SOURCE)
        self.assertIn('Pending image remains UNCONFIRMED', SOURCE)

    def test_console_boot_selection_compiled_out_by_default(self):
        self.assertIn('#if defined(REDONE_UNSAFE_MANUAL_BOOT_SELECTION) && REDONE_UNSAFE_MANUAL_BOOT_SELECTION', SOURCE)
        self.assertIn('esp_ota_set_boot_partition(partition)', SOURCE)
        self.assertNotIn('REDONE_UNSAFE_MANUAL_BOOT_SELECTION=1', SOURCE)

if __name__ == '__main__': unittest.main()
