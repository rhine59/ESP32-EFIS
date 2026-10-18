#!/usr/bin/env python3
"""Fail-closed, non-destructive release-readiness audit. No device writes."""
from pathlib import Path
import argparse
import json
import sys

ROOT = Path(__file__).resolve().parents[3]

def assess(root: Path, evidence: dict) -> dict:
    http = (root / 'hardware/boot-recovery-lab/main/ota_http.c').read_text()
    boot = (root / 'hardware/boot-recovery-lab/main/main.c').read_text()
    storage = (root / 'hardware/boot-recovery-lab/main/ota_esp_storage.c').read_text()
    checks = {
        'inactive_slot_guard_in_source': all(x in storage for x in (
            'esp_ota_get_running_partition', 'esp_ota_get_next_update_partition',
            'ESP_PARTITION_SUBTYPE_APP_OTA_1', 'esp_partition_read')),
        'write_endpoints_locked_in_source': all(x in http for x in (
            'return reject_untrusted_firmware(req);', 'transferEnabled\\":false')),
        'pending_boot_not_auto_confirmed': 'esp_ota_mark_app_valid_cancel_rollback()' not in
            '\n'.join(line for line in boot.splitlines() if not line.strip().startswith('*')),
        'signed_release_device_positive_and_negative_tests': evidence.get('signed_release_device_positive_and_negative_tests') is True,
        'trusted_persistent_version_floor': evidence.get('trusted_persistent_version_floor') is True,
        'boot_health_and_rollback_tested': evidence.get('boot_health_and_rollback_tested') is True,
        'physical_interruption_matrix_passed': evidence.get('physical_interruption_matrix_passed') is True,
        'recovery_access_verified_after_faults': evidence.get('recovery_access_verified_after_faults') is True,
        'partition_b_target_and_backup_verified': evidence.get('partition_b_target_and_backup_verified') is True,
        'operator_authorised_physical_flash': evidence.get('operator_authorised_physical_flash') is True,
    }
    return {'ready_for_real_partition_b_deployment': all(checks.values()),
            'checks': checks,
            'missing': [key for key, passed in checks.items() if not passed]}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, help='Locally reviewed evidence JSON (never fabricate pass results)')
    args = parser.parse_args()
    evidence = json.loads(args.evidence.read_text()) if args.evidence else {}
    result = assess(ROOT, evidence)
    print(json.dumps(result, indent=2))
    return 0 if result['ready_for_real_partition_b_deployment'] else 2

if __name__ == '__main__':
    sys.exit(main())
