#include <string.h>
#include "esp_log.h"
#include "redone_envelope.h"
#include "esp_heap_caps.h"
#include "mbedtls/sha256.h"
#include "esp_partition.h"
#include "cJSON.h"
#include "ota_esp_storage.h"
#include "esp_http_server.h"
#include "esp_ota_ops.h"
#include "esp_app_desc.h"
#include "ota_boot_health.h"
#include "ota_version_claims.h"
#include "ota_version.h"
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

/* Read-only streaming SHA-256. The request is never written to flash.
 * The digest must be compared to a separately authenticated signed manifest;
 * this endpoint by itself does not authorize staging. */
static esp_err_t hash_firmware(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    const esp_partition_t *destination = esp_ota_get_next_update_partition(NULL);
    if (!destination || req->content_len < 1024 ||
        (size_t)req->content_len > destination->size) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid firmware size");
        return ESP_FAIL;
    }
    mbedtls_sha256_context sha;
    mbedtls_sha256_init(&sha);
    if (mbedtls_sha256_starts(&sha, 0) != 0) {
        mbedtls_sha256_free(&sha);
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "SHA-256 unavailable");
        return ESP_FAIL;
    }
    size_t remaining = (size_t)req->content_len;
    uint8_t buffer[1024];
    bool complete = true;
    while (remaining) {
        size_t wanted = remaining < sizeof(buffer) ? remaining : sizeof(buffer);
        int received = httpd_req_recv(req, (char *)buffer, wanted);
        if (received <= 0 || mbedtls_sha256_update(&sha, buffer, (size_t)received) != 0) {
            complete = false;
            break;
        }
        remaining -= (size_t)received;
    }
    uint8_t digest[32];
    if (complete && mbedtls_sha256_finish(&sha, digest) != 0) complete = false;
    mbedtls_sha256_free(&sha);
    if (!complete) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Incomplete or invalid firmware stream");
        return ESP_FAIL;
    }
    char response[128];
    static const char hex[] = "0123456789abcdef";
    char digest_hex[65];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        digest_hex[i * 2] = hex[digest[i] >> 4];
        digest_hex[i * 2 + 1] = hex[digest[i] & 15];
    }
    digest_hex[64] = 0;
    snprintf(response, sizeof(response),
             "{\"sha256\":\"%s\",\"bytes\":%lu,\"transferEnabled\":false}",
             digest_hex, (unsigned long)req->content_len);
    httpd_resp_set_type(req, "application/json");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    return httpd_resp_sendstr(req, response);
}

/* Atomic read-only preflight wire format:
 * 4-byte big-endian manifest length | signed JSON envelope | firmware bytes.
 * The digest is extracted ONLY after verifying the envelope signature.
 * No firmware bytes are written to flash or persisted for later activation. */
static bool receive_exact(httpd_req_t *req, uint8_t *buffer, size_t length) {
    size_t received = 0;
    while (received < length) {
        int n = httpd_req_recv(req, (char *)buffer + received, length - received);
        if (n <= 0) return false;
        received += (size_t)n;
    }
    return true;
}
static esp_err_t signed_preflight(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    const esp_partition_t *destination = esp_ota_get_next_update_partition(NULL);
    if (!destination || req->content_len < 4 + 1 + 1024 ||
        (size_t)req->content_len > (size_t)destination->size + 8192 + 4) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid preflight size");
        return ESP_FAIL;
    }
    uint8_t prefix[4];
    if (!receive_exact(req, prefix, sizeof(prefix))) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Missing manifest length");
        return ESP_FAIL;
    }
    size_t manifest_length = ((size_t)prefix[0] << 24) | ((size_t)prefix[1] << 16) |
                             ((size_t)prefix[2] << 8) | prefix[3];
    size_t total = (size_t)req->content_len;
    if (!manifest_length || manifest_length > 8192 || manifest_length > total - 4 ||
        total - 4 - manifest_length < 1024 || total - 4 - manifest_length > destination->size) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid manifest or image length");
        return ESP_FAIL;
    }
    char *manifest = heap_caps_malloc(manifest_length + 1, MALLOC_CAP_8BIT);
    if (!manifest) {
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Out of memory");
        return ESP_FAIL;
    }
    if (!receive_exact(req, (uint8_t *)manifest, manifest_length)) {
        heap_caps_free(manifest);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Incomplete signed manifest");
        return ESP_FAIL;
    }
    manifest[manifest_length] = 0;
    bool valid = redone_verify_release_envelope(manifest, manifest_length) == 0;
    char expected[65] = {0};
    if (valid) {
        cJSON *root = cJSON_ParseWithLengthOpts(manifest, manifest_length + 1, NULL, 1);
        const cJSON *payload = root ? cJSON_GetObjectItemCaseSensitive(root, "payload") : NULL;
        const cJSON *sha = payload ? cJSON_GetObjectItemCaseSensitive(payload, "sha256") : NULL;
        if (cJSON_IsString(sha) && strlen(sha->valuestring) == 64)
            memcpy(expected, sha->valuestring, 64);
        else valid = false;
        cJSON_Delete(root);
    }
    heap_caps_free(manifest);
    if (!valid) {
        httpd_resp_send_err(req, HTTPD_403_FORBIDDEN, "Invalid signed manifest");
        return ESP_FAIL;
    }
    mbedtls_sha256_context ctx;
    mbedtls_sha256_init(&ctx);
    bool complete = mbedtls_sha256_starts(&ctx, 0) == 0;
    size_t remaining = total - 4 - manifest_length;
    uint8_t buffer[1024], digest[32];
    while (complete && remaining) {
        size_t amount = remaining < sizeof(buffer) ? remaining : sizeof(buffer);
        if (!receive_exact(req, buffer, amount) ||
            mbedtls_sha256_update(&ctx, buffer, amount) != 0) { complete = false; break; }
        remaining -= amount;
    }
    if (complete) complete = mbedtls_sha256_finish(&ctx, digest) == 0;
    mbedtls_sha256_free(&ctx);
    if (!complete || remaining) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Incomplete firmware stream");
        return ESP_FAIL;
    }
    static const char hex[] = "0123456789abcdef";
    char actual[65];
    for (size_t i = 0; i < 32; ++i) {
        actual[2 * i] = hex[digest[i] >> 4];
        actual[2 * i + 1] = hex[digest[i] & 15];
    }
    actual[64] = 0;
    /* Manifest parser accepts uppercase hex; digest comparison is case-insensitive. */
    unsigned mismatch = 0;
    for (size_t i = 0; i < 64; ++i) {
        char c = expected[i];
        if (c >= 'A' && c <= 'F') c += 'a' - 'A';
        mismatch |= (unsigned)(c ^ actual[i]);
    }
    httpd_resp_set_type(req, "application/json");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    if (mismatch) {
        httpd_resp_set_status(req, "422 Unprocessable Entity");
        return httpd_resp_sendstr(req,
            "{\"signatureVerified\":true,\"imageHashMatches\":false,\"transferEnabled\":false}");
    }
    return httpd_resp_sendstr(req,
        "{\"signatureVerified\":true,\"imageHashMatches\":true,\"transferEnabled\":false}");
}

/* STAGING EXPERIMENT: compiled but never registered as an HTTP handler.
 * No on-device mutation is reachable until rollback and power-loss tests pass. */
static esp_err_t signed_staging_dry_run(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    const esp_partition_t *destination = esp_ota_get_next_update_partition(NULL);
    if (!destination || req->content_len < 4 + 1 + 1024 ||
        (size_t)req->content_len > (size_t)destination->size + 8192 + 4) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid preflight size");
        return ESP_FAIL;
    }
    uint8_t prefix[4];
    if (!receive_exact(req, prefix, sizeof(prefix))) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Missing manifest length");
        return ESP_FAIL;
    }
    size_t manifest_length = ((size_t)prefix[0] << 24) | ((size_t)prefix[1] << 16) |
                             ((size_t)prefix[2] << 8) | prefix[3];
    size_t total = (size_t)req->content_len;
    if (!manifest_length || manifest_length > 8192 || manifest_length > total - 4 ||
        total - 4 - manifest_length < 1024 || total - 4 - manifest_length > destination->size) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid manifest or image length");
        return ESP_FAIL;
    }
    char *manifest = heap_caps_malloc(manifest_length + 1, MALLOC_CAP_8BIT);
    if (!manifest) {
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Out of memory");
        return ESP_FAIL;
    }
    if (!receive_exact(req, (uint8_t *)manifest, manifest_length)) {
        heap_caps_free(manifest);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Incomplete signed manifest");
        return ESP_FAIL;
    }
    manifest[manifest_length] = 0;
    redone_verified_release_t verified_release;
    bool valid = redone_verify_release_metadata(manifest, manifest_length,
                                                  &verified_release) == 0;
    heap_caps_free(manifest);
    if (!valid) {
        httpd_resp_send_err(req, HTTPD_403_FORBIDDEN, "Invalid signed manifest");
        return ESP_FAIL;
    }
    /* Fail closed before ANY flash erase/write. A signed build floor is not
     * equivalent to a semantic version. Legacy publisher manifests are
     * rejected until the signer is migrated and independently verified. */
    int32_t signed_minimum_build = 0;
    if (!redone_parse_signed_build_floor(verified_release.minimum_allowed_version,
                                          &signed_minimum_build)) {
        httpd_resp_send_err(req, HTTPD_403_FORBIDDEN, "Unsupported signed minimum build format");
        return ESP_FAIL;
    }
    /* Operational NVS can be erased or rolled back; it is NOT trusted
     * monotonic storage. Do not invent a floor or infer running build from
     * a display version string. Until a secure, rollback-safe floor and
     * running build provenance are implemented, refuse staging. */
    const bool trusted_floor_available = false;
    const int64_t installed_floor = -1;
    const int64_t running_build = -1;
    if (!trusted_floor_available ||
        !redone_ota_version_allowed(valid, verified_release.build,
                                    signed_minimum_build, installed_floor, running_build)) {
        httpd_resp_send_err(req, HTTPD_403_FORBIDDEN, "Trusted version floor unavailable");
        return ESP_FAIL;
    }
    redone_esp_ota_storage_t esp_storage = {0};
    redone_ota_staging_t staging = {0};
    size_t remaining_image_size = total - 4 - manifest_length;
    if (!redone_esp_ota_storage_select(&esp_storage) ||
        !redone_ota_staging_begin(&staging, redone_esp_ota_storage_backend(&esp_storage),
                                   true, valid, true, remaining_image_size,
                                   esp_storage.target->size, verified_release.sha256)) {
        httpd_resp_send_err(req, HTTPD_403_FORBIDDEN, "Inactive-slot staging unavailable");
        return ESP_FAIL;
    }
    mbedtls_sha256_context ctx;
    mbedtls_sha256_init(&ctx);
    bool complete = mbedtls_sha256_starts(&ctx, 0) == 0;
    size_t remaining = total - 4 - manifest_length;
    uint8_t buffer[1024], digest[32];
    while (complete && remaining) {
        size_t amount = remaining < sizeof(buffer) ? remaining : sizeof(buffer);
        if (!receive_exact(req, buffer, amount) ||
            !redone_ota_staging_write(&staging, buffer, amount) ||
            mbedtls_sha256_update(&ctx, buffer, amount) != 0) { complete = false; break; }
        remaining -= amount;
    }
    if (complete) complete = mbedtls_sha256_finish(&ctx, digest) == 0;
    mbedtls_sha256_free(&ctx);
    if (!complete || remaining) {
        redone_ota_staging_abort(&staging);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Incomplete firmware stream");
        return ESP_FAIL;
    }
    if (!redone_ota_staging_finish(&staging, digest)) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST,
                            "Signed firmware digest or flash readback mismatch");
        return ESP_FAIL;
    }
    httpd_resp_set_type(req, "application/json");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    return httpd_resp_sendstr(req,
        "{\"signatureVerified\":true,\"imageHashMatches\":true,\"transferEnabled\":false}");
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
/* Read-only live evidence. Each true check is directly measured here;
 * unavailable sensors/display/power are explicitly false, never inferred
 * from a heartbeat, heap or Wi-Fi connection. No boot confirmation occurs. */
static esp_err_t boot_health(httpd_req_t *req) {
    if (!require_auth(req)) return ESP_FAIL;
    const esp_partition_t *running = esp_ota_get_running_partition();
    const esp_partition_t *next = esp_ota_get_next_update_partition(NULL);
    const esp_app_desc_t *app = esp_app_get_description();
    esp_ota_img_states_t state = ESP_OTA_IMG_UNDEFINED;
    bool pending = running && esp_ota_get_state_partition(running, &state) == ESP_OK &&
                   state == ESP_OTA_IMG_PENDING_VERIFY;
    bool image_ok = running && running->type == ESP_PARTITION_TYPE_APP && app &&
                    strcmp(app->project_name, "efis_boot_lab") == 0;
    bool inactive_ok = running && next && running->address != next->address &&
                       next->type == ESP_PARTITION_TYPE_APP &&
                       (next->subtype == ESP_PARTITION_SUBTYPE_APP_OTA_0 ||
                        next->subtype == ESP_PARTITION_SUBTYPE_APP_OTA_1);
    redone_boot_evidence_t evidence = {
        .image_identity_ok = image_ok,
        .firmware_self_test_ok = false, /* no validated complete self-test */
        .required_sensors_ok = false, /* external sensor hardware not assembled */
        .display_ok = false, /* physical display not validated */
        .power_ok = false, /* no measured supply/ADC threshold */
        .rollback_path_ok = false, /* physical rollback not validated */
        .operator_ground_confirmation = false,
    };
    bool may_confirm = redone_boot_may_confirm(pending ? REDONE_BOOT_PENDING : REDONE_BOOT_UNKNOWN,
                                               &evidence);
    char response[640];
    snprintf(response, sizeof(response),
        "{\"pendingVerify\":%s,\"imageIdentityOk\":%s,\"inactiveSlotPresent\":%s,"
        "\"firmwareSelfTestOk\":false,\"requiredSensorsOk\":false,"
        "\"displayOk\":false,\"powerOk\":false,\"rollbackPathOk\":false,"
        "\"operatorGroundConfirmation\":false,\"mayConfirmBoot\":%s,"
        "\"updateReady\":false,\"evidenceSource\":\"device-live-read-only\"}",
        pending ? "true" : "false", image_ok ? "true" : "false",
        inactive_ok ? "true" : "false", may_confirm ? "true" : "false");
    httpd_resp_set_type(req, "application/json");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    return httpd_resp_sendstr(req, response);
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
    httpd_uri_t health = {.uri="/boot-health", .method=HTTP_GET, .handler=boot_health};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &health));
    httpd_uri_t manifest = {.uri="/firmware/verify-manifest", .method=HTTP_POST, .handler=verify_manifest};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &manifest));
    httpd_uri_t digest = {.uri="/firmware/hash", .method=HTTP_POST, .handler=hash_firmware};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &digest));
    httpd_uri_t preflight = {.uri="/firmware/preflight", .method=HTTP_POST, .handler=signed_preflight};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &preflight));
    httpd_uri_t check = {.uri="/verify", .method=HTTP_POST, .handler=verify_image};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &check));
    httpd_uri_t activate = {.uri="/activate", .method=HTTP_POST, .handler=activate_image};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server, &activate));
    ESP_LOGW(TAG, "Bench OTA requires provisioned NVS token; no default credentials");
}
