/* Read-only, fail-closed recovery diagnostics AP. Credentials provisioned in NVS. */
#include <stdio.h>
#include <string.h>
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "esp_http_server.h"
#include "nvs_flash.h"
#include "nvs.h"
#include "esp_log.h"
#include "diagnostics.h"
static char token[65];
static httpd_handle_t server;
static esp_err_t diagnostic_handler(httpd_req_t *req) {
    char supplied[65]={0};
    if (httpd_req_get_hdr_value_str(req,"X-RedOne-Recovery-Token",supplied,sizeof(supplied))!=ESP_OK) {
        httpd_resp_send_err(req,HTTPD_401_UNAUTHORIZED,"Authorization required"); return ESP_FAIL;
    }
    unsigned diff=(unsigned)(strlen(token)^strlen(supplied));
    for (size_t i=0;i<sizeof(token);++i) diff|=(unsigned)((unsigned char)token[i]^(unsigned char)supplied[i]);
    if(strlen(token)<32 || diff) { httpd_resp_send_err(req,HTTPD_401_UNAUTHORIZED,"Unauthorized"); return ESP_FAIL; }
    char json[4096]; recovery_diagnostics_json(json,sizeof(json));
    httpd_resp_set_type(req,"application/json");
    httpd_resp_set_hdr(req,"Cache-Control","no-store");
    return httpd_resp_sendstr(req,json);
}
void recovery_wifi_start(void) {
    if(nvs_flash_init()!=ESP_OK) { ESP_LOGE("RECOVERY","NVS unavailable; Wi-Fi disabled"); return; }
    nvs_handle_t nvs;
    if(nvs_open("recovery",NVS_READONLY,&nvs)!=ESP_OK) { ESP_LOGW("RECOVERY","Credentials not provisioned; Wi-Fi disabled"); return; }
    char password[64]={0}; size_t plen=sizeof(password),tlen=sizeof(token);
    bool ready=nvs_get_str(nvs,"ap_password",password,&plen)==ESP_OK &&
        nvs_get_str(nvs,"api_token",token,&tlen)==ESP_OK &&
        strlen(password)>=16 && strlen(password)<=63 && strlen(token)>=32;
    nvs_close(nvs);
    if(!ready) { ESP_LOGE("RECOVERY","Invalid credentials; Wi-Fi disabled"); return; }
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_ap();
    wifi_init_config_t init=WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&init));
    wifi_config_t ap={0}; uint8_t mac[6];
    ESP_ERROR_CHECK(esp_wifi_get_mac(WIFI_IF_AP,mac));
    snprintf((char*)ap.ap.ssid,sizeof(ap.ap.ssid),"RedOne_%02X%02X%02X%02X%02X%02X",mac[0],mac[1],mac[2],mac[3],mac[4],mac[5]);
    memcpy(ap.ap.password,password,strlen(password)+1);
    ap.ap.ssid_len=strlen((char*)ap.ap.ssid); ap.ap.channel=6;
    ap.ap.max_connection=1; ap.ap.authmode=WIFI_AUTH_WPA2_PSK;
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_AP));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_AP,&ap));
    memset(password,0,sizeof(password));
    ESP_ERROR_CHECK(esp_wifi_start());
    httpd_config_t cfg=HTTPD_DEFAULT_CONFIG();
    if(httpd_start(&server,&cfg)!=ESP_OK) return;
    httpd_uri_t route={.uri="/api/recovery/diagnostics",.method=HTTP_GET,.handler=diagnostic_handler};
    ESP_ERROR_CHECK(httpd_register_uri_handler(server,&route));
    ESP_LOGW("RECOVERY","Read-only diagnostic AP ready: %s",ap.ap.ssid);
}
