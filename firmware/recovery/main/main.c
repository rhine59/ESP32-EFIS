/* RedOne minimal recovery: USB serial maintenance only, no network or flight UI.
 * Intended solely for the factory partition, NEVER the normal OTA slots.
 * Physical access is required; no unauthenticated Wi-Fi firmware endpoint.
 */
#include <stdio.h>
#include <string.h>
#include "esp_log.h"
#include "esp_system.h"
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "esp_app_desc.h"
#include "diagnostics.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "REDONE_RECOVERY";
static void report(void) {
    const esp_partition_t *running = esp_ota_get_running_partition();
    const esp_partition_t *boot = esp_ota_get_boot_partition();
    printf("\nRedOne RECOVERY (development) — no flight instrumentation\n");
    printf("running=%s selected=%s\n", running ? running->label : "?", boot ? boot->label : "?");
    for (int i=0; i<2; ++i) {
        const esp_partition_t *p = esp_partition_find_first(ESP_PARTITION_TYPE_APP,
            i ? ESP_PARTITION_SUBTYPE_APP_OTA_1 : ESP_PARTITION_SUBTYPE_APP_OTA_0, NULL);
        esp_app_desc_t desc;
        esp_ota_img_states_t state;
        bool valid = p && esp_ota_get_partition_description(p, &desc)==ESP_OK;
        printf("slot %c: %s", i?'B':'A', valid ? desc.version : "not installed / invalid");
        if (p && esp_ota_get_state_partition(p, &state)==ESP_OK) printf(" state=%d", (int)state);
        printf("\n");
    }
    printf("Commands: status, test, bootA, bootB, help (USB serial only)\n");
}
static void boot_slot(int slot) {
    const esp_partition_t *p = esp_partition_find_first(ESP_PARTITION_TYPE_APP,
        slot ? ESP_PARTITION_SUBTYPE_APP_OTA_1 : ESP_PARTITION_SUBTYPE_APP_OTA_0, NULL);
    esp_app_desc_t desc;
    if (!p || esp_ota_get_partition_description(p, &desc)!=ESP_OK) {
        ESP_LOGE(TAG, "Target image missing or invalid"); return;
    }
    /* The bootloader validates image integrity; recovery does not bypass secure boot. */
    esp_err_t err = esp_ota_set_boot_partition(p);
    if (err != ESP_OK) { ESP_LOGE(TAG, "Cannot select image: %s", esp_err_to_name(err)); return; }
    ESP_LOGW(TAG, "Selecting %s; restarting", p->label);
    fflush(stdout);
    vTaskDelay(pdMS_TO_TICKS(300));
    esp_restart();
}
void app_main(void) {
    const esp_partition_t *running = esp_ota_get_running_partition();
    if (!running || running->type!=ESP_PARTITION_TYPE_APP || running->subtype!=ESP_PARTITION_SUBTYPE_APP_FACTORY) {
        ESP_LOGE(TAG, "Recovery image is not running from factory partition; maintenance disabled");
        while (1) vTaskDelay(pdMS_TO_TICKS(1000));
    }
    report();
    char command[32];
    while (1) {
        if (!fgets(command, sizeof(command), stdin)) { clearerr(stdin); vTaskDelay(pdMS_TO_TICKS(100)); continue; }
        command[strcspn(command,"\r\n")] = 0;
        if (!strcmp(command,"status") || !strcmp(command,"help")) report();
        else if (!strcmp(command,"test")) recovery_diagnostics_print();
        else if (!strcmp(command,"bootA")) boot_slot(0);
        else if (!strcmp(command,"bootB")) boot_slot(1);
        else puts("Unknown command. Use help.");
    }
}
