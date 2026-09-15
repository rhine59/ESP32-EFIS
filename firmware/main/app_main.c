#include <stdint.h>
#include "sdkconfig.h"
#include "driver/gpio.h"
#include "esp_check.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_rgb.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "bmi088.h"
#include "horizon_renderer.h"
#include "instrument_screens.h"
#include "instrument_sim.h"
#include "instrument_ui.h"
#include "mcp23008.h"
#include "pins.h"
#include "st7701s.h"
#ifdef CONFIG_EFIS_QEMU
#include "esp_lcd_qemu_rgb.h"
#endif

static const char *TAG = "esp32_efis";
#define LCD_PCLK_HZ 30000000

#ifdef CONFIG_EFIS_BENCH_SIMULATION
#define BENCH_SIMULATION true
#else
#define BENCH_SIMULATION false
#endif

#ifndef CONFIG_EFIS_QEMU
static esp_err_t init_safe_outputs(void)
{
    const gpio_config_t o = {
        .pin_bit_mask = (1ULL << PIN_BMI088_ACC_CS) |
                        (1ULL << PIN_BMI088_GYRO_CS) |
                        (1ULL << PIN_LCD_BACKLIGHT_PWM),
        .mode = GPIO_MODE_OUTPUT,
    };
    ESP_RETURN_ON_ERROR(gpio_config(&o), TAG, "safe outputs");
    gpio_set_level(PIN_BMI088_ACC_CS, 1);
    gpio_set_level(PIN_BMI088_GYRO_CS, 1);
    gpio_set_level(PIN_LCD_BACKLIGHT_PWM, 0);
    return ESP_OK;
}

static esp_err_t init_rgb_panel(esp_lcd_panel_handle_t *po, uint16_t **f0, uint16_t **f1)
{
    const esp_lcd_rgb_panel_config_t c = {
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
    esp_lcd_panel_handle_t p = NULL;
    ESP_RETURN_ON_ERROR(esp_lcd_new_rgb_panel(&c, &p), TAG, "RGB panel");
    ESP_RETURN_ON_ERROR(esp_lcd_panel_reset(p), TAG, "reset");
    ESP_RETURN_ON_ERROR(esp_lcd_panel_init(p), TAG, "init");
    void *a = NULL;
    void *b = NULL;
    ESP_RETURN_ON_ERROR(esp_lcd_rgb_panel_get_frame_buffer(p, 2, &a, &b), TAG, "framebuffers");
    *po = p;
    *f0 = a;
    *f1 = b;
    return ESP_OK;
}
#else
static esp_err_t init_qemu_panel(esp_lcd_panel_handle_t *panel, uint16_t **fb)
{
    const esp_lcd_rgb_qemu_config_t config = {
        .width = AH_DISPLAY_WIDTH,
        .height = AH_DISPLAY_HEIGHT,
        .bpp = RGB_QEMU_BPP_16,
    };
    ESP_RETURN_ON_ERROR(esp_lcd_new_rgb_qemu(&config, panel), TAG, "QEMU RGB panel");
    ESP_RETURN_ON_ERROR(esp_lcd_panel_reset(*panel), TAG, "QEMU reset");
    ESP_RETURN_ON_ERROR(esp_lcd_panel_init(*panel), TAG, "QEMU init");
    void *buffer = NULL;
    ESP_RETURN_ON_ERROR(esp_lcd_rgb_qemu_get_frame_buffer(*panel, &buffer), TAG, "QEMU framebuffer");
    *fb = buffer;
    return ESP_OK;
}
#endif

void app_main(void)
{
    ESP_LOGW(TAG, "ESP32 EFIS - SUPPLEMENTARY/NON-PRIMARY instrument");
    ESP_LOGW(TAG, "BENCH SIMULATION: %s", BENCH_SIMULATION ? "ENABLED - SYNTHETIC DATA" : "OFF");

    instrument_ui_t ui;
    instrument_ui_init(&ui);
    instrument_data_t data = {0};
    instrument_sim_t sim;
    instrument_sim_init(&sim, BENCH_SIMULATION);
    instrument_sim_step(&sim, 0, &data);

#ifdef CONFIG_EFIS_QEMU
    ESP_LOGW(TAG, "QEMU MODE: ENABLED - NO PHYSICAL SENSOR OR DISPLAY I/O");
    ESP_LOGW(TAG, "QEMU TEST HARNESS: deterministic scenarios; 8 seconds per scenario");
    ESP_LOGW(TAG, "QEMU SCENARIO: %s", instrument_sim_scenario_name(sim.scenario));
    esp_lcd_panel_handle_t panel = NULL;
    uint16_t *fb = NULL;
    ESP_ERROR_CHECK(init_qemu_panel(&panel, &fb));
    instrument_render(fb, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT, &ui, &data);
    ESP_ERROR_CHECK(esp_lcd_rgb_qemu_refresh(panel));

    unsigned ticks = 0;
    unsigned scenario_ticks = 0;
    while (1) {
        if (++ticks >= 5) {
            ticks = 0;
            instrument_sim_step(&sim, .05f, &data);
            if (++scenario_ticks >= 160) {
                scenario_ticks = 0;
                instrument_sim_next_scenario(&sim);
                instrument_sim_step(&sim, 0, &data);
                ui.panel = (instrument_panel_t)((ui.panel + 1) % PANEL_COUNT);
                ESP_LOGW(TAG, "QEMU SCENARIO: %s | PANEL: %d",
                         instrument_sim_scenario_name(sim.scenario), (int)ui.panel);
            }
            instrument_render(fb, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT, &ui, &data);
            ESP_ERROR_CHECK(esp_lcd_rgb_qemu_refresh(panel));
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }
#else
    ESP_ERROR_CHECK(init_safe_outputs());
    ESP_ERROR_CHECK(mcp23008_init());
    ESP_ERROR_CHECK(st7701s_gpio_init());
    ESP_ERROR_CHECK(st7701s_panel_reset());
    ESP_ERROR_CHECK(st7701s_init_3wire_rgb565());

    esp_lcd_panel_handle_t panel;
    uint16_t *fb0;
    uint16_t *fb1;
    ESP_ERROR_CHECK(init_rgb_panel(&panel, &fb0, &fb1));
    instrument_render(fb0, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT, &ui, &data);
    instrument_render(fb1, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT, &ui, &data);
    ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(panel, 0, 0, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT, fb0));
    vTaskDelay(pdMS_TO_TICKS(100));
    gpio_set_level(PIN_LCD_BACKLIGHT_PWM, 1);

    bmi088_status_t imu = {0};
    esp_err_t ie = bmi088_init(&imu);
    if (ie == ESP_OK) {
        ESP_LOGI(TAG, "BMI088 communication verified");
    } else {
        ESP_LOGE(TAG, "BMI088 failed: %s", esp_err_to_name(ie));
    }

    uint16_t *draw = fb1;
    unsigned ticks = 0;
    while (1) {
        bool redraw = false;
        esp_err_t e = instrument_ui_poll(&ui, &redraw);
        if (e != ESP_OK) {
            ESP_LOGW(TAG, "control: %s", esp_err_to_name(e));
        }
        if (BENCH_SIMULATION && ++ticks >= 5) {
            ticks = 0;
            instrument_sim_step(&sim, .05f, &data);
            redraw = true;
        }
        if (redraw) {
            instrument_render(draw, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT, &ui, &data);
            ESP_ERROR_CHECK(esp_lcd_panel_draw_bitmap(panel, 0, 0, AH_DISPLAY_WIDTH, AH_DISPLAY_HEIGHT, draw));
            draw = draw == fb0 ? fb1 : fb0;
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }
#endif
}
