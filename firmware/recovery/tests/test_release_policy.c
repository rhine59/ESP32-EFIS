#include "redone_release_policy.h"
#include <assert.h>
#include <stdio.h>
typedef struct {int floor,running;bool protected,reads;} fixture;
static bool protected(void *p){return ((fixture*)p)->protected;}
static bool floor(void *p,int32_t *v){fixture *f=p;if(!f->reads)return false;*v=f->floor;return true;}
static bool running(void *p,int32_t *v){fixture *f=p;if(!f->reads)return false;*v=f->running;return true;}
int main(void){
 fixture f={.floor=8,.running=9,.protected=true,.reads=true};
 redone_release_trust_t t={protected,floor,running,&f};
 redone_verified_release_t v={.build=10,.signed_minimum_build=9};
 assert(redone_release_allowed(&v,&t));
 f.protected=false;assert(!redone_release_allowed(&v,&t));f.protected=true;
 f.reads=false;assert(!redone_release_allowed(&v,&t));f.reads=true;
 f.floor=11;assert(!redone_release_allowed(&v,&t));f.floor=8;
 f.running=11;assert(!redone_release_allowed(&v,&t));f.running=9;
 f.running=7;assert(!redone_release_allowed(&v,&t));f.running=9;
 v.signed_minimum_build=10;assert(!redone_release_allowed(&v,&t));
 v.signed_minimum_build=11;assert(!redone_release_allowed(&v,&t));
 v.signed_minimum_build=-1;assert(!redone_release_allowed(&v,&t));
 v.signed_minimum_build=9;v.build=-1;assert(!redone_release_allowed(&v,&t));
 v.build=10;assert(!redone_release_allowed(&v,0));assert(!redone_release_allowed(0,&t));
 puts("PASS: release policy fail-closed cases");return 0;
}
