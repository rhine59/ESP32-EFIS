#include "ota_floor.h"
#include <stddef.h>

bool redone_floor_read_trusted(const redone_floor_backend_t *backend,
                                int32_t *floor) {
    if (floor) *floor = -1;
    if (!backend || !floor || !backend->read || !backend->hardware_protected ||
        !backend->hardware_protected(backend->context)) return false;
    int32_t value = -1;
    if (!backend->read(backend->context, &value) || value < 0) return false;
    *floor = value;
    return true;
}

bool redone_floor_advance_trusted(const redone_floor_backend_t *backend,
                                   int32_t candidate_floor) {
    if (!backend || candidate_floor < 0 || !backend->advance) return false;
    int32_t previous = -1;
    if (!redone_floor_read_trusted(backend, &previous) || candidate_floor < previous)
        return false;
    if (candidate_floor == previous) return true;
    if (!backend->advance(backend->context, candidate_floor)) return false;
    int32_t observed = -1;
    return redone_floor_read_trusted(backend, &observed) && observed >= candidate_floor;
}
