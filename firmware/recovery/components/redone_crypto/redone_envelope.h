#pragma once
#include <stddef.h>
/* Verifies publisher's signed JSON envelope and conservative hardware claims.
 * Zero on success. Does not write firmware or authorize boot selection.
 * This implementation deliberately rejects non-ASCII metadata until UTF-8
 * canonicalization equivalence is tested across publisher and device. */
int redone_verify_release_envelope(const char *json, size_t length);

/* Trusted fields are populated only after the Ed25519 signature validates.
 * A failed call zeroes the entire output structure. */
#include <stdint.h>
typedef struct {
    int32_t build;
    int32_t signed_minimum_build;
    uint8_t sha256[32];
    char minimum_allowed_version[64];
} redone_verified_release_t;
int redone_verify_release_metadata(const char *json, size_t length,
                                   redone_verified_release_t *verified);
