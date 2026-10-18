"""Publisher-side validation of signed monotonic build claims.

This module validates metadata only; it never publishes or signs releases.
"""
import re

MAX_BUILD = 2_147_483_647
BUILD_FLOOR = re.compile(r'build:(0|[1-9][0-9]*)\Z', re.ASCII)
BUILD_NUMBER = re.compile(r'(0|[1-9][0-9]*)\Z', re.ASCII)


def validate_release_build(build, minimum_allowed_version):
    if isinstance(build, bool):
        raise ValueError('Build must be a nonnegative int32')
    if isinstance(build, int):
        candidate = build
    elif isinstance(build, str) and BUILD_NUMBER.fullmatch(build):
        candidate = int(build)
    else:
        raise ValueError('Build must be a nonnegative decimal int32')
    if not 0 <= candidate <= MAX_BUILD:
        raise ValueError('Build exceeds signed int32 range')
    match = BUILD_FLOOR.fullmatch(minimum_allowed_version) if isinstance(minimum_allowed_version, str) else None
    if not match:
        raise ValueError('Minimum must be build:<nonnegative int32>')
    floor = int(match.group(1))
    if floor > MAX_BUILD or floor > candidate:
        raise ValueError('Minimum build must not exceed candidate build or int32')
    return candidate, floor
