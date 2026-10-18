#include "ota_staging.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
typedef struct { size_t count; bool fail_write, fail_read, aborted; uint8_t digest[32]; } fake;
static bool begin(void *p, size_t n) { (void)n; ((fake *)p)->count=0; return true; }
static bool write_bytes(void *p, const uint8_t *b, size_t n) {
    (void)b; fake *f=p; if(f->fail_write)return false; f->count+=n; return true;
}
static bool read_hash(void *p, uint8_t d[32]) {
    fake *f=p; if(f->fail_read)return false; memcpy(d,f->digest,32);return true;
}
static void abort_io(void *p) { ((fake *)p)->aborted=true; }
static redone_ota_storage_t io(fake *f) {
    return (redone_ota_storage_t){f,begin,write_bytes,read_hash,abort_io};
}
int main(void) {
    uint8_t data[1024]={0}, hash[32]={7};
    fake f={0}; memcpy(f.digest,hash,32);
    redone_ota_staging_t s={0};
    assert(!redone_ota_staging_begin(&s,io(&f),false,true,true,2048,4096,hash));
    assert(redone_ota_staging_begin(&s,io(&f),true,true,true,2048,4096,hash));
    assert(redone_ota_staging_write(&s,data,1024));
    redone_ota_staging_t after_reset={0};
    assert(!redone_ota_guard_can_activate(&after_reset.guard,true,true));
    redone_ota_staging_abort(&s); assert(f.aborted);
    memset(&s,0,sizeof(s)); f.aborted=false; f.fail_write=true;
    assert(redone_ota_staging_begin(&s,io(&f),true,true,true,2048,4096,hash));
    assert(!redone_ota_staging_write(&s,data,1024)); assert(f.aborted);
    memset(&s,0,sizeof(s)); f.aborted=false; f.fail_write=false;
    assert(redone_ota_staging_begin(&s,io(&f),true,true,true,2048,4096,hash));
    assert(redone_ota_staging_write(&s,data,1024));
    assert(!redone_ota_staging_finish(&s,hash)); assert(f.aborted);
    memset(&s,0,sizeof(s)); f.aborted=false; f.fail_read=true;
    assert(redone_ota_staging_begin(&s,io(&f),true,true,true,2048,4096,hash));
    assert(redone_ota_staging_write(&s,data,1024));
    assert(redone_ota_staging_write(&s,data,1024));
    assert(!redone_ota_staging_finish(&s,hash)); assert(f.aborted);
    memset(&s,0,sizeof(s)); f.fail_read=false;
    assert(redone_ota_staging_begin(&s,io(&f),true,true,true,2048,4096,hash));
    assert(redone_ota_staging_write(&s,data,1024));
    assert(redone_ota_staging_write(&s,data,1024));
    assert(redone_ota_staging_finish(&s,hash));
    assert(redone_ota_guard_can_activate(&s.guard,true,true));
    puts("staging fault injection PASS");
}
