#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "instrument_ui.h"

typedef enum {
    GPS_FIX_NONE = 0,
    GPS_FIX_2D = 2,
    GPS_FIX_3D = 3,
} gps_fix_type_t;

typedef struct {
    float pitch_deg;
    float roll_deg;
    bool attitude_valid;
    int altitude_ft;
    bool altitude_valid;
    int heading_deg;
    bool heading_valid;

    /* GNSS position is supplementary and independently valid/fresh. */
    double gps_latitude_deg;
    double gps_longitude_deg;
    float gps_horizontal_accuracy_m;
    uint8_t gps_satellites_used;
    gps_fix_type_t gps_fix_type;
    bool gps_valid;
    bool gps_stale;

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
