#include "ota_version_claims.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    int32_t floor = -1;
    assert(redone_parse_signed_build_floor("build:0", &floor) && floor == 0);
    assert(redone_parse_signed_build_floor("build:2147483647", &floor) && floor == 2147483647);
    assert(redone_parse_signed_build_floor("build:1024", &floor) && floor == 1024);
    const char *bad[] = {"", "1.2.3", "build:", "build:01", "build:-1", "build:+1",
        "build: 1", "build:1 ", "build:1.0", "build:2147483648", "build:99999999999999999", "Build:1"};
    for (unsigned i=0; i<sizeof(bad)/sizeof(bad[0]); i++) {
        floor = 999;
        assert(!redone_parse_signed_build_floor(bad[i], &floor) && floor == 0);
    }
    assert(!redone_parse_signed_build_floor(NULL, &floor));
    assert(!redone_parse_signed_build_floor("build:1", NULL));
    puts("signed build floor parsing PASS");
}
