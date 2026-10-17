#include "diagnostics.h"
#include <stdio.h>
#include <string.h>
#include "esp_system.h"
#include "esp_heap_caps.h"
#include "esp_flash.h"
#include "esp_partition.h"
#include "nvs_flash.h"
#include "esp_err.h"
#include "esp_wifi.h"
#include "esp_ota_ops.h"
#include "esp_app_desc.h"

static const char *const ids[] = {"power","memory_flash","display_backlight","encoder_button","bmi088","bmp585","rm3100","can_smux","wifi","nvs"};
static const char *const names[] = {"Power supply and voltage monitoring","ESP32 memory and flash","Display and backlight","Rotary encoder and push switch","BMI088 attitude sensor","BMP585 pressure sensor","RM3100 magnetometer","CAN bus and SMUX","Wi-Fi communications","Non-volatile configuration"};
void recovery_diagnostics_json(char *out, size_t capacity) {
    if (!out || !capacity) return;
    size_t pos=0;
#define APPEND(...) do { if (pos<capacity) { int n=snprintf(out+pos,capacity-pos,__VA_ARGS__); if(n<0)return; pos += (size_t)n; } } while(0)
    uint32_t flash=0;
    esp_err_t flash_result=esp_flash_get_size(NULL,&flash);
    size_t free_heap=heap_caps_get_free_size(MALLOC_CAP_8BIT);
    size_t largest=heap_caps_get_largest_free_block(MALLOC_CAP_8BIT);
    size_t psram=heap_caps_get_total_size(MALLOC_CAP_SPIRAM);
    size_t psram_free=heap_caps_get_free_size(MALLOC_CAP_SPIRAM);
    const esp_partition_t *running=esp_ota_get_running_partition();
    const esp_partition_t *ota_a=esp_partition_find_first(ESP_PARTITION_TYPE_APP,ESP_PARTITION_SUBTYPE_APP_OTA_0,NULL);
    const esp_partition_t *ota_b=esp_partition_find_first(ESP_PARTITION_TYPE_APP,ESP_PARTITION_SUBTYPE_APP_OTA_1,NULL);
    wifi_sta_list_t clients={0};
    esp_err_t clients_result=esp_wifi_ap_get_sta_list(&clients);
    wifi_mode_t wifi_mode=WIFI_MODE_NULL;
    esp_err_t wifi_result=esp_wifi_get_mode(&wifi_mode);
    const esp_partition_t *nvs=esp_partition_find_first(ESP_PARTITION_TYPE_DATA,ESP_PARTITION_SUBTYPE_DATA_NVS,NULL);
    APPEND("{\"schema\":1,\"device\":\"RedOne\",\"mode\":\"recovery\",\"tests\":[");
    for (size_t i=0;i<10;i++) {
        const char *result="SKIP", *detail="Not Tested: external peripheral is not verified as fitted or wired on this bench; bus probing is disabled until carrier pinout and safe test driver are confirmed";
        char measured[480]={0};
        if (i==1) {
            result=(flash_result==ESP_OK && flash>=8*1024*1024 && free_heap>32768 && largest>16384)?"PASS":"FAIL";
            snprintf(measured,sizeof(measured),"Read flash capacity: %lu bytes; free internal-capable heap: %lu bytes; largest allocation: %lu bytes; PSRAM visible to recovery allocator: %lu total, %lu free (not initialized in this firmware). Expected flash >=8MB, heap >32KB, block >16KB.",(unsigned long)flash,(unsigned long)free_heap,(unsigned long)largest,(unsigned long)psram,(unsigned long)psram_free);
            detail=measured;
        } else if(i==9) {
            result=nvs?"PASS":"FAIL";
            snprintf(measured,sizeof(measured),"Read partition table: NVS %s; recovery running in factory slot: %s; OTA A partition: %s; OTA B partition: %s. No NVS write or credential integrity check performed.",nvs?"present":"MISSING",running && running->subtype==ESP_PARTITION_SUBTYPE_APP_FACTORY?"yes":"NO",ota_a?"present":"MISSING",ota_b?"present":"MISSING");
            result=(nvs && running && running->subtype==ESP_PARTITION_SUBTYPE_APP_FACTORY && ota_a && ota_b)?"PASS":"FAIL";
            detail=measured;
        } else if(i==0) {
            result="SKIP";detail="Not Tested: no validated supply-voltage ADC channel or calibration on this carrier; no electrical measurement attempted";
        } else if(i==2 || i==3) {
            result="SKIP";detail="Not Tested: display/encoder are on external carrier hardware; no safe driver and operator-confirmation procedure enabled in recovery";
        } else if(i==8) {
            result=(wifi_result==ESP_OK && (wifi_mode==WIFI_MODE_AP || wifi_mode==WIFI_MODE_APSTA))?"PASS":"FAIL";
            snprintf(measured,sizeof(measured),"Queried Wi-Fi operating mode and associated station list: mode=%d (AP=2, APSTA=3); station-query=%s; connected clients=%d. HTTP response itself proves diagnostics handler ran; no radio signal-quality test performed.",(int)wifi_mode,esp_err_to_name(clients_result),clients_result==ESP_OK?clients.num:-1);
            result=(result[0]=='P' && clients_result==ESP_OK)?"PASS":"FAIL";
            detail=measured;
        }
        APPEND("%s{\"id\":\"%s\",\"name\":\"%s\",\"result\":\"%s\",\"detail\":\"%s\"}",i?",":"",ids[i],names[i],result,detail);
    }
    APPEND("]}");
    out[capacity-1]='\0';
#undef APPEND
}
void recovery_diagnostics_print(void) {
    char report[4096];
    recovery_diagnostics_json(report,sizeof(report));
    puts(report);
}
