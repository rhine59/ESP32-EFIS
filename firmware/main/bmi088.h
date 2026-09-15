#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"

typedef struct {
    uint8_t accel_chip_id;
    uint8_t gyro_chip_id;
    bool accel_ok;
    bool gyro_ok;
} bmi088_status_t;

typedef struct {
    float accel_x_g;
    float accel_y_g;
    float accel_z_g;
    float gyro_x_dps;
    float gyro_y_dps;
    float gyro_z_dps;
    uint32_t timestamp_ms;
} bmi088_sample_t;

esp_err_t bmi088_init(bmi088_status_t *status);
esp_err_t bmi088_read_sample(bmi088_sample_t *sample);
