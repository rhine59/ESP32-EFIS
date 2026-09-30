#pragma once
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define AEF_CAN_DLC 8
#define AEF_CAN_ID_ENGINE_FAST 0x100u
#define AEF_CAN_ID_CHT 0x101u
#define AEF_CAN_ID_EGT_12 0x102u
#define AEF_CAN_ID_EGT_34 0x103u
#define AEF_CAN_ID_ENGINE_COOLING 0x104u
#define AEF_CAN_ID_EIU_ELECTRICAL 0x180u
#define AEF_CAN_ID_SENSOR_STATUS 0x600u
#define AEF_CAN_ID_EIU_HEALTH 0x601u

typedef struct { uint16_t rpm; uint16_t oil_pressure_cbar; int16_t oil_temperature_dC; } aef_engine_fast_t;
typedef struct { int16_t first_dC; int16_t second_dC; } aef_temp_pair_t;
typedef struct { uint8_t node_instance, page; uint8_t sensor_id[3]; uint8_t state[3]; } aef_sensor_status_t;

void aef_can_encode_engine_fast(uint8_t out[8], const aef_engine_fast_t *v);
bool aef_can_decode_engine_fast(aef_engine_fast_t *out, const uint8_t data[8], uint8_t dlc);
void aef_can_encode_temp_pair(uint8_t out[8], const aef_temp_pair_t *v);
bool aef_can_decode_temp_pair(aef_temp_pair_t *out, const uint8_t data[8], uint8_t dlc);
void aef_can_encode_sensor_status(uint8_t out[8], const aef_sensor_status_t *v);
bool aef_can_decode_sensor_status(aef_sensor_status_t *out, const uint8_t data[8], uint8_t dlc);

#ifdef __cplusplus
}
#endif
