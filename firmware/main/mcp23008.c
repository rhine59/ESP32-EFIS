#include "mcp23008.h"

#include "driver/i2c_master.h"
#include "esp_log.h"
#include "pins.h"

#define MCP23008_REG_IODIR 0x00
#define MCP23008_REG_GPPU  0x06
#define MCP23008_REG_GPIO  0x09
#define MCP23008_REG_OLAT  0x0A

static const char *TAG = "mcp23008";
static i2c_master_bus_handle_t s_bus;
static i2c_master_dev_handle_t s_dev;
static uint8_t s_olat;

static esp_err_t write_reg(uint8_t reg, uint8_t value)
{
    uint8_t tx[2] = {reg, value};
    return i2c_master_transmit(s_dev, tx, sizeof(tx), 100);
}

esp_err_t mcp23008_init(void)
{
    const i2c_master_bus_config_t bus_cfg = {
        .i2c_port = -1,
        .sda_io_num = PIN_IOX_SDA,
        .scl_io_num = PIN_IOX_SCL,
        .clk_source = I2C_CLK_SRC_DEFAULT,
        .glitch_ignore_cnt = 7,
        .flags.enable_internal_pullup = true,
    };
    ESP_RETURN_ON_ERROR(i2c_new_master_bus(&bus_cfg, &s_bus), TAG, "create I2C bus");

    const i2c_device_config_t dev_cfg = {
        .dev_addr_length = I2C_ADDR_BIT_LEN_7,
        .device_address = MCP23008_ADDR,
        .scl_speed_hz = 400000,
    };
    ESP_RETURN_ON_ERROR(i2c_master_bus_add_device(s_bus, &dev_cfg, &s_dev), TAG, "add MCP23008");

    /* GP0 LCD CS and GP1 LCD RESET are outputs. GP2..GP7 are inputs. */
    ESP_RETURN_ON_ERROR(write_reg(MCP23008_REG_IODIR, 0xFC), TAG, "IODIR");
    ESP_RETURN_ON_ERROR(write_reg(MCP23008_REG_GPPU, 0x1C), TAG, "GPPU");

    /* LCD deselected and held in reset until panel init starts. */
    s_olat = (1u << IOX_LCD_CS);
    ESP_RETURN_ON_ERROR(write_reg(MCP23008_REG_OLAT, s_olat), TAG, "OLAT");

    ESP_LOGI(TAG, "ready at address 0x%02X", MCP23008_ADDR);
    return ESP_OK;
}

esp_err_t mcp23008_write_gpio(uint8_t value)
{
    s_olat = value;
    return write_reg(MCP23008_REG_GPIO, s_olat);
}

esp_err_t mcp23008_set_output(unsigned bit, bool high)
{
    if (bit > 7) {
        return ESP_ERR_INVALID_ARG;
    }
    if (high) {
        s_olat |= (uint8_t)(1u << bit);
    } else {
        s_olat &= (uint8_t)~(1u << bit);
    }
    return write_reg(MCP23008_REG_OLAT, s_olat);
}

uint8_t mcp23008_output_shadow(void)
{
    return s_olat;
}
