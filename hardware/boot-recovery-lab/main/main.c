#include <stdio.h>
#include <string.h>
#include "esp_system.h"
#include "esp_app_desc.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "nvs.h"
#include "nvs_flash.h"
#include "ota_boot_health.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#ifndef EFIS_IMAGE_LABEL
#define EFIS_IMAGE_LABEL "A"
#endif
#ifndef EFIS_IMAGE_VERSION
#define EFIS_IMAGE_VERSION "1.0.0"
#endif

/* Bench USB only: updates two NVS keys without erasing the partition.
 * Credentials are supplied over a physically attached USB console; this is
 * NOT a production pairing or remote provisioning mechanism.
 */
static void provision_usb(void) {
    char password[80] = {0}, token[80] = {0};
    puts("USB BENCH PROVISIONING: supply AP password then API token on separate lines.");
    puts("WARNING: terminal software may record or echo these secrets.");
    fflush(stdout);
    if (!fgets(password, sizeof(password), stdin) || !fgets(token, sizeof(token), stdin)) {
        puts("Provisioning cancelled: incomplete input");
        goto cleanup;
    }
    password[strcspn(password, "\r\n")] = 0;
    token[strcspn(token, "\r\n")] = 0;
    if (strlen(password) < 16 || strlen(password) > 63 ||
        strlen(token) < 32 || strlen(token) > 64) {
        puts("Provisioning rejected: credential length invalid");
        goto cleanup;
    }
    nvs_handle_t handle;
    esp_err_t err = nvs_open("recovery", NVS_READWRITE, &handle);
    if (err != ESP_OK) { puts("Provisioning failed: NVS unavailable"); goto cleanup; }
    err = nvs_set_str(handle, "ap_password", password);
    if (err == ESP_OK) err = nvs_set_str(handle, "api_token", token);
    if (err == ESP_OK) err = nvs_commit(handle);
    nvs_close(handle);
    puts(err == ESP_OK ? "Bench credentials saved without NVS erase; reboot required" :
                         "Provisioning failed; verify NVS health");
cleanup:
    memset(password, 0, sizeof(password));
    memset(token, 0, sizeof(token));
}
static void console_task(void *arg) {
    char command[32];
    while (1) {
        if (!fgets(command, sizeof(command), stdin)) {
            clearerr(stdin);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        command[strcspn(command, "\r\n")] = 0;
        if (!strcmp(command, "provision")) {
            provision_usb();
        } else if (!strcmp(command, "status")) {
            const esp_partition_t *running = esp_ota_get_running_partition();
            const esp_partition_t *selected = esp_ota_get_boot_partition();
            ESP_LOGI("BOOT_LAB", "running=%s selected=%s", running->label, selected->label);
#if defined(REDONE_UNSAFE_MANUAL_BOOT_SELECTION) && REDONE_UNSAFE_MANUAL_BOOT_SELECTION
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
#endif
        }
    }
}

void lab_wifi_start(void);

void app_main(void) {
    const esp_partition_t *running = esp_ota_get_running_partition();
    const esp_partition_t *next = esp_ota_get_next_update_partition(NULL);
    printf("\n=====================================\n");
    printf("EFIS BOOT LAB — IMAGE %s — %s\n", EFIS_IMAGE_LABEL, EFIS_IMAGE_VERSION);
    printf("Running partition: %s, next update: %s\n", running ? running->label : "unknown", next ? next->label : "none");
    printf("=====================================\n");
    esp_ota_img_states_t state;
    if (running && esp_ota_get_state_partition(running, &state) == ESP_OK && state == ESP_OTA_IMG_PENDING_VERIFY) {
        /* Only the bench firmware's identity is known. Sensor, display,
         * power and recovery readiness are NOT established on this board.
         * In particular, a heartbeat or Wi-Fi connection is not sufficient. */
        const redone_boot_evidence_t evidence = {
            .image_identity_ok = true,
            .firmware_self_test_ok = false,
            .required_sensors_ok = false,
            .display_ok = false,
            .power_ok = false,
            .rollback_path_ok = false,
            .operator_ground_confirmation = false,
        };
        if (!redone_boot_may_confirm(REDONE_BOOT_PENDING, &evidence)) {
            ESP_LOGW("BOOT_LAB", "Pending image remains UNCONFIRMED: critical health evidence missing");
        }
        /* Do not call esp_ota_mark_app_valid_cancel_rollback here.
         * ESP-IDF rollback remains armed until a separate verified health
         * protocol is implemented and tested on the bench. */
    }
    xTaskCreate(console_task, "lab_console", 4096, NULL, 5, NULL);
    lab_wifi_start();
    int counter = 0;
    while (1) {
        ESP_LOGI("BOOT_LAB", "IMAGE %s v%s heartbeat %d", EFIS_IMAGE_LABEL, EFIS_IMAGE_VERSION, ++counter);
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}
