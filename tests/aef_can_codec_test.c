#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "../firmware/main/aef_can_codec.h"

static void same(const uint8_t a[8],const uint8_t b[8]){assert(memcmp(a,b,8)==0);}
int main(void){
 uint8_t b[8];
 const uint8_t engine[8]={0x06,0x13,0x7B,0x00,0xC4,0x03,0,0};
 aef_engine_fast_t e={4870,123,964},d={0};
 aef_can_encode_engine_fast(b,&e); same(b,engine);
 assert(aef_can_decode_engine_fast(&d,b,8)); assert(d.rpm==4870&&d.oil_pressure_cbar==123&&d.oil_temperature_dC==964);
 b[7]=1; assert(!aef_can_decode_engine_fast(&d,b,8));

 const uint8_t cht[8]={0xFC,0x03,0xB0,0x04,0,0,0,0};
 aef_temp_pair_t t={1020,1200},td={0};
 aef_can_encode_temp_pair(b,&t); same(b,cht);
 assert(aef_can_decode_temp_pair(&td,b,8)); assert(td.first_dC==1020&&td.second_dC==1200);

 const uint8_t status[8]={0,0,1,0,2,0,3,0};
 aef_sensor_status_t s={0,0,{1,2,3},{0,0,0}},sd={0};
 aef_can_encode_sensor_status(b,&s); same(b,status);
 assert(aef_can_decode_sensor_status(&sd,b,8)); assert(sd.sensor_id[2]==3&&sd.state[2]==0);
 puts("PASS: AEF-CAN C codec golden vectors");
 return 0;
}
