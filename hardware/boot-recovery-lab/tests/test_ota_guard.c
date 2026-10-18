#include "ota_guard.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    redone_ota_guard_t g = {0};
    uint8_t digest[32] = {1}, bad[32] = {2};
    assert(!redone_ota_guard_begin(&g, false, true, true, 2048, 4096, digest));
    assert(!redone_ota_guard_begin(&g, true, false, true, 2048, 4096, digest));
    assert(!redone_ota_guard_begin(&g, true, true, false, 2048, 4096, digest));
    assert(!redone_ota_guard_begin(&g, true, true, true, 4097, 4096, digest));
    assert(redone_ota_guard_begin(&g, true, true, true, 2048, 4096, digest));
    assert(!redone_ota_guard_can_activate(&g, true, true));
    assert(redone_ota_guard_advance(&g, 1024));
    assert(!redone_ota_guard_finish(&g, digest, digest));
    assert(g.state == REDONE_OTA_FAILED);
    assert(!redone_ota_guard_can_activate(&g, true, true));
    redone_ota_guard_reset(&g);
    assert(redone_ota_guard_begin(&g, true, true, true, 2048, 4096, digest));
    assert(!redone_ota_guard_advance(&g, 2049));
    assert(g.state == REDONE_OTA_FAILED);
    redone_ota_guard_reset(&g);
    assert(redone_ota_guard_begin(&g, true, true, true, 2048, 4096, digest));
    assert(redone_ota_guard_advance(&g, 2048));
    assert(!redone_ota_guard_finish(&g, digest, bad));
    redone_ota_guard_reset(&g);
    assert(redone_ota_guard_begin(&g, true, true, true, 2048, 4096, digest));
    assert(redone_ota_guard_advance(&g, 2048));
    assert(redone_ota_guard_finish(&g, digest, digest));
    assert(!redone_ota_guard_can_activate(&g, false, true));
    assert(!redone_ota_guard_can_activate(&g, true, false));
    assert(redone_ota_guard_can_activate(&g, true, true));
    redone_ota_guard_abort(&g);
    assert(!redone_ota_guard_can_activate(&g, true, true));
    puts("OTA guard tests passed");
    return 0;
}
