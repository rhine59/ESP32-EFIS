#pragma once
#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"
#include "driver/i2c_master.h"

#ifdef __cplusplus
extern "C" {
#endif

/* I2C address: 0x20..0x23 depending on SA1/SA0 wiring. */
#define RM3100_I2C_ADDRESS_DEFAULT 0x20
#define RM3100_CYCLE_COUNT_DEFAULT 200
#define RM3100_TMRC_75HZ 0x93
#define RM3100_TMRC_37HZ 0x94

typedef struct {
    i2c_master_dev_handle_t dev;
    uint16_t cycle_count;
    bool continuous;
} rm3100_t;

typedef struct {
    int32_t x, y, z;       /* Signed 24-bit raw counts, sign extended */
    int64_t timestamp_us;  /* Local read timestamp, not sensor sample timestamp */
} rm3100_sample_t;

/* Caller owns the I2C master bus and must keep it alive until deinit. */
esp_err_t rm3100_init(rm3100_t *sensor, i2c_master_bus_handle_t bus,
                      uint8_t address, uint32_t scl_speed_hz);
esp_err_t rm3100_deinit(rm3100_t *sensor);
esp_err_t rm3100_get_revision(rm3100_t *sensor, uint8_t *revision);
esp_err_t rm3100_set_cycle_count(rm3100_t *sensor, uint16_t count);
esp_err_t rm3100_set_tmrc(rm3100_t *sensor, uint8_t tmrc);
esp_err_t rm3100_start_continuous(rm3100_t *sensor);
esp_err_t rm3100_stop(rm3100_t *sensor);
esp_err_t rm3100_trigger_single(rm3100_t *sensor);
esp_err_t rm3100_data_ready(rm3100_t *sensor, bool *ready);
esp_err_t rm3100_read_raw(rm3100_t *sensor, rm3100_sample_t *sample);
esp_err_t rm3100_read_when_ready(rm3100_t *sensor, rm3100_sample_t *sample,
                                  uint32_t timeout_ms);

/* Approximate conversion from raw counts to microtesla, not calibration.
 * Gain(counts/uT) ~= 0.3671 * cycle_count + 1.5 (PNI approximation).
 * Do not use for heading until mounting and hard/soft iron are calibrated. */
esp_err_t rm3100_raw_to_ut(const rm3100_t *sensor,
                           const rm3100_sample_t *sample, float xyz_ut[3]);

#ifdef __cplusplus
}
#endif
