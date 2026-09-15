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
    /* QEMU-only test metadata. Ignored by normal aircraft/bench presentation. */
    bool test_overlay;
    const char *test_name;
    int test_index;
    int test_count;
    int test_seconds_left;
} instrument_data_t;

void instrument_render(uint16_t *fb, int width, int height,
                       const instrument_ui_t *ui,
                       const instrument_data_t *data);
