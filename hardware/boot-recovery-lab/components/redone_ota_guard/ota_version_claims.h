#pragma once
#include <stdbool.h>
#include <stdint.h>
/* Strict decimal build-floor notation: "build:<integer>". No whitespace,
 * signs, leading zeroes, overflow or semver ambiguity. */
bool redone_parse_signed_build_floor(const char *minimum_allowed_version,
                                      int32_t *build_floor);
