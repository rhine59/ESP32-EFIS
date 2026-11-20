#include <stdint.h>
#include <stddef.h>
#include "driver/gpio.h"
#include "driver/ledc.h"
#include "esp_err.h"
#include "esp_heap_caps.h"
#include <stdlib.h>
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "esp_system.h"
#include "esp_log.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_rgb.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "st7701s.h"
#define W 480
#define H 480
#define BACKLIGHT_PWM_GPIO GPIO_NUM_42
#define BACKLIGHT_PWM_FREQ_HZ 10000
static const char *TAG="newhaven_test";
// Simulated bank-only diagnostic: precompute every scanline outside the ISR.
// Each row has at most three solid-colour spans; no per-pixel geometry.
#define SKY 0x45BF
#define GROUND 0xA345
#define WHITE 0xFFFF
#define YELLOW 0xFFE0
typedef struct { int16_t left, right; uint8_t sky_on_left; } bank_row_t;
static bank_row_t bank_rows[2][H];
static volatile int active_bank_table=0;
static void prepare_bank_table(int slot, int degrees) {
    // Fixed-point slopes for 0..15 degrees, scaled by 1024.
    static const int slope_q10[16]={0,18,36,54,72,90,108,126,144,162,181,199,217,236,255,274};
    int slope=slope_q10[abs(degrees)];
    if(degrees<0) slope=-slope;
    for(int y=0;y<H;y++) {
        bank_row_t *r=&bank_rows[slot][y];
        if(slope==0) {
            r->left=(y>=239 && y<=241)?0:W;
            r->right=(y>=239 && y<=241)?W:W;
            r->sky_on_left=(y<239)?2:((y>241)?4:1);
        } else {
            // White band covers y = 240 + slope*(x-240)/1024 +/- 1.
            int x1=240+((y-241)*1024)/slope;
            int x2=240+((y-239)*1024)/slope;
            if(x1>x2){int t=x1;x1=x2;x2=t;}
            r->left=x1<0?0:(x1>W?W:x1);
            r->right=x2<0?0:(x2>W?W:x2);
            r->sky_on_left=(slope>0)?0:3;
        }
    }
}
static bool IRAM_ATTR fill_bounce(esp_lcd_panel_handle_t panel, void *buf, int pos_px, int len_bytes, void *ctx) {
    uint16_t *pixels=(uint16_t *)buf;
    int count=len_bytes/2;
    int table=active_bank_table;
    for(int i=0;i<count;) {
        int index=pos_px+i;
        int row=index/W;
        int x0=index%W;
        int until=W-x0;
        if(until>count-i) until=count-i;
        bank_row_t r=bank_rows[table][row];
        for(int j=0;j<until;) {
            int x=x0+j;
            int end;
            uint16_t colour;
            if(r.sky_on_left==1) {colour=WHITE;end=W;}
            else if(r.sky_on_left==2) {colour=SKY;end=W;}
            else if(r.sky_on_left==4) {colour=GROUND;end=W;}
            else if(x<r.left) {colour=r.sky_on_left==3?SKY:GROUND;end=r.left;}
            else if(x<r.right) {colour=WHITE;end=r.right;}
            else {colour=r.sky_on_left==3?GROUND:SKY;end=W;}
            int n=end-x;
            if(n>until-j)n=until-j;
            for(int k=0;k<n;k++) pixels[i+j+k]=colour;
            j+=n;
        }
        // Aircraft reference is always fixed in screen coordinates.
        if(row>=246 && row<=249) {
            for(int x=185;x<=225;x++) if(x>=x0 && x<x0+until) pixels[i+x-x0]=YELLOW;
            for(int x=255;x<=295;x++) if(x>=x0 && x<x0+until) pixels[i+x-x0]=YELLOW;
        }
        if(row>=238 && row<=255)
            for(int x=237;x<=242;x++) if(x>=x0 && x<x0+until) pixels[i+x-x0]=YELLOW;
        i+=until;
    }
    return false;
}
void app_main(void) {
    gpio_config_t outputs={.pin_bit_mask=(1ULL<<40)|(1ULL<<41),.mode=GPIO_MODE_OUTPUT};
    ESP_ERROR_CHECK(gpio_config(&outputs));
    gpio_set_level(GPIO_NUM_40,1);
    gpio_set_level(GPIO_NUM_41,1);
    // Keep the external LED boost converter disabled until the panel is initialized.
    gpio_config_t bl_off = {.pin_bit_mask = (1ULL << BACKLIGHT_PWM_GPIO),
                            .mode = GPIO_MODE_OUTPUT};
    ESP_ERROR_CHECK(gpio_config(&bl_off));
    gpio_set_level(BACKLIGHT_PWM_GPIO, 0);
    ESP_ERROR_CHECK(st7701s_gpio_init());
    ESP_ERROR_CHECK(st7701s_panel_reset());
    ESP_ERROR_CHECK(st7701s_init_3wire_rgb565());
    esp_lcd_rgb_panel_config_t cfg={
        .clk_src=LCD_CLK_SRC_DEFAULT,
        .timings={.pclk_hz=18000000,.h_res=W,.v_res=H,
                  .hsync_pulse_width=20,.hsync_back_porch=60,.hsync_front_porch=40,
                  .vsync_pulse_width=6,.vsync_back_porch=10,.vsync_front_porch=10},
        .data_width=16,.num_fbs=0,.bounce_buffer_size_px=W*10,
        .hsync_gpio_num=38,.vsync_gpio_num=39,.de_gpio_num=2,.pclk_gpio_num=1,
        .disp_gpio_num=-1,
        .data_gpio_nums={4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,21},
        .flags.no_fb=true
    };
    esp_lcd_panel_handle_t panel=NULL;
    ESP_ERROR_CHECK(esp_lcd_new_rgb_panel(&cfg,&panel));
    esp_lcd_rgb_panel_event_callbacks_t callbacks={.on_bounce_empty=fill_bounce};
    ESP_ERROR_CHECK(esp_lcd_rgb_panel_register_event_callbacks(panel,&callbacks,NULL));
    prepare_bank_table(0,0);
    prepare_bank_table(1,0);
    ESP_ERROR_CHECK(esp_lcd_panel_init(panel));

    // Press BOOT (GPIO0) AFTER the application has started for >= 2 seconds
    // to request a switch back to ota_0. Never press during power-on.
    gpio_set_direction(GPIO_NUM_0, GPIO_MODE_INPUT);
    gpio_pullup_en(GPIO_NUM_0);
    // Enable PWM only after the LCD controller and RGB peripheral are ready.
    ledc_timer_config_t bl_timer = {
        .speed_mode = LEDC_LOW_SPEED_MODE, .duty_resolution = LEDC_TIMER_10_BIT,
        .timer_num = LEDC_TIMER_0, .freq_hz = BACKLIGHT_PWM_FREQ_HZ,
        .clk_cfg = LEDC_AUTO_CLK
    };
    ESP_ERROR_CHECK(ledc_timer_config(&bl_timer));
    ledc_channel_config_t bl_channel = {
        .gpio_num = BACKLIGHT_PWM_GPIO, .speed_mode = LEDC_LOW_SPEED_MODE,
        .channel = LEDC_CHANNEL_0, .intr_type = LEDC_INTR_DISABLE,
        .timer_sel = LEDC_TIMER_0, .duty = 512, .hpoint = 0
    };
    ESP_ERROR_CHECK(ledc_channel_config(&bl_channel));
    ESP_LOGI(TAG,"Simulated attitude indicator running without PSRAM; PWM GPIO42 10kHz 50 percent");
    ESP_LOGW(TAG,"Hold BOOT for 2 seconds AFTER startup to return to ota_0");
    ESP_LOGW(TAG,"SIMULATED BANK ONLY: +/-15 degrees; aircraft fixed; pitch ladder omitted for this diagnostic");
    int boot_hold_ms=0;
    // Advance one degree per 200 ms; table generation runs in task context.
    int direction=1;
    int bank_degrees=0;
    while(1){
        for (int elapsed=0; elapsed<2000; elapsed+=100) {
                if((elapsed%200)==0) {
                    bank_degrees+=direction;
                    if(bank_degrees>=15) {bank_degrees=15;direction=-1;}
                    if(bank_degrees<=-15) {bank_degrees=-15;direction=1;}
                    int inactive=1-active_bank_table;
                    prepare_bank_table(inactive,bank_degrees);
                    active_bank_table=inactive;
                }
                if (gpio_get_level(GPIO_NUM_0)==0) boot_hold_ms+=100;
                else boot_hold_ms=0;
                if (boot_hold_ms>=2000) {
                    const esp_partition_t *previous =
                        esp_partition_find_first(ESP_PARTITION_TYPE_APP,
                                                 ESP_PARTITION_SUBTYPE_APP_OTA_0,
                                                 NULL);
                    if (!previous) {
                        ESP_LOGE(TAG,"ota_0 not found; staying in test");
                        boot_hold_ms=0;
                    } else {
                        esp_err_t err=esp_ota_set_boot_partition(previous);
                        if (err==ESP_OK) {
                            ESP_LOGW(TAG,"Switching to ota_0");
                            vTaskDelay(pdMS_TO_TICKS(200));
                            esp_restart();
                        }
                        ESP_LOGE(TAG,"Switch failed: %s",esp_err_to_name(err));
                        boot_hold_ms=0;
                    }
                }
                vTaskDelay(pdMS_TO_TICKS(100));
            }
    }
}
