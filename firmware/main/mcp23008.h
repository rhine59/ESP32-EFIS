#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"
#include "driver/i2c_master.h"

esp_err_t mcp23008_init(void);
i2c_master_bus_handle_t mcp23008_bus_handle(void);
esp_err_t mcp23008_write_gpio(uint8_t value);
esp_err_t mcp23008_set_output(unsigned bit, bool high);
esp_err_t mcp23008_read_gpio(uint8_t *value);
uint8_t mcp23008_output_shadow(void);
