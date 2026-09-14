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

esp_err_t bmi088_init(bmi088_status_t *status);
