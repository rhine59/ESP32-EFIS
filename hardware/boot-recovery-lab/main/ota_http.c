#include <string.h>
#include "esp_log.h"
#include "esp_http_server.h"
#include "esp_ota_ops.h"
#include "esp_app_desc.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
static const char *TAG = "LAB_OTA";
static esp_err_t upload(httpd_req_t *req) {
    char token[80] = {0};
    if (httpd_req_get_hdr_value_str(req, "X-Lab-Token", token, sizeof(token)) != ESP_OK ||
        strcmp(token, "efis-bench-only")) {
        httpd_resp_send_err(req, HTTPD_401_UNAUTHORIZED, "Lab token required");
        return ESP_FAIL;
    }
    const esp_partition_t *dest = esp_ota_get_next_update_partition(NULL);
    if (!dest || req->content_len < 1024 || req->content_len > dest->size) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid image size");
        return ESP_FAIL;
    }
    esp_ota_handle_t handle;
    esp_err_t err = esp_ota_begin(dest, req->content_len, &handle);
    if (err != ESP_OK) {
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "OTA begin failed");
        return ESP_FAIL;
    }
    int remaining = req->content_len;
    char buffer[1024];
    while (remaining > 0) {
        int n = httpd_req_recv(req, buffer, remaining < (int)sizeof(buffer) ? remaining : (int)sizeof(buffer));
        if (n <= 0) { err = ESP_FAIL; break; }
        err = esp_ota_write(handle, buffer, n);
        if (err != ESP_OK) break;
        remaining -= n;
    }
    if (err == ESP_OK) err = esp_ota_end(handle);
    else esp_ota_abort(handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "OTA write failed: %s", esp_err_to_name(err));
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid firmware");
        return ESP_FAIL;
    }
    esp_app_desc_t desc;
    if (esp_ota_get_partition_description(dest, &desc) != ESP_OK ||
        strcmp(desc.project_name, "efis_boot_lab")) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Wrong firmware project");
        return ESP_FAIL;
    }
    err = esp_ota_set_boot_partition(dest);
    if (err != ESP_OK) {
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Boot selection failed");
        return ESP_FAIL;
    }
    ESP_LOGW(TAG, "Selected %s version %s", dest->label, desc.version);
    httpd_resp_sendstr(req, "OTA accepted; rebooting");
    vTaskDelay(pdMS_TO_TICKS(500));
    esp_restart();
    return ESP_OK;
}
static esp_err_t status(httpd_req_t *req) {
    const esp_partition_t *running = esp_ota_get_running_partition();
    const esp_partition_t *next = esp_ota_get_next_update_partition(NULL);
    const esp_app_desc_t *app = esp_app_get_description();
    char response[256];
    snprintf(response, sizeof(response),
        "{\"device\":\"RedOne\",\"version\":\"%s\",\"running\":\"%s\",\"next\":\"%s\"}",
        app->version, running ? running->label : "unknown", next ? next->label : "unknown");
    httpd_resp_set_type(req, "application/json");
    return httpd_resp_sendstr(req, response);
}

void lab_http_start(void) {
    httpd_handle_t server = NULL;
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    if (httpd_start(&server, &config) != ESP_OK) return;
    httpd_uri_t uri = {.uri="/update", .method=HTTP_POST, .handler=upload};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &uri));
    httpd_uri_t info = {.uri="/status", .method=HTTP_GET, .handler=status};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &info));
    ESP_LOGI(TAG, "HTTP OTA endpoint ready");
}
