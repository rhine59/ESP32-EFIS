#include "ota_floor.h"
#include <assert.h>
#include <stdio.h>
typedef struct { int32_t value; bool protected; bool readable; bool writable; bool tamper; bool lose_protection_on_read; } mock_t;
static bool protect(void *ctx) { return ((mock_t *)ctx)->protected; }
static bool read_floor(void *ctx, int32_t *floor) {
    mock_t *m=ctx;
    if (!m->readable) return false;
    *floor=m->value;
    if (m->lose_protection_on_read) m->protected=false;
    return true;
}
static bool advance(void *ctx, int32_t floor) {
    mock_t *m=ctx;
    if (!m->writable) return false;
    if (!m->tamper) m->value=floor;
    return true;
}
int main(void) {
    mock_t m={.value=12,.protected=false,.readable=true,.writable=true};
    redone_floor_backend_t b={read_floor,advance,protect,&m};
    int32_t out=0;
    assert(!redone_floor_read_trusted(&b,&out) && out==-1);
    assert(!redone_floor_advance_trusted(&b,13));
    m.protected=true;
    assert(redone_floor_read_trusted(&b,&out) && out==12);
    assert(!redone_floor_advance_trusted(&b,11));
    assert(redone_floor_advance_trusted(&b,12));
    assert(redone_floor_advance_trusted(&b,13) && m.value==13);
    m.readable=false;
    assert(!redone_floor_read_trusted(&b,&out) && out==-1);
    assert(!redone_floor_advance_trusted(&b,14));
    m.readable=true;
    m.writable=false;
    assert(!redone_floor_advance_trusted(&b,14));
    m.writable=true;
    m.lose_protection_on_read=true;
    assert(!redone_floor_advance_trusted(&b,14) && m.value==13);
    m.lose_protection_on_read=false;
    m.protected=true;
    m.tamper=true;
    assert(!redone_floor_advance_trusted(&b,14));
    assert(!redone_floor_advance_trusted(&b,-1));
    assert(!redone_floor_read_trusted(NULL,&out));
    puts("trusted floor policy PASS");
}
