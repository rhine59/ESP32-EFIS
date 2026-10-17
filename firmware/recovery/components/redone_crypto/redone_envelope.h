#pragma once
#include <stddef.h>
/* Verifies publisher's signed JSON envelope and conservative hardware claims.
 * Zero on success. Does not write firmware or authorize boot selection.
 * This implementation deliberately rejects non-ASCII metadata until UTF-8
 * canonicalization equivalence is tested across publisher and device. */
int redone_verify_release_envelope(const char *json, size_t length);
