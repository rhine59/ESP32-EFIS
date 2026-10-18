#include <string.h>
#include "esp_log.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "nvs_flash.h"
#include "nvs.h"
void lab_http_start(void);
void lab_wifi_start(void) {
    esp_err_t err = nvs_flash_init();
    /* Never erase aircraft configuration automatically. */
    if (err != ESP_OK) {
        ESP_LOGE("LAB_WIFI", "NVS unavailable; OTA disabled (no automatic erase)");
        return;
    }
    nvs_handle_t auth;
    char password[64] = {0};
    char token[80] = {0};
    size_t password_size = sizeof(password), token_size = sizeof(token);
    if (nvs_open("lab_auth", NVS_READONLY, &auth) != ESP_OK) {
        ESP_LOGW("LAB_WIFI", "Credentials not provisioned; bench Wi-Fi disabled");
        return;
    }
    esp_err_t pw_err = nvs_get_str(auth, "ap_password", password, &password_size);
    esp_err_t token_err = nvs_get_str(auth, "token", token, &token_size);
    nvs_close(auth);
    if (pw_err != ESP_OK || token_err != ESP_OK ||
        strlen(password) < 16 || strlen(password) > 63 ||
        strlen(token) < 32 || strlen(token) > 64) {
        ESP_LOGW("LAB_WIFI", "Incomplete credentials; bench Wi-Fi disabled");
        return;
    }
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_ap();
    wifi_init_config_t init = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&init));
    wifi_config_t ap = {0};
    uint8_t mac[6] = {0};
    ESP_ERROR_CHECK(esp_wifi_get_mac(WIFI_IF_AP, mac));
    snprintf((char *)ap.ap.ssid, sizeof(ap.ap.ssid), "RedOne_%02X%02X%02X%02X%02X%02X",
             mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    memcpy(ap.ap.password, password, strlen(password) + 1);
    ap.ap.ssid_len = strlen((char *)ap.ap.ssid);
    ap.ap.channel = 6;
    ap.ap.max_connection = 1;
    ap.ap.authmode = WIFI_AUTH_WPA2_PSK;
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_AP));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_AP, &ap));
    ESP_ERROR_CHECK(esp_wifi_start());
    ESP_LOGW("LAB_WIFI", "Bench AP SSID: %s (replace credentials for production)", ap.ap.ssid);
    lab_http_start();
}
