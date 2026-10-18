#include "ota_version.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    assert(redone_ota_version_allowed(true, 12, 10, 11, 11));
    assert(!redone_ota_version_allowed(false, 12, 10, 11, 11));
    assert(!redone_ota_version_allowed(true, 10, 10, 11, 11));
    assert(!redone_ota_version_allowed(true, 11, 10, 11, 11));
    assert(!redone_ota_version_allowed(true, 12, 13, 11, 11));
    assert(!redone_ota_version_allowed(true, 12, 10, 13, 11));
    assert(!redone_ota_version_allowed(true, -1, 0, 0, 0));
    assert(!redone_ota_version_allowed(true, 2147483648LL, 0, 0, 0));
    puts("anti-downgrade policy PASS");
}
