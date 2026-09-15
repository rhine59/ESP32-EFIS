#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"

esp_err_t mcp23008_init(void);
esp_err_t mcp23008_write_gpio(uint8_t value);
esp_err_t mcp23008_set_output(unsigned bit, bool high);
esp_err_t mcp23008_read_gpio(uint8_t *value);
uint8_t mcp23008_output_shadow(void);
