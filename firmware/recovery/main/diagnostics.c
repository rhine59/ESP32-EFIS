#include "diagnostics.h"
#include <stdio.h>
#include <string.h>
#include "esp_system.h"
#include "esp_heap_caps.h"
#include "esp_flash.h"
#include "esp_partition.h"
#include "nvs_flash.h"
#include "esp_err.h"

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
    const esp_partition_t *nvs=esp_partition_find_first(ESP_PARTITION_TYPE_DATA,ESP_PARTITION_SUBTYPE_DATA_NVS,NULL);
    APPEND("{\"schema\":1,\"device\":\"RedOne\",\"mode\":\"recovery\",\"tests\":[");
    for (size_t i=0;i<10;i++) {
        const char *result="SKIP", *detail="Driver or safe measurement not implemented in recovery";
        char measured[160]={0};
        if (i==1) {
            result=(flash_result==ESP_OK && flash>=8*1024*1024 && free_heap>32768 && largest>16384)?"PASS":"FAIL";
            snprintf(measured,sizeof(measured),"flash=%lu bytes; free_heap=%lu; largest_block=%lu",(unsigned long)flash,(unsigned long)free_heap,(unsigned long)largest);
            detail=measured;
        } else if(i==9) {
            result=nvs?"WARN":"FAIL";
            detail=nvs?"NVS partition exists; non-destructive read/write and integrity checks not performed":"NVS partition missing";
        } else if(i==0) {
            result="SKIP";detail="No calibrated supply-voltage ADC channel configured";
        } else if(i==2 || i==3) {
            result="SKIP";detail="Requires physical UI driver and operator confirmation";
        } else if(i==8) {
            result="SKIP";detail="Wi-Fi AP and authenticated diagnostics transport not yet implemented";
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
