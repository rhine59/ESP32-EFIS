#include "ota_boot_health.h"

bool redone_boot_may_confirm(redone_boot_state_t state,
                             const redone_boot_evidence_t *evidence) {
    return state == REDONE_BOOT_PENDING && evidence &&
           evidence->image_identity_ok && evidence->firmware_self_test_ok &&
           evidence->required_sensors_ok && evidence->display_ok &&
           evidence->power_ok && evidence->rollback_path_ok &&
           evidence->operator_ground_confirmation;
}
