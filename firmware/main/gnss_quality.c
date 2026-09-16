#include "gnss_quality.h"

#include <math.h>

gnss_quality_t gnss_quality_from_accuracy(float accuracy_m,
                                          bool fix_valid,
                                          bool stale)
{
    if (!fix_valid || stale || !isfinite(accuracy_m) || accuracy_m < 0.0f) {
        return GNSS_QUALITY_INVALID;
    }
    if (accuracy_m <= 1.0f) return GNSS_QUALITY_EXCELLENT;
    if (accuracy_m <= 3.0f) return GNSS_QUALITY_GOOD;
    if (accuracy_m <= 10.0f) return GNSS_QUALITY_FAIR;
    if (accuracy_m <= 30.0f) return GNSS_QUALITY_WEAK;
    return GNSS_QUALITY_POOR;
}

const char *gnss_quality_label(gnss_quality_t quality)
{
    switch (quality) {
    case GNSS_QUALITY_EXCELLENT: return "EXCELLENT";
    case GNSS_QUALITY_GOOD: return "GOOD";
    case GNSS_QUALITY_FAIR: return "FAIR";
    case GNSS_QUALITY_WEAK: return "WEAK";
    case GNSS_QUALITY_POOR: return "POOR";
    case GNSS_QUALITY_INVALID:
    default: return "INVALID";
    }
}
