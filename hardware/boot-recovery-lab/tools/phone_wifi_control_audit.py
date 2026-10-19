#!/usr/bin/env python3
"""Source-level phone/ESP Wi-Fi control inventory; never contacts or changes hardware."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
PHONE = ROOT / 'ios/EFISService/EFISService/EFISWiFiView.swift'
DEVICE = ROOT / 'hardware/boot-recovery-lab/main/ota_http.c'

def audit(phone=None, device=None):
    phone = PHONE.read_text() if phone is None else phone
    device = DEVICE.read_text() if device is None else device
    checks = {
        'phone_wifi_join': 'NEHotspotConfiguration(ssid:' in phone,
        'phone_saved_pairing': 'RecoveryPairingStore.load()' in phone,
        'phone_authenticated_status': 'X-Lab-Token' in phone and '/status' in phone,
        'phone_boot_health_request': '/boot-health' in phone,
        'device_status_route_in_source': '.uri="/status"' in device,
        'device_boot_health_route_in_source': '.uri="/boot-health"' in device,
        'device_manifest_verify_route_in_source': '.uri="/firmware/verify-manifest"' in device,
        'device_hash_route_in_source': '.uri="/firmware/hash"' in device,
        'device_preflight_route_in_source': '.uri="/firmware/preflight"' in device,
        'device_write_gate_in_source': 'reject_untrusted_firmware' in device,
    }
    return {
        'mode': 'source-only-no-network', 'checks': checks,
        'live_phone_to_board_validated': False,
        'installed_board_route_inventory_validated': False,
        'physical_write_authorized': False,
        'decision': 'PHONE-WIFI-VALIDATION-PENDING',
    }

if __name__ == '__main__':
    print(json.dumps(audit(), indent=2))
