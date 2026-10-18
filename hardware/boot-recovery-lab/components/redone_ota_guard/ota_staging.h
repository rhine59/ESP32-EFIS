#pragma once
#include "ota_guard.h"
typedef struct {
    void *context;
    bool (*begin)(void *, size_t);
    bool (*write)(void *, const uint8_t *, size_t);
    bool (*read_digest)(void *, uint8_t [32]);
    void (*abort)(void *);
} redone_ota_storage_t;
typedef struct {
    redone_ota_guard_t guard;
    redone_ota_storage_t storage;
    bool opened;
} redone_ota_staging_t;
bool redone_ota_staging_begin(redone_ota_staging_t *, redone_ota_storage_t,
    bool authenticated, bool signed_manifest_valid, bool inactive_partition,
    size_t size, size_t capacity, const uint8_t expected_digest[32]);
bool redone_ota_staging_write(redone_ota_staging_t *, const uint8_t *, size_t);
bool redone_ota_staging_finish(redone_ota_staging_t *, const uint8_t digest[32]);
void redone_ota_staging_abort(redone_ota_staging_t *);
