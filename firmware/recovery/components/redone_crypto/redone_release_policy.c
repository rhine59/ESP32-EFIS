#include "redone_release_policy.h"

bool redone_release_allowed(const redone_verified_release_t *verified,
                            const redone_release_trust_t *trust) {
    if (!verified || !trust || !trust->hardware_protected ||
        !trust->read_floor || !trust->read_running_build ||
        !trust->hardware_protected(trust->context)) return false;
    int32_t floor=-1, running=-1;
    if (!trust->read_floor(trust->context, &floor) ||
        !trust->read_running_build(trust->context, &running)) return false;
    if (floor<0 || running<0 || verified->build<0 ||
        verified->signed_minimum_build<0) return false;
    if (running<floor || verified->build<floor ||
        verified->build<running ||
        verified->signed_minimum_build>verified->build ||
        running<verified->signed_minimum_build) return false;
    return true;
}
