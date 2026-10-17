#include "rm3100.h"
#include <string.h>
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define REG_POLL 0x00
#define REG_CMM 0x01
#define REG_CCX 0x04
#define REG_TMRC 0x0B
#define REG_MX 0x24
#define REG_STATUS 0x34
#define REG_REVID 0x36
#define AXES_ALL 0x70
#define CMM_START 0x01
#define STATUS_DRDY 0x80
#define BUS_TIMEOUT_MS 100

static esp_err_t write_reg(rm3100_t *s, uint8_t reg, const uint8_t *data, size_t len)
{
    if (!s || !s->dev || !data || len > 8) return ESP_ERR_INVALID_ARG;
    uint8_t buffer[9];
    buffer[0] = reg;
    memcpy(buffer + 1, data, len);
    return i2c_master_transmit(s->dev, buffer, len + 1, BUS_TIMEOUT_MS);
}

static esp_err_t read_reg(rm3100_t *s, uint8_t reg, uint8_t *out, size_t len)
{
    if (!s || !s->dev || !out || !len) return ESP_ERR_INVALID_ARG;
    return i2c_master_transmit_receive(s->dev, &reg, 1, out, len, BUS_TIMEOUT_MS);
}

static esp_err_t write_byte(rm3100_t *s, uint8_t reg, uint8_t value)
{
    return write_reg(s, reg, &value, 1);
}

esp_err_t rm3100_init(rm3100_t *s, i2c_master_bus_handle_t bus,
                      uint8_t address, uint32_t scl_speed_hz)
{
    if (!s || !bus || address < 0x20 || address > 0x23 || !scl_speed_hz)
        return ESP_ERR_INVALID_ARG;
    memset(s, 0, sizeof(*s));
    i2c_device_config_t cfg = {
        .dev_addr_length = I2C_ADDR_BIT_LEN_7,
        .device_address = address,
        .scl_speed_hz = scl_speed_hz,
    };
    esp_err_t err = i2c_master_bus_add_device(bus, &cfg, &s->dev);
    if (err != ESP_OK) return err;
    err = i2c_master_probe(bus, address, BUS_TIMEOUT_MS);
    if (err == ESP_OK) err = rm3100_stop(s);
    if (err == ESP_OK) err = rm3100_set_cycle_count(s, RM3100_CYCLE_COUNT_DEFAULT);
    if (err == ESP_OK) err = rm3100_set_tmrc(s, RM3100_TMRC_37HZ);
    if (err != ESP_OK) {
        rm3100_deinit(s);
        return err;
    }
    return ESP_OK;
}

esp_err_t rm3100_deinit(rm3100_t *s)
{
    if (!s) return ESP_ERR_INVALID_ARG;
    esp_err_t err = ESP_OK;
    if (s->dev) {
        (void)rm3100_stop(s);
        err = i2c_master_bus_rm_device(s->dev);
    }
    memset(s, 0, sizeof(*s));
    return err;
}

esp_err_t rm3100_get_revision(rm3100_t *s, uint8_t *revision)
{
    return read_reg(s, REG_REVID, revision, 1);
}

esp_err_t rm3100_set_cycle_count(rm3100_t *s, uint16_t count)
{
    if (!s || count < 30 || count > 400) return ESP_ERR_INVALID_ARG;
    uint8_t data[6];
    for (int i = 0; i < 3; ++i) {
        data[2*i] = (uint8_t)(count >> 8);
        data[2*i+1] = (uint8_t)count;
    }
    esp_err_t err = write_reg(s, REG_CCX, data, sizeof(data));
    if (err == ESP_OK) s->cycle_count = count;
    return err;
}

esp_err_t rm3100_set_tmrc(rm3100_t *s, uint8_t tmrc)
{
    /* 0x92 (600 Hz) through 0x9F (0.075 Hz). Feasible ODR depends on CC. */
    if (tmrc < 0x92 || tmrc > 0x9F) return ESP_ERR_INVALID_ARG;
    return write_byte(s, REG_TMRC, tmrc);
}

esp_err_t rm3100_start_continuous(rm3100_t *s)
{
    esp_err_t err = write_byte(s, REG_CMM, AXES_ALL | CMM_START);
    if (err == ESP_OK) s->continuous = true;
    return err;
}

esp_err_t rm3100_stop(rm3100_t *s)
{
    esp_err_t err = write_byte(s, REG_CMM, 0);
    if (err == ESP_OK) s->continuous = false;
    return err;
}

esp_err_t rm3100_trigger_single(rm3100_t *s)
{
    if (!s || s->continuous) return ESP_ERR_INVALID_STATE;
    return write_byte(s, REG_POLL, AXES_ALL);
}

esp_err_t rm3100_data_ready(rm3100_t *s, bool *ready)
{
    if (!ready) return ESP_ERR_INVALID_ARG;
    uint8_t status = 0;
    esp_err_t err = read_reg(s, REG_STATUS, &status, 1);
    if (err == ESP_OK) *ready = (status & STATUS_DRDY) != 0;
    return err;
}

static int32_t sign_extend24(const uint8_t *p)
{
    uint32_t u = ((uint32_t)p[0] << 16) | ((uint32_t)p[1] << 8) | p[2];
    return (u & 0x800000u) ? (int32_t)(u | 0xFF000000u) : (int32_t)u;
}

esp_err_t rm3100_read_raw(rm3100_t *s, rm3100_sample_t *sample)
{
    if (!sample) return ESP_ERR_INVALID_ARG;
    uint8_t bytes[9];
    esp_err_t err = read_reg(s, REG_MX, bytes, sizeof(bytes));
    if (err != ESP_OK) return err;
    rm3100_sample_t tmp = {
        .x = sign_extend24(bytes),
        .y = sign_extend24(bytes + 3),
        .z = sign_extend24(bytes + 6),
        .timestamp_us = esp_timer_get_time(),
    };
    *sample = tmp;
    return ESP_OK;
}

esp_err_t rm3100_read_when_ready(rm3100_t *s, rm3100_sample_t *sample,
                                  uint32_t timeout_ms)
{
    if (!s || !sample) return ESP_ERR_INVALID_ARG;
    int64_t deadline = esp_timer_get_time() + (int64_t)timeout_ms * 1000;
    for (;;) {
        bool ready = false;
        esp_err_t err = rm3100_data_ready(s, &ready);
        if (err != ESP_OK) return err;
        if (ready) return rm3100_read_raw(s, sample);
        if (esp_timer_get_time() >= deadline) return ESP_ERR_TIMEOUT;
        vTaskDelay(pdMS_TO_TICKS(5) > 0 ? pdMS_TO_TICKS(5) : 1);
    }
}

esp_err_t rm3100_raw_to_ut(const rm3100_t *s,
                           const rm3100_sample_t *sample, float xyz_ut[3])
{
    if (!s || !sample || !xyz_ut || !s->cycle_count) return ESP_ERR_INVALID_ARG;
    float gain = 0.3671f * (float)s->cycle_count + 1.5f;
    xyz_ut[0] = sample->x / gain;
    xyz_ut[1] = sample->y / gain;
    xyz_ut[2] = sample->z / gain;
    return ESP_OK;
}
