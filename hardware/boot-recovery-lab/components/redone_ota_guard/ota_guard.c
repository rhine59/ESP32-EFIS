#include "ota_guard.h"
#include <string.h>

/* Pure policy state machine. Does not perform flash operations. */
void redone_ota_guard_reset(redone_ota_guard_t *guard) {
    if (guard) memset(guard, 0, sizeof(*guard));
}

bool redone_ota_guard_begin(redone_ota_guard_t *guard, bool authenticated,
                            bool signed_manifest_valid, bool destination_is_inactive_ota,
                            size_t image_size, size_t partition_capacity,
                            const uint8_t digest[32]) {
    if (!guard || guard->state != REDONE_OTA_IDLE || !authenticated ||
        !signed_manifest_valid || !destination_is_inactive_ota || !digest ||
        image_size < 1024 || image_size > partition_capacity) return false;
    guard->expected_bytes = image_size;
    memcpy(guard->expected_digest, digest, 32);
    guard->signature_verified = true;
    guard->state = REDONE_OTA_RECEIVING;
    return true;
}

bool redone_ota_guard_advance(redone_ota_guard_t *guard, size_t bytes) {
    if (!guard || guard->state != REDONE_OTA_RECEIVING || !bytes ||
        guard->received_bytes > guard->expected_bytes ||
        bytes > guard->expected_bytes - guard->received_bytes) {
        redone_ota_guard_abort(guard);
        return false;
    }
    guard->received_bytes += bytes;
    return true;
}

bool redone_ota_guard_finish(redone_ota_guard_t *guard,
                             const uint8_t streamed_digest[32],
                             const uint8_t flash_readback_digest[32]) {
    if (!guard || guard->state != REDONE_OTA_RECEIVING ||
        guard->received_bytes != guard->expected_bytes ||
        !streamed_digest || !flash_readback_digest) {
        redone_ota_guard_abort(guard);
        return false;
    }
    unsigned difference = 0;
    for (size_t i = 0; i < 32; ++i) {
        difference |= (unsigned)(guard->expected_digest[i] ^ streamed_digest[i]);
        difference |= (unsigned)(guard->expected_digest[i] ^ flash_readback_digest[i]);
    }
    if (difference) {
        redone_ota_guard_abort(guard);
        return false;
    }
    guard->readback_verified = true;
    guard->state = REDONE_OTA_STAGED;
    return true;
}

void redone_ota_guard_abort(redone_ota_guard_t *guard) {
    if (!guard) return;
    memset(guard->expected_digest, 0, sizeof(guard->expected_digest));
    guard->signature_verified = false;
    guard->readback_verified = false;
    guard->state = REDONE_OTA_FAILED;
}

bool redone_ota_guard_can_activate(const redone_ota_guard_t *guard,
                                   bool ground_confirmation, bool rollback_ready) {
    return guard && guard->state == REDONE_OTA_STAGED &&
           guard->signature_verified && guard->readback_verified &&
           ground_confirmation && rollback_ready;
}
