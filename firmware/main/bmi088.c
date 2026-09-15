#include "bmi088.h"

#include <stdbool.h>
#include <string.h>

#include "driver/spi_master.h"
#include "esp_check.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "pins.h"

#define BMI088_ACCEL_CHIP_ID_REG   0x00
#define BMI088_ACCEL_CHIP_ID_VALUE 0x1E
#define BMI088_ACCEL_DATA_REG      0x12
#define BMI088_ACCEL_RANGE_REG     0x41
#define BMI088_ACCEL_RANGE_6G      0x01
#define BMI088_ACCEL_PWR_CONF      0x7C
#define BMI088_ACCEL_PWR_CTRL      0x7D
#define BMI088_ACCEL_PWR_ACTIVE    0x04

#define BMI088_GYRO_CHIP_ID_REG    0x00
#define BMI088_GYRO_CHIP_ID_VALUE  0x0F
#define BMI088_GYRO_DATA_REG       0x02
#define BMI088_GYRO_RANGE_REG      0x0F
#define BMI088_GYRO_RANGE_500_DPS  0x02

#define BMI088_ACCEL_LSB_PER_G     5460.0f
#define BMI088_GYRO_LSB_PER_DPS    65.536f

static const char *TAG = "bmi088";
static spi_device_handle_t s_accel;
static spi_device_handle_t s_gyro;
static bool s_ready;

static int16_t le_i16(const uint8_t *p)
{
    return (int16_t)((uint16_t)p[0] | ((uint16_t)p[1] << 8));
}

static esp_err_t accel_read_bytes(uint8_t reg, uint8_t *data, size_t len)
{
    if (len > 16) return ESP_ERR_INVALID_SIZE;
    uint8_t tx[18] = {0};
    uint8_t rx[18] = {0};
    tx[0] = (uint8_t)(reg | 0x80u);
    spi_transaction_t t = {
        .length = (len + 2) * 8,
        .tx_buffer = tx,
        .rx_buffer = rx,
    };
    ESP_RETURN_ON_ERROR(spi_device_transmit(s_accel, &t), TAG, "accel read 0x%02X", reg);
    memcpy(data, &rx[2], len); /* BMI088 accel SPI inserts one dummy byte. */
    return ESP_OK;
}

static esp_err_t gyro_read_bytes(uint8_t reg, uint8_t *data, size_t len)
{
    if (len > 16) return ESP_ERR_INVALID_SIZE;
    uint8_t tx[17] = {0};
    uint8_t rx[17] = {0};
    tx[0] = (uint8_t)(reg | 0x80u);
    spi_transaction_t t = {
        .length = (len + 1) * 8,
        .tx_buffer = tx,
        .rx_buffer = rx,
    };
    ESP_RETURN_ON_ERROR(spi_device_transmit(s_gyro, &t), TAG, "gyro read 0x%02X", reg);
    memcpy(data, &rx[1], len);
    return ESP_OK;
}

static esp_err_t accel_read(uint8_t reg, uint8_t *value)
{
    return accel_read_bytes(reg, value, 1);
}

static esp_err_t gyro_read(uint8_t reg, uint8_t *value)
{
    return gyro_read_bytes(reg, value, 1);
}

static esp_err_t accel_write(uint8_t reg, uint8_t value)
{
    uint8_t tx[2] = {(uint8_t)(reg & 0x7Fu), value};
    spi_transaction_t t = {.length = 16, .tx_buffer = tx};
    return spi_device_transmit(s_accel, &t);
}

static esp_err_t gyro_write(uint8_t reg, uint8_t value)
{
    uint8_t tx[2] = {(uint8_t)(reg & 0x7Fu), value};
    spi_transaction_t t = {.length = 16, .tx_buffer = tx};
    return spi_device_transmit(s_gyro, &t);
}

esp_err_t bmi088_init(bmi088_status_t *status)
{
    if (status == NULL) return ESP_ERR_INVALID_ARG;
    memset(status, 0, sizeof(*status));
    s_ready = false;

    const spi_bus_config_t bus_cfg = {
        .mosi_io_num = PIN_SPI_MOSI,
        .miso_io_num = PIN_SPI_MISO,
        .sclk_io_num = PIN_SPI_SCLK,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = 32,
    };
    ESP_RETURN_ON_ERROR(spi_bus_initialize(SPI2_HOST, &bus_cfg, SPI_DMA_CH_AUTO), TAG, "SPI bus");

    const spi_device_interface_config_t accel_cfg = {
        .clock_speed_hz = 5 * 1000 * 1000,
        .mode = 0,
        .spics_io_num = PIN_BMI088_ACC_CS,
        .queue_size = 2,
    };
    const spi_device_interface_config_t gyro_cfg = {
        .clock_speed_hz = 5 * 1000 * 1000,
        .mode = 0,
        .spics_io_num = PIN_BMI088_GYRO_CS,
        .queue_size = 2,
    };

    ESP_RETURN_ON_ERROR(spi_bus_add_device(SPI2_HOST, &accel_cfg, &s_accel), TAG, "add accel");
    ESP_RETURN_ON_ERROR(spi_bus_add_device(SPI2_HOST, &gyro_cfg, &s_gyro), TAG, "add gyro");
    vTaskDelay(pdMS_TO_TICKS(2));

    /* The accelerometer powers up in I2C mode. A CS rising edge from this
       discarded SPI read switches it into SPI mode until the next reset. */
    uint8_t dummy = 0;
    (void)accel_read(BMI088_ACCEL_CHIP_ID_REG, &dummy);

    ESP_RETURN_ON_ERROR(accel_read(BMI088_ACCEL_CHIP_ID_REG, &status->accel_chip_id), TAG,
                        "accelerometer chip ID");
    ESP_RETURN_ON_ERROR(gyro_read(BMI088_GYRO_CHIP_ID_REG, &status->gyro_chip_id), TAG,
                        "gyro chip ID");

    status->accel_ok = status->accel_chip_id == BMI088_ACCEL_CHIP_ID_VALUE;
    status->gyro_ok = status->gyro_chip_id == BMI088_GYRO_CHIP_ID_VALUE;
    if (!status->accel_ok || !status->gyro_ok) {
        ESP_LOGE(TAG, "chip ID mismatch accel=0x%02X gyro=0x%02X",
                 status->accel_chip_id, status->gyro_chip_id);
        return ESP_ERR_INVALID_RESPONSE;
    }

    /* Explicit ranges make the raw-to-engineering-unit conversion deterministic. */
    ESP_RETURN_ON_ERROR(accel_write(BMI088_ACCEL_RANGE_REG, BMI088_ACCEL_RANGE_6G), TAG,
                        "accelerometer range");
    ESP_RETURN_ON_ERROR(gyro_write(BMI088_GYRO_RANGE_REG, BMI088_GYRO_RANGE_500_DPS), TAG,
                        "gyro range");

    /* Enable accelerometer normal operation and allow its documented startup time. */
    ESP_RETURN_ON_ERROR(accel_write(BMI088_ACCEL_PWR_CONF, 0x00), TAG,
                        "accelerometer active configuration");
    ESP_RETURN_ON_ERROR(accel_write(BMI088_ACCEL_PWR_CTRL, BMI088_ACCEL_PWR_ACTIVE), TAG,
                        "accelerometer power");
    vTaskDelay(pdMS_TO_TICKS(50));

    s_ready = true;
    ESP_LOGI(TAG, "BMI088 ready accel=0x%02X gyro=0x%02X ranges=+/-6g,+/-500dps",
             status->accel_chip_id, status->gyro_chip_id);
    return ESP_OK;
}

esp_err_t bmi088_read_sample(bmi088_sample_t *sample)
{
    if (sample == NULL) return ESP_ERR_INVALID_ARG;
    if (!s_ready) return ESP_ERR_INVALID_STATE;

    uint8_t accel[6];
    uint8_t gyro[6];
    ESP_RETURN_ON_ERROR(accel_read_bytes(BMI088_ACCEL_DATA_REG, accel, sizeof(accel)), TAG,
                        "accelerometer sample");
    ESP_RETURN_ON_ERROR(gyro_read_bytes(BMI088_GYRO_DATA_REG, gyro, sizeof(gyro)), TAG,
                        "gyro sample");

    sample->accel_x_g = (float)le_i16(&accel[0]) / BMI088_ACCEL_LSB_PER_G;
    sample->accel_y_g = (float)le_i16(&accel[2]) / BMI088_ACCEL_LSB_PER_G;
    sample->accel_z_g = (float)le_i16(&accel[4]) / BMI088_ACCEL_LSB_PER_G;
    sample->gyro_x_dps = (float)le_i16(&gyro[0]) / BMI088_GYRO_LSB_PER_DPS;
    sample->gyro_y_dps = (float)le_i16(&gyro[2]) / BMI088_GYRO_LSB_PER_DPS;
    sample->gyro_z_dps = (float)le_i16(&gyro[4]) / BMI088_GYRO_LSB_PER_DPS;
    sample->timestamp_ms = (uint32_t)(xTaskGetTickCount() * portTICK_PERIOD_MS);
    return ESP_OK;
}
