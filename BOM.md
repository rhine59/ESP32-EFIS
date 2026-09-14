# Bill of Materials

This BOM records the current reference hardware for the ESP32 artificial-horizon prototype. Parts may still change after bench and sunlight testing, but the principal electronics are now frozen for the first prototype.

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU board | **Espressif ESP32-S3-DevKitC-1-N8R8** | 1 | Official Espressif board; ESP32-S3-WROOM-1-N8R8, 8 MB flash, 8 MB PSRAM, 3.3 V logic |
| IMU | **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** | 1 | Official Bosch BMI088 evaluation board; project uses SPI; 22 × 14 mm PCB; 1.27 mm connector pitch |
| Display | **Newhaven Display NHD-2.1-480480AF-ASXP** | 1 | 2.1-inch round, 480×480, IPS, 1000 nit, ST7701S, no touch, 18-bit RGB or 1-lane MIPI DSI |
| Display FFC connector | 40-pin, 0.5 mm pitch FFC connector | 1 | Newhaven recommends Molex 54104-4096 or electrically/mechanically compatible part |
| Backlight driver | **Adafruit TPS61169 Constant Current Boost Converter, PID 6354** | 1 | 3–5 V input, PWM dimming, selectable LED current; configure for 100 mA for the Newhaven backlight |
| Control | Rotary encoder with push switch | 1 | Brightness/menu/cage/acknowledge functions |
| Power lead | USB-C cable | 1 | Instrument input is regulated 5 V through USB-C |
| 5 V supply | Regulated 5 V source | 1 | External to instrument; must provide adequate current for ESP32, LCD and 1000-nit backlight |
| Wiring | Jumper leads / prototype wiring | as needed | Bench only; replace with retained connectors for aircraft evaluation |
| Fasteners | M2/M2.5 hardware and threaded inserts | as needed | For display/PCB/enclosure mounting |
| Enclosure | 3D-printed nominal 3 1/8-inch instrument case | 1 | ASA/ABS or suitable engineering filament preferred |
| Front lens | Anti-glare/anti-reflective cover, optional | 1 | Evaluate after direct-sunlight testing |

## Locked reference parts

### MCU — Espressif ESP32-S3-DevKitC-1-N8R8

- Manufacturer: Espressif Systems
- Ordering code: `ESP32-S3-DevKitC-1-N8R8`
- Module: `ESP32-S3-WROOM-1-N8R8`
- Flash: 8 MB
- PSRAM: 8 MB Octal SPI
- Logic: 3.3 V
- Dual-core ESP32-S3, up to 240 MHz
- Most GPIOs are exposed on headers, making it suitable for the first wired prototype

The project should use the official Espressif board rather than an unspecified clone so the GPIO map and mechanical dimensions remain reproducible.

### IMU — Bosch SHUTTLE BOARD 3.0 BMI088

- Manufacturer: Bosch Sensortec
- Sensor: BMI088 6-axis IMU
- Interface: SPI or I²C; project will use SPI
- Board outline: approximately 22 mm × 14 mm
- Connector pitch: 1.27 mm
- Separate accelerometer and gyroscope chip-select handling is required in SPI mode

The 1.27 mm connector pitch is not standard breadboard spacing. The prototype will therefore need either an adapter/carrier PCB or suitable 1.27 mm socket/header wiring.

### Display — Newhaven NHD-2.1-480480AF-ASXP

- 2.1-inch round IPS TFT
- 480 × 480 pixels
- 1000 cd/m² (1000 nit)
- ST7701S controller/driver
- no touch layer
- active area: 53.28 × 53.28 mm
- overall outline: 58.18 × 60.71 × 2.26 mm
- 40-pin 0.5 mm pitch FFC
- interface: 18-bit parallel RGB or 1-lane MIPI DSI
- TFT supply: approximately 3.0 V
- backlight requirement: approximately 6.0 V / 100 mA
- operating temperature: -20 °C to +70 °C
- EMI-shielded FPC
- anti-glare optical treatment stated by the manufacturer

The project will use the **18-bit parallel RGB interface** with the ESP32-S3 rather than MIPI DSI.

### Backlight driver — Adafruit TPS61169 breakout, PID 6354

- Texas Instruments TPS61169 constant-current boost LED driver
- Adafruit breakout product ID: 6354
- input: 3–5 V, compatible with the project 5 V USB-C rail
- constant-current boost output suitable for an LED backlight string
- PWM brightness input available for ESP32 control
- current is selected by onboard DIP switches
- configure the prototype for **100 mA maximum backlight current**
- board dimensions: approximately 25.2 × 19.0 × 10.1 mm

The driver should be powered from the 5 V rail, while the PWM/dimming input is driven from an ESP32 GPIO. The LCD backlight must not be powered from the ESP32 3.3 V rail.

## Still to be frozen

- exact 40-pin FFC connector / breakout or carrier PCB
- rotary encoder model and shaft dimensions
- rear USB-C connector/strain-relief arrangement
- enclosure mounting-hole geometry from the actual aircraft panel
- final GPIO allocation after the FFC/carrier wiring is defined

## Future optional items

- GNSS receiver for aided attitude development
- independent watchdog/power supervisor
- ambient-light sensor for automatic dimming
- external temperature sensor for enclosure/thermal testing
- dedicated carrier PCB after prototype validation
