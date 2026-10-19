#include "redone_release_policy.h"
#include <assert.h>
#include <stdio.h>

typedef struct { bool protected; bool floor_ok; bool build_ok; int32_t floor; int32_t running; } state_t;
static bool protected(void *ctx) { return ((state_t *)ctx)->protected; }
static bool floor_read(void *ctx, int32_t *out) {
    state_t *s=ctx; if (!s->floor_ok) return false; *out=s->floor; return true;
}
static bool build_read(void *ctx, int32_t *out) {
    state_t *s=ctx; if (!s->build_ok) return false; *out=s->running; return true;
}
int main(void) {
    state_t state={true,true,true,10,12};
    redone_release_trust_t trust={protected,floor_read,build_read,&state};
    redone_verified_release_t release={.build=13,.signed_minimum_build=10};
    assert(redone_release_allowed(&release,&trust));
    assert(!redone_release_allowed(NULL,&trust));
    assert(!redone_release_allowed(&release,NULL));
    state.protected=false; assert(!redone_release_allowed(&release,&trust));
    state.protected=true; state.floor_ok=false; assert(!redone_release_allowed(&release,&trust));
    state.floor_ok=true; state.build_ok=false; assert(!redone_release_allowed(&release,&trust));
    state.build_ok=true; state.floor=14; assert(!redone_release_allowed(&release,&trust));
    state.floor=10; state.running=14; assert(!redone_release_allowed(&release,&trust));
    state.running=12; release.signed_minimum_build=13;
    assert(!redone_release_allowed(&release,&trust));
    release.signed_minimum_build=14; assert(!redone_release_allowed(&release,&trust));
    release.signed_minimum_build=-1; assert(!redone_release_allowed(&release,&trust));
    release.signed_minimum_build=10; release.build=-1;
    assert(!redone_release_allowed(&release,&trust));
    puts("release trust policy PASS");
}
