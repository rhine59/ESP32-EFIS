#!/usr/bin/env python3
"""Read-only trust-boundary audit. Not evidence of physical security provisioning."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]

def assess(root=ROOT):
    floor=(root/'hardware/boot-recovery-lab/components/redone_ota_guard/ota_floor.c').read_text()
    policy=(root/'firmware/recovery/components/redone_crypto/redone_release_policy.c').read_text()
    config=set((root/'hardware/boot-recovery-lab/sdkconfig').read_text().splitlines())
    checks={
        'floor_requires_hardware_attestation': 'backend->hardware_protected(backend->context)' in floor,
        'floor_rejects_failed_read': '!backend->read(backend->context, &value)' in floor,
        'floor_rejects_decrement': 'candidate_floor < previous' in floor,
        'floor_verifies_advance_by_readback': 'observed >= candidate_floor' in floor,
        'release_policy_requires_hardware_attestation': 'trust->hardware_protected(trust->context)' in policy,
        'release_policy_requires_running_build': 'trust->read_running_build(trust->context, &running)' in policy,
        'secure_boot_enabled_in_build': 'CONFIG_SECURE_BOOT=y' in config,
        'flash_encryption_enabled_in_build': 'CONFIG_FLASH_ENCRYPTION_ENABLED=y' in config,
        'hardware_anti_rollback_enabled_in_build': 'CONFIG_APP_ANTI_ROLLBACK=y' in config,
    }
    return {
        'audit':'source-only',
        'checks':checks,
        'trusted_build_floor_provider_implemented':False,
        'external_secure_element_authenticated_and_tested':False,
        'security_epoch_recovery_compatibility_physically_proven':False,
        'safe_to_provision_efuses':False,
        'safe_to_flash_partition_b':False,
        'decision':'NO-GO',
    }
if __name__=='__main__':print(json.dumps(assess(),indent=2))
