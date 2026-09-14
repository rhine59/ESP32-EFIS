#include <stdint.h>

#include "driver/gpio.h"
#include "esp_check.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_rgb.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "bmi088.h"
#include "horizon_renderer.h"
#include "mcp23008.h"
#include "pins.h"
#include "st7701s.h"

static const char *TAG = "artificial_horizon";

#define LCD_PCLK_HZ 30000000

static esp_err_t init_safe_outputs(void)
{
    const gpio_config_t outputs = {
        .pin_bit_mask = (1ULL << PIN_BMI088_ACC_CS) |
                        (1ULL << PIN_BMI088_GYRO_CS) |
                        (1ULL << PIN_LCD_BACKLIGHT_PWM),
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    ESP_RETURN_ON_ERROR(gpio_config(&outputs), TAG, "configure safe outputs");

    gpio_set_level(PIN_BMI088_ACC_CS, 1);
    gpio_set_level(PIN_BMI088_GYRO_CS, 1);
    gpio_set_level(PIN_LCD_BACKLIGHT_PWM, 0);
    return ESP_OK;
}

static esp_err_t init_rgb_panel(esp_lcd_panel_handle_t *panel_out,
                                uint16_t **fb0_out,
                                uint16_t **fb1_out)
{
    const esp_lcd_rgb_panel_config_t cfg = {
        .clk_src = LCD_CLK_SRC_DEFAULT,
        .timings = {
            .pclk_hz = LCD_PCLK_HZ,
            .h_res = AH_DISPLAY_WIDTH,
            .v_res = AH_DISPLAY_HEIGHT,
            .hsync_pulse_width = 4,
            .hsync_back_porch = 50,
            .hsync_front_porch = 50,
            .vsync_pulse_width = 2,
            .vsync_back_porch = 50,
            .vsync_front_porch = 50,
        },
        .data_width = 16,
        .num_fbs = 2,
        .hsync_gpio_num = PIN_LCD_HSYNC,
        .vsync_gpio_num = PIN_LCD_VSYNC,
        .de_gpio_num = PIN_LCD_DE,
        .pclk_gpio_num = PIN_LCD_PCLK,
        .disp_gpio_num = -1,
        .data_gpio_nums = {
            PIN_LCD_D0, PIN_LCD_D1, PIN_LCD_D2, PIN_LCD_D3,
            PIN_LCD_D4, PIN_LCD_D5, PIN_LCD_D6, PIN_LCD_D7,
            PIN_LCD_D8, PIN_LCD_D9, PIN_LCD_D10, PIN_LCD_D11,
            PIN_LCD_D12, PIN_LCD_D13, PIN_LCD_D14, PIN_LCD_D15,
        },
        .flags.fb_in_psram = true,
    };

    esp_lcd_panel_handle_t panel = NULL;
    ESP_RETURN_ON_ERROR(esp_lcd_new_rgb_panel(&cfg, &panel), TAG, "create RGB panel");
    ESP_RETURN_ON_ERROR(esp_lcd_panel_reset(panel), TAG, "RGB panel reset");
    ESP_RETURN_ON_ERROR(esp_lcd_panel_init(panel), TAG, "RGB panel init");

    void *fb0 = NULL;
    void *fb1 = NULL;
    ESP_RETURN_ON_ERROR(esp_lcd_rgb_panel_get_frame_buffer(panel, 2, &fb0, &fb1),
                        TAG, "get RGB framebuffers");

    *panel_out = panel;
    *fb0_out = (uint16_t *)fb0;
    *fb1_out = (uint16_t *)fb1;
    return ESP_OK;
}

void app_main(void)
{
    ESP_LOGI(TAG, "ESP32 Artificial Horizon firmware proof-of-life");
    ESP_LOGI(TAG, "supplementary/non-primary development instrument");

    ESP_ERROR_CHECK(init_safe_outputs());
    ESP_ERROR_CHECK(mcp23008_init());
    ESP_ERROR_CHECK(st7701s_gpio_init());
    ESP_ERROR_CHECK(st7701s_panel_reset());
    ESP_ERROR_CHECK(st7701s_init_3wire_rgb565());

    esp_lcd_panel_handle_t panel = NULL;
    uint16_t *fb0 = NULL;
    uint16_t *fb1 = NULL;
    ESP_ERROR_CHECK(init_rgb_panel(&panel, &fb0, &fb1));

    horizon_render_static(fb0, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT);
    horizon_render_static(fb1, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT);

    /* Select the first prepared frame and only then enable the backlight. */
    ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(panel, 0, 0,
                                              AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT,
                                              fb0));
    vTaskDelay(pdMS_TO_TICKS(100));
    gpio_set_level(PIN_LCD_BACKLIGHT_PWM, 1);
    ESP_LOGI(TAG, "static horizon active; backlight enabled");

    /* BMI088 bring-up is deliberately non-fatal at this stage so the display
       proof-of-life remains usable while sensor wiring is commissioned. */
    bmi088_status_t imu = {0};
    esp_err_t imu_err = bmi088_init(&imu);
    if (imu_err == ESP_OK) {
        ESP_LOGI(TAG, "BMI088 communication verified");
    } else {
        ESP_LOGE(TAG, "BMI088 bring-up failed: %s", esp_err_to_name(imu_err));
    }

    ESP_LOGW(TAG, "AHRS is not active yet; horizon is a static test image");

    while (true) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
