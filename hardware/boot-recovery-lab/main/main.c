#include <stdio.h>
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#ifndef EFIS_IMAGE_LABEL
#define EFIS_IMAGE_LABEL "A"
#endif
#ifndef EFIS_IMAGE_VERSION
#define EFIS_IMAGE_VERSION "1.0.0"
#endif

void app_main(void) {
    const esp_partition_t *running = esp_ota_get_running_partition();
    const esp_partition_t *next = esp_ota_get_next_update_partition(NULL);
    printf("\n=====================================\n");
    printf("EFIS BOOT LAB — IMAGE %s — %s\n", EFIS_IMAGE_LABEL, EFIS_IMAGE_VERSION);
    printf("Running partition: %s, next update: %s\n", running ? running->label : "unknown", next ? next->label : "none");
    printf("=====================================\n");
    esp_ota_img_states_t state;
    if (running && esp_ota_get_state_partition(running, &state) == ESP_OK && state == ESP_OTA_IMG_PENDING_VERIFY) {
        ESP_LOGW("BOOT_LAB", "New image pending validation; confirming healthy after startup checks");
        ESP_ERROR_CHECK(esp_ota_mark_app_valid_cancel_rollback());
    }
    int counter = 0;
    while (1) {
        ESP_LOGI("BOOT_LAB", "IMAGE %s v%s heartbeat %d", EFIS_IMAGE_LABEL, EFIS_IMAGE_VERSION, ++counter);
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}
