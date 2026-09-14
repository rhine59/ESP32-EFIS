#pragma once

// ESP32 Artificial Horizon - prototype pin allocation
// Target module: ESP32-S3-WROOM-1-N16R2 on custom carrier PCB
// Supplementary/non-primary flight-development instrument.

// RGB565 display data bus: D0..D15
#define PIN_LCD_D0   4   // panel B1
#define PIN_LCD_D1   5   // panel B2
#define PIN_LCD_D2   6   // panel B3
#define PIN_LCD_D3   7   // panel B4
#define PIN_LCD_D4   8   // panel B5
#define PIN_LCD_D5   9   // panel G0
#define PIN_LCD_D6   10  // panel G1
#define PIN_LCD_D7   11  // panel G2
#define PIN_LCD_D8   12  // panel G3
#define PIN_LCD_D9   13  // panel G4
#define PIN_LCD_D10  14  // panel G5
#define PIN_LCD_D11  15  // panel R1
#define PIN_LCD_D12  16  // panel R2
#define PIN_LCD_D13  17  // panel R3
#define PIN_LCD_D14  18  // panel R4
#define PIN_LCD_D15  21  // panel R5

// RGB timing
#define PIN_LCD_PCLK   1
#define PIN_LCD_DE     2
#define PIN_LCD_HSYNC 38
#define PIN_LCD_VSYNC 39

// Shared configuration/sensor SPI
#define PIN_SPI_MOSI 35
#define PIN_SPI_SCLK 36
#define PIN_SPI_MISO 37

#define PIN_BMI088_ACC_CS  40
#define PIN_BMI088_GYRO_CS 41

// High-brightness backlight PWM
#define PIN_LCD_BACKLIGHT_PWM 42

// MCP23008 I2C bus and interrupt
#define PIN_IOX_SDA 47
#define PIN_IOX_SCL 48
#define PIN_IOX_INT 43
#define MCP23008_ADDR 0x20

// MCP23008 GPIO allocation
#define IOX_LCD_CS      0
#define IOX_LCD_RESET   1
#define IOX_ENCODER_A   2
#define IOX_ENCODER_B   3
#define IOX_ENCODER_SW  4

// Keep GPIO44 unused initially for diagnostics/debug expansion.
#define PIN_SPARE 44

// Native USB on the custom carrier PCB.
#define PIN_USB_DM 19
#define PIN_USB_DP 20

// Deliberately reserved strapping pins:
// GPIO0 = BOOT; GPIO3/GPIO45/GPIO46 have no operational loads.
