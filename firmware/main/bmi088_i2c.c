#include "bmi088_i2c.h"
#include <string.h>
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#define ACC_ADDR 0x18
#define GYR_ADDR 0x68
static i2c_master_dev_handle_t acc, gyr;
static bool ready;
static esp_err_t rd(i2c_master_dev_handle_t d,uint8_t reg,uint8_t *p,size_t n){return i2c_master_transmit_receive(d,&reg,1,p,n,100);}
static esp_err_t wr(i2c_master_dev_handle_t d,uint8_t reg,uint8_t v){uint8_t b[]={reg,v};return i2c_master_transmit(d,b,2,100);}
static int16_t s16(const uint8_t *b){return (int16_t)((uint16_t)b[0]|((uint16_t)b[1]<<8));}
esp_err_t bmi088_i2c_deinit(void){ready=false;if(acc){i2c_master_bus_rm_device(acc);acc=NULL;}if(gyr){i2c_master_bus_rm_device(gyr);gyr=NULL;}return ESP_OK;}
esp_err_t bmi088_i2c_init(i2c_master_bus_handle_t bus,bmi088_status_t *st){
 if(!bus||!st)return ESP_ERR_INVALID_ARG;
 bmi088_i2c_deinit();memset(st,0,sizeof(*st));
 i2c_device_config_t cfg={.dev_addr_length=I2C_ADDR_BIT_LEN_7,.scl_speed_hz=100000,.device_address=ACC_ADDR};
 esp_err_t e=i2c_master_bus_add_device(bus,&cfg,&acc);if(e!=ESP_OK)return e;
 cfg.device_address=GYR_ADDR;e=i2c_master_bus_add_device(bus,&cfg,&gyr);if(e!=ESP_OK)goto fail;
 e=rd(acc,0,&st->accel_chip_id,1);if(e!=ESP_OK)goto fail;
 e=rd(gyr,0,&st->gyro_chip_id,1);if(e!=ESP_OK)goto fail;
 st->accel_ok=st->accel_chip_id==0x1e;st->gyro_ok=st->gyro_chip_id==0x0f;
 if(!st->accel_ok||!st->gyro_ok){e=ESP_ERR_INVALID_RESPONSE;goto fail;}
 e=wr(acc,0x7c,0x00);if(e!=ESP_OK)goto fail;vTaskDelay(pdMS_TO_TICKS(5));
 e=wr(acc,0x7d,0x04);if(e!=ESP_OK)goto fail;vTaskDelay(pdMS_TO_TICKS(50));
 e=wr(acc,0x41,0x01);if(e!=ESP_OK)goto fail; // +/-6g
 e=wr(gyr,0x0f,0x02);if(e!=ESP_OK)goto fail; // +/-500 dps
 ready=true;return ESP_OK;
 fail:bmi088_i2c_deinit();return e;
}
esp_err_t bmi088_i2c_read_sample(bmi088_sample_t *s){
 if(!s||!ready)return ESP_ERR_INVALID_STATE;
 uint8_t a[6],g[6];esp_err_t e=rd(acc,0x12,a,6);if(e!=ESP_OK)return e;
 e=rd(gyr,0x02,g,6);if(e!=ESP_OK)return e;
 s->accel_x_g=s16(a)/5460.0f;s->accel_y_g=s16(a+2)/5460.0f;s->accel_z_g=s16(a+4)/5460.0f;
 s->gyro_x_dps=s16(g)/65.536f;s->gyro_y_dps=s16(g+2)/65.536f;s->gyro_z_dps=s16(g+4)/65.536f;
 s->timestamp_ms=(uint32_t)(esp_timer_get_time()/1000);return ESP_OK;
}
