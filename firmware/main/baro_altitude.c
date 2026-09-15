#include "baro_altitude.h"

#include <math.h>

#define METRES_TO_FEET 3.280839895f
#define ISA_ALTITUDE_SCALE_M 44330.0f
#define ISA_EXPONENT 0.190294957f

bool baro_altitude_from_pressure(float pressure_hpa, float qnh_hpa, int *altitude_ft)
{
    if (!altitude_ft || !isfinite(pressure_hpa) || !isfinite(qnh_hpa)) return false;
    if (pressure_hpa < 100.0f || pressure_hpa > 1100.0f) return false;
    if (qnh_hpa < 950.0f || qnh_hpa > 1050.0f) return false;

    const float ratio = pressure_hpa / qnh_hpa;
    const float altitude_m = ISA_ALTITUDE_SCALE_M * (1.0f - powf(ratio, ISA_EXPONENT));
    if (!isfinite(altitude_m)) return false;

    const float feet = altitude_m * METRES_TO_FEET;
    *altitude_ft = (int)lroundf(feet);
    return true;
}
