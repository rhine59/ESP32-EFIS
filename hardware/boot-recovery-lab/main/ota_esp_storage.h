#pragma once
#include "ota_staging.h"
#include "esp_ota_ops.h"

typedef struct {
    const esp_partition_t *target;
    esp_ota_handle_t handle;
    size_t image_size;
    bool started;
    bool ended;
} redone_esp_ota_storage_t;

/* Selects only the non-running OTA app slot; never factory/recovery. */
bool redone_esp_ota_storage_select(redone_esp_ota_storage_t *storage);
redone_ota_storage_t redone_esp_ota_storage_backend(redone_esp_ota_storage_t *storage);
