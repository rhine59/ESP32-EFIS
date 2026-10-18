#pragma once
#include <stdbool.h>
#include <stdint.h>

/* Strict anti-downgrade gate. The candidate build and minimum version must
 * originate from a verified signed envelope; installed_floor must be stored
 * in trusted monotonic storage before activation is ever enabled. */
bool redone_ota_version_allowed(bool signed_claims_verified,
    int64_t candidate_build, int64_t signed_minimum_build,
    int64_t installed_floor, int64_t running_build);
