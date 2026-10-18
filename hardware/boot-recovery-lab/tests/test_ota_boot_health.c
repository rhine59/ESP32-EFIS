#include "ota_boot_health.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    redone_boot_evidence_t e = { .image_identity_ok=true, .firmware_self_test_ok=true,
        .required_sensors_ok=true, .display_ok=true, .power_ok=true,
        .rollback_path_ok=true, .operator_ground_confirmation=true };
    assert(!redone_boot_may_confirm(REDONE_BOOT_PENDING, NULL));
    assert(!redone_boot_may_confirm(REDONE_BOOT_UNKNOWN, &e));
    assert(!redone_boot_may_confirm(REDONE_BOOT_VALID, &e));
    assert(!redone_boot_may_confirm(REDONE_BOOT_INVALID, &e));
    assert(redone_boot_may_confirm(REDONE_BOOT_PENDING, &e));
    bool *fields[] = {&e.image_identity_ok, &e.firmware_self_test_ok,
        &e.required_sensors_ok, &e.display_ok, &e.power_ok,
        &e.rollback_path_ok, &e.operator_ground_confirmation};
    for (unsigned i=0;i<sizeof(fields)/sizeof(fields[0]);++i) {
        *fields[i]=false;
        assert(!redone_boot_may_confirm(REDONE_BOOT_PENDING, &e));
        *fields[i]=true;
    }
    puts("boot health fail-closed policy PASS");
}
