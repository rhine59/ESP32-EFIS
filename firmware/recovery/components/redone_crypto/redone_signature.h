#pragma once
#include <stddef.h>
#include <stdint.h>
/* Verify the exact canonical JSON payload bytes signed by the publisher.
 * Never accept a hash, signature or claimed verification result from the phone
 * without verifying the signed payload independently. Returns 0 on success. */
int redone_signature_self_test(void);
int redone_verify_release_signature(const char *key_id,
                                    const uint8_t signature[64],
                                    const uint8_t *canonical_payload,
                                    size_t canonical_payload_length);
