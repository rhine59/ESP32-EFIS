#include <string.h>
#include "esp_log.h"
#include "redone_envelope.h"
#include "esp_heap_caps.h"
#include "esp_http_server.h"
#include "esp_ota_ops.h"
#include "esp_app_desc.h"
#include "esp_system.h"
#include "nvs.h"
#include "esp_ota_ops.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
static const char *TAG = "LAB_OTA";
static const esp_partition_t *staged = NULL;
static bool verified = false;
/* Production safety gate: authentication and image parsing are not a signature
 * verification protocol. Never allow writes or boot changes from this build. */
static esp_err_t reject_untrusted_firmware(httpd_req_t *req) {
    httpd_resp_send_err(req, HTTPD_403_FORBIDDEN,
        "OTA locked: device-side signed manifest verification and rollback testing required");
    return ESP_FAIL;
}

/* Fail closed until a unique bench token has been provisioned into NVS. */
static bool authorised(httpd_req_t *req) {
    char supplied[80] = {0}, expected[80] = {0};
    size_t size = sizeof(expected);
    nvs_handle_t handle;
    if (httpd_req_get_hdr_value_str(req, "X-Lab-Token", supplied, sizeof(supplied)) != ESP_OK ||
        nvs_open("recovery", NVS_READONLY, &handle) != ESP_OK) return false;
    esp_err_t err = nvs_get_str(handle, "api_token", expected, &size);
    nvs_close(handle);
    if (err != ESP_OK || size < 33 || size > sizeof(expected)) return false;
    unsigned char difference = 0;
    for (size_t i = 0; i < sizeof(expected); ++i) difference |= (unsigned char)(expected[i] ^ supplied[i]);
    return difference == 0;
}
static bool require_auth(httpd_req_t *req) {
    if (authorised(req)) return true;
    httpd_resp_send_err(req, HTTPD_401_UNAUTHORIZED, "Provisioned bench token required");
    return false;
}
/* Authenticated, read-only Ed25519 publisher manifest verification.
 * Verification alone never grants staging/activation permission. */
static esp_err_t verify_manifest(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    if (req->content_len <= 0 || req->content_len > 8192) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid signed manifest size");
        return ESP_FAIL;
    }
    size_t total = (size_t)req->content_len, received = 0;
    char *body = heap_caps_malloc(total + 1, MALLOC_CAP_8BIT);
    if (!body) {
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Out of memory");
        return ESP_FAIL;
    }
    while (received < total) {
        int n = httpd_req_recv(req, body + received, total - received);
        if (n <= 0) {
            heap_caps_free(body);
            httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Incomplete signed manifest");
            return ESP_FAIL;
        }
        received += (size_t)n;
    }
    body[total] = 0;
    bool valid = redone_verify_release_envelope(body, total) == 0;
    heap_caps_free(body);
    httpd_resp_set_type(req, "application/json");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    return httpd_resp_sendstr(req, valid ?
        "{\"signatureVerified\":true,\"transferEnabled\":false}" :
        "{\"signatureVerified\":false,\"transferEnabled\":false}");
}

static esp_err_t upload(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    return reject_untrusted_firmware(req);
#if 0 /* Unsafe legacy bench implementation retained for reference only. */
    staged = NULL;
    verified = false;
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
    staged = dest;
    ESP_LOGI(TAG, "Staged %s version %s; activation requires separate command", dest->label, desc.version);
    httpd_resp_sendstr(req, "Firmware staged; verify and activate separately");
    return ESP_OK;
#endif
}
static esp_err_t verify_image(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    return reject_untrusted_firmware(req);
#if 0
    esp_app_desc_t desc;
    if (!staged || esp_ota_get_partition_description(staged, &desc) != ESP_OK ||
        strcmp(desc.project_name, "efis_boot_lab")) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "No valid staged lab image");
        return ESP_FAIL;
    }
    verified = true;
    httpd_resp_sendstr(req, "Staged image validated");
    return ESP_OK;
#endif
}
static esp_err_t activate_image(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    return reject_untrusted_firmware(req);
#if 0
    if (!staged || !verified) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Verify staged image first");
        return ESP_FAIL;
    }
    esp_err_t err = esp_ota_set_boot_partition(staged);
    if (err != ESP_OK) {
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Boot selection failed");
        return ESP_FAIL;
    }
    httpd_resp_sendstr(req, "Activation accepted; rebooting");
    vTaskDelay(pdMS_TO_TICKS(500));
    esp_restart();
    return ESP_OK;
#endif
}
static esp_err_t status(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    const esp_partition_t *running = esp_ota_get_running_partition();
    const esp_partition_t *next = esp_ota_get_next_update_partition(NULL);
    const esp_app_desc_t *app = esp_app_get_description();
    esp_ota_img_states_t state = ESP_OTA_IMG_UNDEFINED;
    bool known = running && esp_ota_get_state_partition(running, &state) == ESP_OK;
    const char *boot_state = "unknown";
    if (known) {
        switch (state) {
            case ESP_OTA_IMG_NEW: boot_state = "new"; break;
            case ESP_OTA_IMG_PENDING_VERIFY: boot_state = "pending_verify"; break;
            case ESP_OTA_IMG_VALID: boot_state = "valid"; break;
            case ESP_OTA_IMG_INVALID: boot_state = "invalid"; break;
            case ESP_OTA_IMG_ABORTED: boot_state = "aborted"; break;
            default: boot_state = "undefined"; break;
        }
    }
    char response[512];
    snprintf(response, sizeof(response),
        "{\"device\":\"RedOne\",\"version\":\"%s\",\"running\":\"%s\",\"next\":\"%s\",\"rollbackAvailable\":false,\"rollbackReason\":\"Rollback not yet validated on bench\",\"updateReady\":false,\"apiVersion\":1,\"bootState\":\"%s\"}",
        app->version, running ? running->label : "unknown", next ? next->label : "unknown", boot_state);
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
    httpd_uri_t manifest = {.uri="/firmware/verify-manifest", .method=HTTP_POST, .handler=verify_manifest};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &manifest));
    httpd_uri_t check = {.uri="/verify", .method=HTTP_POST, .handler=verify_image};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &check));
    httpd_uri_t activate = {.uri="/activate", .method=HTTP_POST, .handler=activate_image};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &activate));
    ESP_LOGW(TAG, "Bench OTA requires provisioned NVS token; no default credentials");
}
