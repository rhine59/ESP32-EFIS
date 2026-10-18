#pragma once
#include <stdbool.h>
#include <stdint.h>
#include "redone_envelope.h"

/* Only an independently attested hardware-protected monotonic backend may
 * implement these callbacks. Mutable NVS and user-supplied values are invalid. */
typedef struct {
    bool (*hardware_protected)(void *context);
    bool (*read_floor)(void *context, int32_t *floor);
    bool (*read_running_build)(void *context, int32_t *build);
    void *context;
} redone_release_trust_t;

/* Pure, fail-closed policy for ALREADY signature-verified metadata.
 * Never stages, advances a floor, or changes boot selection. */
bool redone_release_allowed(const redone_verified_release_t *verified,
                            const redone_release_trust_t *trust);
