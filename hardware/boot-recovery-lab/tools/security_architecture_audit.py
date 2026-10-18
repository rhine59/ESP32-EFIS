#!/usr/bin/env python3
"""Read-only source/config audit; not a physical security certification."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
config = (ROOT / 'sdkconfig').read_text()
partitions = (ROOT / 'partitions.csv').read_text()
required = {
    'secure_boot_enabled': 'CONFIG_SECURE_BOOT=y' in config.splitlines(),
    'flash_encryption_enabled': 'CONFIG_FLASH_ENCRYPTION_ENABLED=y' in config.splitlines(),
    'application_anti_rollback_enabled': 'CONFIG_APP_ANTI_ROLLBACK=y' in config.splitlines(),
    'bootloader_anti_rollback_enabled': 'CONFIG_BOOTLOADER_APP_ANTI_ROLLBACK=y' in config.splitlines(),
    'factory_recovery_partition_declared': any(line.strip().startswith('recovery,') and ',  factory,' in line for line in partitions.splitlines()),
    'ota_a_partition_declared': 'ota_0,    app,  ota_0,' in partitions,
    'ota_b_partition_declared': 'ota_1,    app,  ota_1,' in partitions,
}
print(json.dumps({'audit':'source-only','safe_for_physical_partition_b':False,'checks':required}, indent=2))
