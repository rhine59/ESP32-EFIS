#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "monocypher-ed25519.h"
#include "redone_signature.h"
static void hex(uint8_t *out, const char *s, size_t n) {
    for (size_t i=0;i<n;i++) { unsigned x=0; sscanf(s+2*i,"%2x",&x); out[i]=(uint8_t)x; }
}
int main(void) {
    /* RFC 8032 section 7.1, Ed25519 test vector 1: empty message. */
    uint8_t pk[32],sig[64];
    hex(pk,"d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",32);
    hex(sig,"e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e06522490155"
            "5fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b",64);
    if (crypto_ed25519_check(sig,pk,(const uint8_t*)"",0)) return 1;
    if (!crypto_ed25519_check(sig,pk,(const uint8_t*)"x",1)) return 2;
    sig[0]^=1;
    if (!crypto_ed25519_check(sig,pk,(const uint8_t*)"",0)) return 3;
    if (!redone_verify_release_signature("invalid",sig,(const uint8_t*)"x",1)) return 4;
    if (!redone_verify_release_signature("redone-v1",sig,(const uint8_t*)"x",1)) return 5;
    if (!redone_verify_release_signature("redone-v2",sig,(const uint8_t*)"x",1)) return 6;
    if (!redone_verify_release_signature("redone-v1",sig,(const uint8_t*)"",0)) return 7;
    puts("PASS: RFC8032 valid/tampered signature and RedOne trust-key rejection");
    return 0;
}
