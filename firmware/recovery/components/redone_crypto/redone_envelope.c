#include "redone_envelope.h"
#include "redone_signature.h"
#include "cJSON.h"
#include "mbedtls/base64.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static const char *const fields[] = {
    "build", "hardware_profile", "idf", "image_url", "minimum_allowed_version",
    "product", "release_notes", "sha256", "version"
};
static bool ascii_text(const char *s) {
    if (!s) return false;
    for (const unsigned char *p=(const unsigned char *)s; *p; p++) {
        if (*p < 32 || *p > 126) return false;
    }
    return true;
}
static bool hex_digest(const char *s) {
    if (!s || strlen(s)!=64) return false;
    for (;*s;s++) if (!( (*s>='0'&&*s<='9') || (*s>='a'&&*s<='f') || (*s>='A'&&*s<='F') )) return false;
    return true;
}
static bool exact_keys(const cJSON *object, const char *const *keys, size_t n) {
    if (!cJSON_IsObject(object)) return false;
    size_t count=0;
    for (const cJSON *item=object->child; item; item=item->next) {
        bool found=false;
        for (size_t i=0;i<n;i++) if (item->string && strcmp(item->string,keys[i])==0) found=true;
        if (!found) return false;
        for (const cJSON *prev=object->child; prev!=item; prev=prev->next)
            if (prev->string && strcmp(prev->string,item->string)==0) return false;
        count++;
    }
    return count==n;
}
int redone_verify_release_envelope(const char *json, size_t length) {
    if (!json || length==0 || length>8192) return -1;
    const char *const envelope_keys[]={"signature_format","key_id","payload","signature"};
    /* Reject embedded NUL and trailing garbage: signature covers the entire envelope. */
    if (memchr(json,0,length)!=NULL) return -1;
    char *terminated=malloc(length+1);
    if (!terminated) return -1;
    memcpy(terminated,json,length);
    terminated[length]=0;
    cJSON *root=cJSON_ParseWithLengthOpts(terminated,length+1,NULL,1);
    free(terminated);
    cJSON *canonical=NULL;
    char *bytes=NULL;
    int result=-1;
    if (!root || !exact_keys(root,envelope_keys,4)) goto done;
    const cJSON *format=cJSON_GetObjectItemCaseSensitive(root,"signature_format");
    const cJSON *key=cJSON_GetObjectItemCaseSensitive(root,"key_id");
    const cJSON *signature=cJSON_GetObjectItemCaseSensitive(root,"signature");
    const cJSON *payload=cJSON_GetObjectItemCaseSensitive(root,"payload");
    if (!cJSON_IsString(format) || strcmp(format->valuestring,"redone-ed25519-json-v1") ||
        !cJSON_IsString(key) || !ascii_text(key->valuestring) ||
        !cJSON_IsString(signature) || strlen(signature->valuestring)!=88 ||
        !exact_keys(payload,fields,sizeof(fields)/sizeof(fields[0]))) goto done;
    const cJSON *product=cJSON_GetObjectItemCaseSensitive(payload,"product");
    const cJSON *hardware=cJSON_GetObjectItemCaseSensitive(payload,"hardware_profile");
    const cJSON *url=cJSON_GetObjectItemCaseSensitive(payload,"image_url");
    const cJSON *sha=cJSON_GetObjectItemCaseSensitive(payload,"sha256");
    const cJSON *build=cJSON_GetObjectItemCaseSensitive(payload,"build");
    if (!cJSON_IsString(product) || strcmp(product->valuestring,"ESP32-EFIS") ||
        !cJSON_IsString(hardware) || strcmp(hardware->valuestring,"s3-n16r2-v1") ||
        !cJSON_IsString(url) || strncmp(url->valuestring,"https://",8) ||
        !cJSON_IsString(sha) || !hex_digest(sha->valuestring) ||
        !cJSON_IsNumber(build) || build->valuedouble<0 || build->valuedouble>2147483647 ||
        build->valuedouble!=(double)build->valueint) goto done;
    uint8_t sig[64]; size_t decoded=0;
    if (mbedtls_base64_decode(sig,sizeof(sig),&decoded,(const unsigned char *)signature->valuestring,
                              strlen(signature->valuestring))!=0 || decoded!=sizeof(sig)) goto done;
    canonical=cJSON_CreateObject();
    if (!canonical) goto done;
    for (size_t i=0;i<sizeof(fields)/sizeof(fields[0]);i++) {
        const cJSON *field=cJSON_GetObjectItemCaseSensitive(payload,fields[i]);
        cJSON *copy=NULL;
        if (strcmp(fields[i],"build")==0) copy=cJSON_CreateNumber(build->valueint);
        else if (cJSON_IsString(field) && ascii_text(field->valuestring))
            copy=cJSON_CreateString(field->valuestring);
        if (!copy || !cJSON_AddItemToObject(canonical,fields[i],copy)) { cJSON_Delete(copy); goto done; }
    }
    bytes=cJSON_PrintUnformatted(canonical);
    if (!bytes) goto done;
    result=redone_verify_release_signature(key->valuestring,sig,(const uint8_t *)bytes,strlen(bytes));
done:
    cJSON_free(bytes);
    cJSON_Delete(canonical);
    cJSON_Delete(root);
    return result;
}
