# Bill of Materials

This BOM records the current reference hardware for the ESP32 artificial-horizon prototype. Parts may still change after bench and sunlight testing, but the IMU and display reference parts are now frozen for mechanical and electrical design.

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU board | ESP32-S3 N8R8-class development board | 1 | 8 MB PSRAM preferred for 480×480 frame buffers; exact DevKit board still to be frozen |
| IMU | **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** | 1 | Official Bosch BMI088 evaluation board; SPI/I²C; 22 × 14 mm PCB; 1.27 mm connector pitch |
| Display | **Newhaven Display NHD-2.1-480480AF-ASXP** | 1 | 2.1-inch round, 480×480, IPS, 1000 nit, ST7701S, no touch, 18-bit RGB or 1-lane MIPI DSI |
| Display FFC connector | 40-pin, 0.5 mm pitch FFC connector | 1 | Newhaven recommends Molex 54104-4096 or electrically/mechanically compatible part |
| Backlight driver | 5 V-input boost / constant-current LED driver | 1 | Required because selected display backlight is specified at about 6.0 V / 100 mA; exact driver TBD |
| Control | Rotary encoder with push switch | 1 | Brightness/menu/cage/acknowledge functions |
| Power lead | USB-C cable | 1 | Instrument input is regulated 5 V through USB-C |
| 5 V supply | Regulated 5 V source | 1 | External to instrument; must provide adequate current for ESP32, LCD and 1000-nit backlight |
| Wiring | Jumper leads / prototype wiring | as needed | Bench only; replace with retained connectors for aircraft evaluation |
| Fasteners | M2/M2.5 hardware and threaded inserts | as needed | For display/PCB/enclosure mounting |
| Enclosure | 3D-printed nominal 3 1/8-inch instrument case | 1 | ASA/ABS or suitable engineering filament preferred |
| Front lens | Anti-glare/anti-reflective cover, optional | 1 | Evaluate after direct-sunlight testing |

## Locked reference parts

### IMU — Bosch SHUTTLE BOARD 3.0 BMI088

- Manufacturer: Bosch Sensortec
- Sensor: BMI088 6-axis IMU
- Interface: SPI or I²C; project will use SPI
- Board outline: approximately 22 mm × 14 mm
- Connector pitch: 1.27 mm
- Separate accelerometer and gyroscope chip-select handling is required in SPI mode
- Official Bosch evaluation hardware is preferred for the first prototype to reduce uncertainty around the sensor implementation

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

## Still to be frozen

- exact ESP32-S3 N8R8 development board model
- exact 40-pin FFC connector / breakout or carrier PCB
- exact 5 V to display-backlight boost/current driver
- rotary encoder model and shaft dimensions
- rear USB-C connector/strain-relief arrangement
- enclosure mounting-hole geometry from the actual aircraft panel

## Future optional items

- GNSS receiver for aided attitude development
- independent watchdog/power supervisor
- ambient-light sensor for automatic dimming
- external temperature sensor for enclosure/thermal testing
- dedicated carrier PCB after prototype validation
