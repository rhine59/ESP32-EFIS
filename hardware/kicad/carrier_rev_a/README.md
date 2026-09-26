# Carrier PCB Revision A

KiCad 8-compatible project for the ESP32 Artificial Horizon custom carrier.

- 68 mm circular 4-layer PCB
- ESP32-S3-WROOM-1-N16R2
- TPS62162-Q1 3.3 V buck
- MCP23008 control expander
- USB-C 2.0 device/power input
- direct 40-pin Newhaven FFC
- BMI088, encoder and TPS61169 interfaces
- 60 mm mounting-hole PCD

This is a prototype hardware revision for bench validation. It is not flight-qualified hardware.

## Testability and production follow-on

Revision A remains a bench PCB, but bring-up should preserve access needed by the bootable electrical test harness: power rails, reset/boot, display/backlight controls, MCP23008/encoder and sensor interfaces. The later production carrier adds protected nominal 12 V aircraft power conversion, encrypted-NVS-capable firmware configuration, GNSS and protected external DATA/EXPANSION interfaces. Do not expose raw ESP32 GPIO as aircraft-voltage-tolerant connections.
