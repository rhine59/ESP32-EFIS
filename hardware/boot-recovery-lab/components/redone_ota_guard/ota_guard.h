#pragma once
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef enum {
    REDONE_OTA_IDLE = 0,
    REDONE_OTA_RECEIVING,
    REDONE_OTA_STAGED,
    REDONE_OTA_FAILED
} redone_ota_state_t;

typedef struct {
    redone_ota_state_t state;
    size_t expected_bytes;
    size_t received_bytes;
    uint8_t expected_digest[32];
    bool signature_verified;
    bool readback_verified;
} redone_ota_guard_t;

void redone_ota_guard_reset(redone_ota_guard_t *guard);
bool redone_ota_guard_begin(redone_ota_guard_t *guard, bool authenticated,
                            bool signed_manifest_valid, bool destination_is_inactive_ota,
                            size_t image_size, size_t partition_capacity,
                            const uint8_t digest[32]);
bool redone_ota_guard_advance(redone_ota_guard_t *guard, size_t bytes);
bool redone_ota_guard_finish(redone_ota_guard_t *guard,
                             const uint8_t streamed_digest[32],
                             const uint8_t flash_readback_digest[32]);
void redone_ota_guard_abort(redone_ota_guard_t *guard);
bool redone_ota_guard_can_activate(const redone_ota_guard_t *guard,
                                   bool ground_confirmation, bool rollback_ready);
