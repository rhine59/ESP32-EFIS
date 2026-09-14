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
#define BMI088_ACCEL_PWR_CTRL      0x7D
#define BMI088_ACCEL_PWR_ACTIVE    0x04

#define BMI088_GYRO_CHIP_ID_REG    0x00
#define BMI088_GYRO_CHIP_ID_VALUE  0x0F

static const char *TAG = "bmi088";
static spi_device_handle_t s_accel;
static spi_device_handle_t s_gyro;

static esp_err_t accel_read(uint8_t reg, uint8_t *value)
{
    uint8_t tx[3] = {(uint8_t)(reg | 0x80u), 0x00, 0x00};
    uint8_t rx[3] = {0};
    spi_transaction_t t = {
        .length = 24,
        .tx_buffer = tx,
        .rx_buffer = rx,
    };
    ESP_RETURN_ON_ERROR(spi_device_transmit(s_accel, &t), TAG, "accel read 0x%02X", reg);
    *value = rx[2]; /* accelerometer SPI reads include one dummy byte */
    return ESP_OK;
}

static esp_err_t gyro_read(uint8_t reg, uint8_t *value)
{
    uint8_t tx[2] = {(uint8_t)(reg | 0x80u), 0x00};
    uint8_t rx[2] = {0};
    spi_transaction_t t = {
        .length = 16,
        .tx_buffer = tx,
        .rx_buffer = rx,
    };
    ESP_RETURN_ON_ERROR(spi_device_transmit(s_gyro, &t), TAG, "gyro read 0x%02X", reg);
    *value = rx[1];
    return ESP_OK;
}

static esp_err_t accel_write(uint8_t reg, uint8_t value)
{
    uint8_t tx[2] = {(uint8_t)(reg & 0x7Fu), value};
    spi_transaction_t t = {
        .length = 16,
        .tx_buffer = tx,
    };
    return spi_device_transmit(s_accel, &t);
}

esp_err_t bmi088_init(bmi088_status_t *status)
{
    if (status == NULL) return ESP_ERR_INVALID_ARG;
    memset(status, 0, sizeof(*status));

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

    /* First accelerometer read is intentionally discarded: its CS rising edge
       switches the accelerometer from its power-up I2C state into SPI mode. */
    uint8_t dummy = 0;
    (void)accel_read(BMI088_ACCEL_CHIP_ID_REG, &dummy);

    ESP_RETURN_ON_ERROR(accel_read(BMI088_ACCEL_CHIP_ID_REG, &status->accel_chip_id),
                        TAG, "accelerometer chip ID");
    ESP_RETURN_ON_ERROR(gyro_read(BMI088_GYRO_CHIP_ID_REG, &status->gyro_chip_id),
                        TAG, "gyro chip ID");

    status->accel_ok = status->accel_chip_id == BMI088_ACCEL_CHIP_ID_VALUE;
    status->gyro_ok = status->gyro_chip_id == BMI088_GYRO_CHIP_ID_VALUE;

    if (!status->accel_ok || !status->gyro_ok) {
        ESP_LOGE(TAG, "chip ID mismatch accel=0x%02X gyro=0x%02X",
                 status->accel_chip_id, status->gyro_chip_id);
        return ESP_ERR_INVALID_RESPONSE;
    }

    ESP_RETURN_ON_ERROR(accel_write(BMI088_ACCEL_PWR_CTRL, BMI088_ACCEL_PWR_ACTIVE),
                        TAG, "accelerometer active mode");
    vTaskDelay(pdMS_TO_TICKS(1));

    ESP_LOGI(TAG, "BMI088 detected accel=0x%02X gyro=0x%02X",
             status->accel_chip_id, status->gyro_chip_id);
    return ESP_OK;
}
