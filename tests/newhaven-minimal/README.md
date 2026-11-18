# Newhaven 2.1-inch minimal display test
Isolated ESP-IDF application. No MCP23008 or BMI088 required. TPS61169 LED driver now supported on GPIO42 PWM (10kHz, 50% initial brightness).
**No physical flash has been performed.** Do not overwrite the RedOne factory/recovery partitions.
ESP32 GPIO40 -> LCD CSX pin34; GPIO41 -> RESETX pin33; GPIO35 -> SDA pin37; GPIO36 -> SCL pin35.
GPIO1 -> PCLK pin13; GPIO2 -> DE pin14; GPIO38 -> HSYNC pin12; GPIO39 -> VSYNC pin11.
GPIO4..8 -> B1..B5 pins16..20; GPIO9..14 -> G0..G5 pins21..26;
GPIO15..18,21 -> R1..R5 pins28..32.
Display VDD pin3 -> regulated 3.3V; GND pins4,7,10; B0 pin15 and R0 pin27 -> GND.
IM0 pin38 GND, IM1 pin39 3.3V, IM2 pin40 GND.
Backlight: TPS61169 L+ -> LCD pin2 LED_A; LED- -> LCD pin1 LED_K; Vin -> regulated 5V; G -> common GND; PWM -> ESP32 GPIO42. Do not tie LCD LED_K directly to ground: it must return to the driver LED- terminal. Verify the driver DIP switches: default 25mA + switch 1 (25mA) + switch 2 (50mA) = 100mA; switches 3 and 4 OFF. Never enable the driver without the display LED load connected.
RGB 16-bit mapping: B0 and R0 tied low, B1..B5 from GPIO4..8; G0..G5 from GPIO9..14; R1..R5 from GPIO15..18 and GPIO21. Serial interface RGB+9bit SPI: IM0=0 IM1=1 IM2=0; DCX pin36 is unused in 9-bit mode (do not drive it). Verify LCD pins5,6,8,9 and FFC connector contact orientation from Newhaven datasheet before applying power.
Build: source ~/.espressif/v5.4.4/esp-idf/export.sh; idf.py set-target esp32s3; idf.py build
Serial logs prove firmware progress, NOT successful physical display operation.

## OTA slot deployment
This project uses the SAME custom partition table as the RedOne firmware.
The built application image alone may be written to ota_1 at 0x420000 after
verifying the live device partition table and that ota_0 is backed up.
DO NOT flash the test project's bootloader or partition-table binaries.
A raw write to ota_1 does NOT change boot selection.
Use an OTA-aware boot-partition switch on the running device, not blind writes to otadata.
Once running this test in ota_1, hold BOOT (GPIO0) for 2 seconds AFTER startup
to select ota_0 and restart. The ota_0 firmware needs its own boot-slot switch
capability to return to ota_1 without a host-side operation.

## 2026-11 backlight revision
Uses Newhaven datasheet 18MHz pixel clock, HS 20/60/40, VS 6/10/10. Backlight PWM 10kHz 50% via GPIO42 after display init. **Unwired bench hardware: do not energize before checking the exact board GPIO42 pad, 3.3V rail, FFC header mapping and all connections.** Existing firmware/test not verified on physical display.
