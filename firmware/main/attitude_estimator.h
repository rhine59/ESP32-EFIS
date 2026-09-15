#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "bmi088.h"

typedef struct {
    float pitch_deg;
    float roll_deg;
    bool valid;
    uint32_t last_sample_ms;
    bool initialized;
} attitude_estimator_t;

void attitude_estimator_init(attitude_estimator_t *state);
bool attitude_estimator_update(attitude_estimator_t *state,
                               const bmi088_sample_t *body_sample);
void attitude_estimator_check_stale(attitude_estimator_t *state,
                                    uint32_t now_ms);
