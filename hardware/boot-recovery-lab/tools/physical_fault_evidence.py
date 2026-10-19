#!/usr/bin/env python3
"""Validate documented physical fault-test evidence without touching hardware."""
import argparse
import json
from pathlib import Path

REQUIRED_SCENARIOS = (
    'signed_valid_image', 'tampered_signature', 'downgrade_rejected',
    'stage_power_interruption', 'activation_power_interruption',
    'pending_boot_power_interruption', 'boot_health_failure',
    'both_ota_slots_invalid', 'recovery_after_each_fault',
    'security_epoch_recovery_compatibility',
)


def assess(record):
    board = record.get('board', {})
    original_mac = '3c0f02d61fdc'
    mac = board.get('mac', '')
    normalized = mac.lower().replace(':', '').replace('-', '') if isinstance(mac, str) else ''
    separate = len(normalized) == 12 and all(c in '0123456789abcdef' for c in normalized) and normalized != original_mac
    evidence = record.get('scenarios', {})
    scenarios = {}
    for name in REQUIRED_SCENARIOS:
        item = evidence.get(name, {})
        scenarios[name] = bool(isinstance(item, dict) and item.get('result') == 'PASS'
                               and isinstance(item.get('log_sha256'), str)
                               and len(item['log_sha256']) == 64
                               and all(c in '0123456789abcdef' for c in item['log_sha256'].lower())
                               and isinstance(item.get('reviewer'), str) and item['reviewer'].strip())
    return {
        'scope': 'operator-supplied-evidence-inventory-only',
        'separate_test_board_identified': separate,
        'disposable_board_declared': board.get('disposable') is True,
        'test_only_keys_declared': board.get('test_only_keys') is True,
        'scenario_evidence_present': scenarios,
        'missing': [name for name, present in scenarios.items() if not present],
        'record_complete_for_independent_review': separate and board.get('disposable') is True
            and board.get('test_only_keys') is True and all(scenarios.values()),
        'logs_authenticity_verified': False,
        'hardware_attestation_verified': False,
        'safe_to_flash_redone': False,
        'safe_to_provision_efuses': False,
        'decision': 'NO-GO',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, help='Local JSON record, never secrets')
    args = parser.parse_args()
    record = json.loads(args.evidence.read_text()) if args.evidence else {}
    print(json.dumps(assess(record), indent=2))


if __name__ == '__main__':
    main()
