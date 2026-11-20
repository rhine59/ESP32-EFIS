#pragma once
#include "driver/i2c_master.h"
#include "esp_err.h"
#include <stdint.h>
// Adafruit LSM303AGR PID 4413: magnetometer-only temporary bench interface.
// Requires a pre-initialized 3.3V I2C master bus; does not own GPIOs.
typedef struct {i2c_master_dev_handle_t dev;} lsm303agr_t;
typedef struct {float x_ut,y_ut,z_ut;} lsm303agr_field_t;
esp_err_t lsm303agr_init(lsm303agr_t *sensor, i2c_master_bus_handle_t bus);
esp_err_t lsm303agr_read(lsm303agr_t *sensor, lsm303agr_field_t *field);
esp_err_t lsm303agr_deinit(lsm303agr_t *sensor);
