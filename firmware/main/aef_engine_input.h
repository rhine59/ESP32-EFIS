#pragma once
#include <stdbool.h>
#include <stdint.h>
#include "aef_can_codec.h"

typedef struct {
    bool present;
    bool engine_fast_valid;
    uint32_t last_engine_fast_ms;
    aef_engine_fast_t engine_fast;
} aef_engine_state_t;

void aef_engine_state_init(aef_engine_state_t *s);
bool aef_engine_state_accept(aef_engine_state_t *s, uint16_t can_id, const uint8_t data[8], uint8_t dlc, uint32_t now_ms);
void aef_engine_state_tick(aef_engine_state_t *s, uint32_t now_ms);
