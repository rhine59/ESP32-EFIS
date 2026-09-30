#include "aef_can_codec.h"
#include <string.h>

static void put_u16(uint8_t *p,uint16_t v){p[0]=(uint8_t)v;p[1]=(uint8_t)(v>>8);}
static uint16_t get_u16(const uint8_t *p){return (uint16_t)p[0]|((uint16_t)p[1]<<8);}
static void put_i16(uint8_t *p,int16_t v){put_u16(p,(uint16_t)v);}
static int16_t get_i16(const uint8_t *p){return (int16_t)get_u16(p);}

void aef_can_encode_engine_fast(uint8_t out[8],const aef_engine_fast_t *v){
 memset(out,0,8); put_u16(out,v->rpm); put_u16(out+2,v->oil_pressure_cbar); put_i16(out+4,v->oil_temperature_dC);
}
bool aef_can_decode_engine_fast(aef_engine_fast_t *out,const uint8_t data[8],uint8_t dlc){
 if(!out||!data||dlc!=8||data[6]||data[7]) return false;
 out->rpm=get_u16(data); out->oil_pressure_cbar=get_u16(data+2); out->oil_temperature_dC=get_i16(data+4); return true;
}
void aef_can_encode_temp_pair(uint8_t out[8],const aef_temp_pair_t *v){
 memset(out,0,8); put_i16(out,v->first_dC); put_i16(out+2,v->second_dC);
}
bool aef_can_decode_temp_pair(aef_temp_pair_t *out,const uint8_t data[8],uint8_t dlc){
 if(!out||!data||dlc!=8||data[4]||data[5]||data[6]||data[7]) return false;
 out->first_dC=get_i16(data); out->second_dC=get_i16(data+2); return true;
}
void aef_can_encode_sensor_status(uint8_t out[8],const aef_sensor_status_t *v){
 out[0]=v->node_instance; out[1]=v->page;
 for(int i=0;i<3;i++){out[2+i*2]=v->sensor_id[i];out[3+i*2]=v->state[i];}
}
bool aef_can_decode_sensor_status(aef_sensor_status_t *out,const uint8_t data[8],uint8_t dlc){
 if(!out||!data||dlc!=8) return false;
 out->node_instance=data[0]; out->page=data[1];
 for(int i=0;i<3;i++){out->sensor_id[i]=data[2+i*2];out->state[i]=data[3+i*2];if(out->state[i]>7)return false;}
 return true;
}
