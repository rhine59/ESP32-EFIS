#include <stdio.h>
#include <string.h>
#include "esp_system.h"
#include "esp_app_desc.h"
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

static void console_task(void *arg) {
    char command[32];
    while (1) {
        if (!fgets(command, sizeof(command), stdin)) {
            clearerr(stdin);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        command[strcspn(command, "\r\n")] = 0;
        if (!strcmp(command, "status")) {
            const esp_partition_t *running = esp_ota_get_running_partition();
            const esp_partition_t *selected = esp_ota_get_boot_partition();
            ESP_LOGI("BOOT_LAB", "running=%s selected=%s", running->label, selected->label);
        } else if (!strcmp(command, "boot0") || !strcmp(command, "boot1")) {
            int slot = command[4] - '0';
            const esp_partition_t *partition = esp_partition_find_first(ESP_PARTITION_TYPE_APP,
                slot ? ESP_PARTITION_SUBTYPE_APP_OTA_1 : ESP_PARTITION_SUBTYPE_APP_OTA_0, NULL);
            esp_app_desc_t desc;
            if (!partition || esp_ota_get_partition_description(partition, &desc) != ESP_OK ||
                strcmp(desc.project_name, "efis_boot_lab")) {
                ESP_LOGE("BOOT_LAB", "No valid lab firmware in requested slot");
                continue;
            }
            esp_err_t err = esp_ota_set_boot_partition(partition);
            if (err != ESP_OK) {
                ESP_LOGE("BOOT_LAB", "Boot selection failed: %s", esp_err_to_name(err));
                continue;
            }
            ESP_LOGW("BOOT_LAB", "Selected %s; restarting", partition->label);
            vTaskDelay(pdMS_TO_TICKS(300));
            esp_restart();
        }
    }
}

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
    xTaskCreate(console_task, "lab_console", 4096, NULL, 5, NULL);
    int counter = 0;
    while (1) {
        ESP_LOGI("BOOT_LAB", "IMAGE %s v%s heartbeat %d", EFIS_IMAGE_LABEL, EFIS_IMAGE_VERSION, ++counter);
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}
