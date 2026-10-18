#pragma once
#include <stdbool.h>
#include <stdint.h>

typedef enum {
    REDONE_BOOT_UNKNOWN = 0,
    REDONE_BOOT_PENDING,
    REDONE_BOOT_VALID,
    REDONE_BOOT_INVALID
} redone_boot_state_t;

typedef struct {
    bool image_identity_ok;
    bool firmware_self_test_ok;
    bool required_sensors_ok;
    bool display_ok;
    bool power_ok;
    bool rollback_path_ok;
    bool operator_ground_confirmation;
} redone_boot_evidence_t;

/* Fail closed. UNKNOWN is never interpreted as valid. This policy is independent
 * of ESP-IDF and does not mutate otadata or mark an image valid. */
bool redone_boot_may_confirm(redone_boot_state_t state,
                             const redone_boot_evidence_t *evidence);
