import importlib.util
from pathlib import Path
import unittest
path=Path(__file__).resolve().parents[1]/'tools/phone_wifi_control_audit.py'
spec=importlib.util.spec_from_file_location('phone_wifi_control_audit',path)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class PhoneWiFiControlAudit(unittest.TestCase):
    def test_source_inventory_not_live_proof(self):
        report=m.audit()
        self.assertTrue(all(report['checks'].values()))
        self.assertFalse(report['live_phone_to_board_validated'])
        self.assertFalse(report['physical_write_authorized'])
    def test_missing_auth_or_route_fails_source_check(self):
        phone=m.PHONE.read_text().replace('X-Lab-Token','REMOVED')
        device=m.DEVICE.read_text().replace('.uri="/boot-health"','.uri="/removed"')
        result=m.audit(phone,device)
        self.assertFalse(result['checks']['phone_authenticated_status'])
        self.assertFalse(result['checks']['device_boot_health_route_in_source'])
        self.assertFalse(result['physical_write_authorized'])
if __name__=='__main__': unittest.main()
