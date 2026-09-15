#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "instrument_ui.h"

typedef struct {
    float pitch_deg;
    float roll_deg;
    bool attitude_valid;
    int altitude_ft;
    bool altitude_valid;
    int heading_deg;
    bool heading_valid;
    bool simulated;
} instrument_data_t;

void instrument_render(uint16_t *fb, int width, int height,
                       const instrument_ui_t *ui,
                       const instrument_data_t *data);
