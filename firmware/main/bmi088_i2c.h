#pragma once
#include "bmi088.h"
#include "driver/i2c_master.h"
// Separate, opt-in BMI088 I2C transport; existing SPI driver remains unchanged.
esp_err_t bmi088_i2c_init(i2c_master_bus_handle_t bus, bmi088_status_t *status);
esp_err_t bmi088_i2c_read_sample(bmi088_sample_t *sample);
esp_err_t bmi088_i2c_deinit(void);
