#include "ota_version.h"
#include <limits.h>

bool redone_ota_version_allowed(bool signed_claims_verified,
    int64_t candidate_build, int64_t signed_minimum_build,
    int64_t installed_floor, int64_t running_build) {
    if (!signed_claims_verified || candidate_build < 0 ||
        candidate_build > INT32_MAX || signed_minimum_build < 0 ||
        signed_minimum_build > INT32_MAX || installed_floor < 0 ||
        installed_floor > INT32_MAX || running_build < 0 ||
        running_build > INT32_MAX) return false;
    /* Strictly newer releases only. A higher signed minimum may narrow but
     * must never relax the device's persistent floor. */
    return candidate_build > running_build &&
           candidate_build >= installed_floor &&
           candidate_build >= signed_minimum_build;
}
