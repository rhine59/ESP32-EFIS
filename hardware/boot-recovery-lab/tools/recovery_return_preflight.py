#!/usr/bin/env python3
"""Offline-only factory recovery return-path audit. Does not access serial or write flash."""
import argparse
import hashlib
import json
from pathlib import Path

RECOVERY_OFFSET=0x20000
RECOVERY_SIZE=0x100000

def audit(full_backup,live_factory,build_image,recovery_source,idf_ota_source):
    backup=Path(full_backup).read_bytes()
    factory=Path(live_factory).read_bytes()
    build=Path(build_image).read_bytes()
    source=Path(recovery_source).read_text()
    ota=Path(idf_ota_source).read_text()
    checks={
        'backup_covers_factory':len(backup)>=RECOVERY_OFFSET+RECOVERY_SIZE,
        'live_factory_exact_size':len(factory)==RECOVERY_SIZE,
        'live_factory_matches_backup':len(backup)>=RECOVERY_OFFSET+RECOVERY_SIZE and factory==backup[RECOVERY_OFFSET:RECOVERY_OFFSET+RECOVERY_SIZE],
        'build_image_matches_live_factory_prefix':len(build)>0 and len(build)<=len(factory) and factory[:len(build)]==build,
        'recovery_has_usb_bootA_command':'!strcmp(command,"bootA")' in source and 'boot_slot(0)' in source,
        'recovery_calls_ota_boot_api':'esp_ota_set_boot_partition(p)' in source,
        'factory_boot_selection_erases_otadata':'partition->subtype == ESP_PARTITION_SUBTYPE_APP_FACTORY' in ota and 'esp_partition_erase_range(find_partition, 0, find_partition->size)' in ota,
    }
    return {'checks':checks,'all_offline_checks_pass':all(checks.values()),
            'recovery_image_sha256':hashlib.sha256(factory).hexdigest(),
            'return_to_a_physically_tested':False,'safe_to_execute_factory_boot':False,
            'note':'Source/binary equivalence does not establish runtime recovery or return-to-A; separate physical approval required.'}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('backup','factory','build','source','idf_ota_source'):p.add_argument(name,type=Path)
    a=p.parse_args()
    print(json.dumps(audit(a.backup,a.factory,a.build,a.source,a.idf_ota_source),indent=2))
if __name__=='__main__':main()
