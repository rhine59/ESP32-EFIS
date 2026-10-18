#include "ota_esp_storage.h"
#include "esp_partition.h"
#include "mbedtls/sha256.h"
#include <string.h>

static bool inactive_ota(const esp_partition_t *target) {
    const esp_partition_t *running = esp_ota_get_running_partition();
    if (!target || !running || target->type != ESP_PARTITION_TYPE_APP ||
        (target->subtype != ESP_PARTITION_SUBTYPE_APP_OTA_0 &&
         target->subtype != ESP_PARTITION_SUBTYPE_APP_OTA_1)) return false;
    if (running->address == target->address) return false;
    const esp_partition_t *configured = esp_ota_get_next_update_partition(NULL);
    return configured && configured->address == target->address &&
           configured->size == target->size;
}

bool redone_esp_ota_storage_select(redone_esp_ota_storage_t *storage) {
    if (!storage) return false;
    memset(storage, 0, sizeof(*storage));
    storage->target = esp_ota_get_next_update_partition(NULL);
    return inactive_ota(storage->target);
}

static bool start(void *ctx, size_t size) {
    redone_esp_ota_storage_t *s = ctx;
    if (!s || s->started || s->ended || !inactive_ota(s->target) ||
        size < 1024 || size > s->target->size) return false;
    if (esp_ota_begin(s->target, size, &s->handle) != ESP_OK) return false;
    s->image_size = size;
    s->started = true;
    return true;
}

static bool write_chunk(void *ctx, const uint8_t *bytes, size_t length) {
    redone_esp_ota_storage_t *s = ctx;
    return s && s->started && !s->ended && inactive_ota(s->target) &&
           bytes && length && esp_ota_write(s->handle, bytes, length) == ESP_OK;
}

static bool readback_digest(void *ctx, uint8_t digest[32]) {
    redone_esp_ota_storage_t *s = ctx;
    if (!s || !s->started || s->ended || !digest || !inactive_ota(s->target)) return false;
    /* End validates the ESP image and closes the OTA handle before readback. */
    if (esp_ota_end(s->handle) != ESP_OK) {
        s->started = false;
        return false;
    }
    s->started = false;
    s->ended = true;
    mbedtls_sha256_context hash;
    mbedtls_sha256_init(&hash);
    bool ok = mbedtls_sha256_starts(&hash, 0) == 0;
    uint8_t buffer[1024];
    for (size_t offset = 0; ok && offset < s->image_size;) {
        size_t n = s->image_size - offset;
        if (n > sizeof(buffer)) n = sizeof(buffer);
        if (esp_partition_read(s->target, offset, buffer, n) != ESP_OK ||
            mbedtls_sha256_update(&hash, buffer, n) != 0) ok = false;
        offset += n;
    }
    if (ok) ok = mbedtls_sha256_finish(&hash, digest) == 0;
    mbedtls_sha256_free(&hash);
    return ok;
}

static void cancel(void *ctx) {
    redone_esp_ota_storage_t *s = ctx;
    if (!s) return;
    if (s->started) esp_ota_abort(s->handle);
    s->started = false;
    /* No boot selection or recovery partition mutation. */
}

redone_ota_storage_t redone_esp_ota_storage_backend(redone_esp_ota_storage_t *storage) {
    return (redone_ota_storage_t){
        .context = storage, .begin = start, .write = write_chunk,
        .read_digest = readback_digest, .abort = cancel
    };
}
