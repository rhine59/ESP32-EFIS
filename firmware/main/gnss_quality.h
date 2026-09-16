#pragma once

#include <stdbool.h>

typedef enum {
    GNSS_QUALITY_INVALID = 0,
    GNSS_QUALITY_POOR,
    GNSS_QUALITY_WEAK,
    GNSS_QUALITY_FAIR,
    GNSS_QUALITY_GOOD,
    GNSS_QUALITY_EXCELLENT,
} gnss_quality_t;

gnss_quality_t gnss_quality_from_accuracy(float horizontal_accuracy_m,
                                          bool fix_valid,
                                          bool stale);
const char *gnss_quality_label(gnss_quality_t quality);
