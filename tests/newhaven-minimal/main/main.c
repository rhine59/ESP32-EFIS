#include <stdint.h>
#include <stddef.h>
#include "driver/gpio.h"
#include "driver/ledc.h"
#include "esp_err.h"
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
// PSRAM-free simulated attitude instrument: ISR draws directly into RGB DMA bounce strips.
// Simulation is deliberately not connected to flight sensors; NOT FOR FLIGHT USE.
static volatile int pitch_px=0, bank_slope=0;
static inline int absi(int v) { return v<0?-v:v; }
static bool IRAM_ATTR fill_bounce(esp_lcd_panel_handle_t panel, void *buf, int pos_px, int len_bytes, void *ctx) {
    uint16_t *pixels=(uint16_t *)buf;
    const int pitch=pitch_px, slope=bank_slope;
    for (int i=0;i<len_bytes/2;i++) {
        int n=pos_px+i, x=n%W, y=n/W;
        int dx=x-W/2, dy=y-H/2;
        int horizon=H/2+pitch+(dx*slope)/256;
        uint16_t color=(y<horizon)?0x45BF:0xA345; // sky blue / earth brown
        if (absi(y-horizon)<=1) color=0xFFFF;
        // Pitch ladder, short white bars at 10-degree intervals (24 pixels each).
        for (int k=-3;k<=3;k++) {
            if (k==0) continue;
            int ly=horizon+k*24;
            if (absi(y-ly)<=1 && absi(dx)<((k%2)==0?58:34)) color=0xFFFF;
        }
        // Fixed aircraft symbol: wings, center reticle and nose.
        if ((absi(dy)<=2 && absi(dx)>=15 && absi(dx)<=88) ||
            (absi(dx)<=2 && dy>=-13 && dy<=13) ||
            (absi(dy+9)<=2 && absi(dx)<=12)) color=0xFFE0;
        // Bank index marks across the upper arc.
        if (y>=28 && y<=38 && (absi(dx)==0 || absi(dx)==65 || absi(dx)==120)) color=0xFFFF;
        pixels[i]=color;
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
    int boot_hold_ms=0;
    while(1){
        for(int c=0;c<8;c++){
            static const int pitches[]={0,12,25,12,0,-12,-25,-12};
            static const int banks[]={0,24,48,24,0,-24,-48,-24};
            pitch_px=pitches[c]; bank_slope=banks[c];
            ESP_LOGI(TAG,"Simulated attitude step %d: pitch_offset=%d slope=%d",c,pitch_px,bank_slope);
            for (int elapsed=0; elapsed<2000; elapsed+=100) {
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
}
