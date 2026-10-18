#!/usr/bin/env python3
"""Non-destructive Stage 19 test-board preparation audit. Never writes hardware."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ('board_is_separate_from_redone', 'board_is_disposable',
            'board_identity_recorded', 'independent_recovery_plan_reviewed',
            'signed_images_and_keys_reviewed', 'physical_operator_authorisation')

def assess(evidence):
    config = (ROOT/'sdkconfig').read_text().splitlines()
    partitions = (ROOT/'partitions.csv').read_text()
    hardware = {key: evidence.get(key) is True for key in REQUIRED}
    config_info = {
        'target_esp32s3': 'CONFIG_IDF_TARGET="esp32s3"' in config,
        'custom_partition_table': 'CONFIG_PARTITION_TABLE_CUSTOM=y' in config,
        'factory_recovery_present': any(line.strip().startswith('recovery,') and ',  factory,' in line for line in partitions.splitlines()),
        'ota_a_present': 'ota_0,    app,  ota_0,' in partitions,
        'ota_b_present': 'ota_1,    app,  ota_1,' in partitions,
        'secure_boot_currently_enabled': 'CONFIG_SECURE_BOOT=y' in config,
        'flash_encryption_currently_enabled': 'CONFIG_FLASH_ENCRYPTION_ENABLED=y' in config,
        'anti_rollback_currently_enabled': 'CONFIG_APP_ANTI_ROLLBACK=y' in config,
    }
    return {
        'stage':'19', 'audit':'read-only',
        'safe_to_provision_efuses':False,
        'safe_to_flash_partition_b':False,
        'ready_to_request_separate_test_board_plan':all(hardware.values()) and all(
            config_info[k] for k in ('target_esp32s3','custom_partition_table',
                                      'factory_recovery_present','ota_a_present','ota_b_present')),
        'physical_evidence':hardware, 'source_configuration':config_info,
        'missing_physical_evidence':[key for key, ok in hardware.items() if not ok],
    }

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence',type=Path,help='Operator-reviewed JSON; does not authorise flash/eFuse writes')
    args=parser.parse_args()
    evidence=json.loads(args.evidence.read_text()) if args.evidence else {}
    print(json.dumps(assess(evidence),indent=2))

if __name__=='__main__':main()
