#include "redone_envelope.h"
#include "redone_signature.h"
#include "cJSON.h"
#include "mbedtls/base64.h"
#include <stdbool.h>
#include <limits.h>
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
/* Strict monotonic build-floor syntax; never accept legacy semver here. */
static bool signed_build_floor(const char *claim, int32_t *floor) {
    if (!claim || !floor || strncmp(claim, "build:", 6)) return false;
    const char *digits=claim+6;
    if (!*digits || (digits[0]=='0' && digits[1])) return false;
    int32_t value=0;
    for (const char *p=digits; *p; ++p) {
        if (*p<'0' || *p>'9') return false;
        int digit=*p-'0';
        if (value>(INT32_MAX-digit)/10) return false;
        value=value*10+digit;
    }
    *floor=value;
    return true;
}

int redone_verify_release_metadata(const char *json, size_t length,
                                   redone_verified_release_t *verified) {
    if (verified) memset(verified, 0, sizeof(*verified));
    if (!verified) return -1;
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
    if (result == 0) {
        const cJSON *minimum=cJSON_GetObjectItemCaseSensitive(payload,"minimum_allowed_version");
        if (!cJSON_IsString(minimum) || !ascii_text(minimum->valuestring) ||
            strlen(minimum->valuestring)>=sizeof(verified->minimum_allowed_version)) {
            result=-1;
            goto done;
        }
        int32_t signed_floor=-1;
        if (!signed_build_floor(minimum->valuestring, &signed_floor) ||
            signed_floor>build->valueint) {
            result=-1;
            goto done;
        }
        verified->build=build->valueint;
        verified->signed_minimum_build=signed_floor;
        memcpy(verified->minimum_allowed_version,minimum->valuestring,
               strlen(minimum->valuestring)+1);
        for (size_t i=0;i<32;i++) {
            char a=sha->valuestring[i*2],b=sha->valuestring[i*2+1];
            unsigned hi=(unsigned)(a>='0'&&a<='9'?a-'0':(a>='a'&&a<='f'?a-'a'+10:a-'A'+10));
            unsigned lo=(unsigned)(b>='0'&&b<='9'?b-'0':(b>='a'&&b<='f'?b-'a'+10:b-'A'+10));
            verified->sha256[i]=(uint8_t)((hi<<4)|lo);
        }
    }
done:
    cJSON_free(bytes);
    cJSON_Delete(canonical);
    cJSON_Delete(root);
    if (result != 0) memset(verified, 0, sizeof(*verified));
    return result;
}

int redone_verify_release_envelope(const char *json, size_t length) {
    redone_verified_release_t verified;
    return redone_verify_release_metadata(json, length, &verified);
}
