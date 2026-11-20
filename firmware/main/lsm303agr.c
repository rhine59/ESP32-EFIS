#include "lsm303agr.h"
#include <stddef.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#define MAG_ADDR 0x1e
#define WHO_AM_I_M 0x4f
#define WHO_AM_I_EXPECTED 0x40
#define CFG_REG_A_M 0x60
#define OUTX_L_REG_M 0x68
static esp_err_t read_reg(lsm303agr_t *s,uint8_t reg,uint8_t *buf,size_t n){
    return i2c_master_transmit_receive(s->dev,&reg,1,buf,n,100);
}
static esp_err_t write_reg(lsm303agr_t *s,uint8_t reg,uint8_t value){
    uint8_t tx[2]={reg,value};return i2c_master_transmit(s->dev,tx,2,100);
}
esp_err_t lsm303agr_init(lsm303agr_t *s,i2c_master_bus_handle_t bus){
    if(!s||!bus)return ESP_ERR_INVALID_ARG;
    s->dev=NULL;
    i2c_device_config_t cfg={.dev_addr_length=I2C_ADDR_BIT_LEN_7,.device_address=MAG_ADDR,.scl_speed_hz=100000};
    esp_err_t err=i2c_master_bus_add_device(bus,&cfg,&s->dev);
    if(err!=ESP_OK)return err;
    uint8_t id=0;
    err=read_reg(s,WHO_AM_I_M,&id,1);
    if(err==ESP_OK && id!=WHO_AM_I_EXPECTED)err=ESP_ERR_INVALID_RESPONSE;
    // Continuous conversion, 100Hz, temperature compensation enabled.
    if(err==ESP_OK)err=write_reg(s,CFG_REG_A_M,0x8c);
    if(err!=ESP_OK){(void)lsm303agr_deinit(s);return err;}
    vTaskDelay(pdMS_TO_TICKS(15));
    return ESP_OK;
}
esp_err_t lsm303agr_read(lsm303agr_t *s,lsm303agr_field_t *f){
    if(!s||!s->dev||!f)return ESP_ERR_INVALID_ARG;
    uint8_t raw[6];esp_err_t err=read_reg(s,OUTX_L_REG_M,raw,sizeof(raw));
    if(err!=ESP_OK)return err;
    int16_t x=(int16_t)((uint16_t)raw[0]|((uint16_t)raw[1]<<8));
    int16_t y=(int16_t)((uint16_t)raw[2]|((uint16_t)raw[3]<<8));
    int16_t z=(int16_t)((uint16_t)raw[4]|((uint16_t)raw[5]<<8));
    // 1.5 milligauss/LSB = 0.15 microtesla/LSB.
    f->x_ut=x*0.15f;f->y_ut=y*0.15f;f->z_ut=z*0.15f;
    return ESP_OK;
}
esp_err_t lsm303agr_deinit(lsm303agr_t *s){
    if(!s)return ESP_ERR_INVALID_ARG;
    if(!s->dev)return ESP_OK;
    esp_err_t err=i2c_master_bus_rm_device(s->dev);s->dev=NULL;return err;
}
