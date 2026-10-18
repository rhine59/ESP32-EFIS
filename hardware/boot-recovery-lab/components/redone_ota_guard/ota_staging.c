#include "ota_staging.h"

void redone_ota_staging_abort(redone_ota_staging_t *s) {
    if (!s) return;
    if (s->opened && s->storage.abort) s->storage.abort(s->storage.context);
    s->opened = false;
    redone_ota_guard_abort(&s->guard);
}

bool redone_ota_staging_begin(redone_ota_staging_t *s, redone_ota_storage_t storage,
    bool authenticated, bool signed_manifest_valid, bool inactive_partition,
    size_t size, size_t capacity, const uint8_t expected_digest[32]) {
    if (!s || s->opened || s->guard.state != REDONE_OTA_IDLE ||
        !storage.begin || !storage.write || !storage.read_digest || !storage.abort)
        return false;
    if (!redone_ota_guard_begin(&s->guard, authenticated, signed_manifest_valid,
                                inactive_partition, size, capacity, expected_digest)) return false;
    s->storage = storage;
    if (!s->storage.begin(s->storage.context, size)) {
        redone_ota_staging_abort(s);
        return false;
    }
    s->opened = true;
    return true;
}

bool redone_ota_staging_write(redone_ota_staging_t *s, const uint8_t *data, size_t length) {
    if (!s || !s->opened || !data || !length ||
        s->guard.state != REDONE_OTA_RECEIVING ||
        s->guard.received_bytes > s->guard.expected_bytes ||
        length > s->guard.expected_bytes - s->guard.received_bytes) {
        redone_ota_staging_abort(s);
        return false;
    }
    if (!s->storage.write(s->storage.context, data, length) ||
        !redone_ota_guard_advance(&s->guard, length)) {
        redone_ota_staging_abort(s);
        return false;
    }
    return true;
}

bool redone_ota_staging_finish(redone_ota_staging_t *s, const uint8_t digest[32]) {
    if (!s || !s->opened || !digest ||
        s->guard.received_bytes != s->guard.expected_bytes) {
        redone_ota_staging_abort(s);
        return false;
    }
    uint8_t readback[32];
    if (!s->storage.read_digest(s->storage.context, readback) ||
        !redone_ota_guard_finish(&s->guard, digest, readback)) {
        redone_ota_staging_abort(s);
        return false;
    }
    s->opened = false;
    return true;
}
