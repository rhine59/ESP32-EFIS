#pragma once
#include <stdbool.h>
#include <stdint.h>

/* Hardware-backed monotonic counter abstraction. This policy cannot be used
 * with mutable NVS, an unverified file or a caller-provided number. */
typedef struct {
    bool (*read)(void *context, int32_t *floor);
    bool (*advance)(void *context, int32_t new_floor);
    bool (*hardware_protected)(void *context);
    void *context;
} redone_floor_backend_t;

/* Read the hardware-protected floor; never substitute zero on failure. */
bool redone_floor_read_trusted(const redone_floor_backend_t *backend,
                                int32_t *floor);
/* Commit a nondecreasing floor and read back to verify; never decrease. */
bool redone_floor_advance_trusted(const redone_floor_backend_t *backend,
                                   int32_t candidate_floor);
