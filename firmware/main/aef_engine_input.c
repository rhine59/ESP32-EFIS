#include "aef_engine_input.h"
#include <string.h>

#define ENGINE_FAST_TIMEOUT_MS 500u

void aef_engine_state_init(aef_engine_state_t *s){ if(s) memset(s,0,sizeof(*s)); }

bool aef_engine_state_accept(aef_engine_state_t *s,uint16_t can_id,const uint8_t data[8],uint8_t dlc,uint32_t now_ms){
 if(!s||!data) return false;
 if(can_id==AEF_CAN_ID_ENGINE_FAST){
   aef_engine_fast_t v;
   if(!aef_can_decode_engine_fast(&v,data,dlc)) return false;
   s->engine_fast=v; s->last_engine_fast_ms=now_ms; s->engine_fast_valid=true; s->present=true; return true;
 }
 return false;
}
void aef_engine_state_tick(aef_engine_state_t *s,uint32_t now_ms){
 if(!s) return;
 if(s->engine_fast_valid && (uint32_t)(now_ms-s->last_engine_fast_ms)>ENGINE_FAST_TIMEOUT_MS) s->engine_fast_valid=false;
 if(!s->engine_fast_valid) s->present=false;
}
