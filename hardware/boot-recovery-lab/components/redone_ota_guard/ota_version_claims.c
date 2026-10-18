#include "ota_version_claims.h"
#include <limits.h>
#include <stddef.h>
#include <string.h>

bool redone_parse_signed_build_floor(const char *text, int32_t *floor) {
    if (floor) *floor = 0;
    if (!text || !floor || strncmp(text, "build:", 6) != 0) return false;
    const char *digits = text + 6;
    if (!*digits || (digits[0] == '0' && digits[1])) return false;
    int32_t value = 0;
    for (const char *p = digits; *p; ++p) {
        if (*p < '0' || *p > '9') return false;
        int digit = *p - '0';
        if (value > (INT32_MAX - digit) / 10) return false;
        value = value * 10 + digit;
    }
    *floor = value;
    return true;
}
