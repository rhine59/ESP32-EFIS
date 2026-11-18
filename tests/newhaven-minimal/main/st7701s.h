#pragma once

#include "esp_err.h"

esp_err_t st7701s_gpio_init(void);
esp_err_t st7701s_panel_reset(void);
esp_err_t st7701s_init_3wire_rgb565(void);
