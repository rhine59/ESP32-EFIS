# Bill of Materials

This BOM records the current reference hardware for the ESP32 artificial-horizon prototype.

| Item | Reference choice | Qty | Notes |
|---|---|---:|---|
| MCU board | **Espressif ESP32-S3-DevKitC-1-N8R8** | 1 | 8 MB flash, 8 MB PSRAM |
| IMU | **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** | 1 | Official BMI088 evaluation board; project uses SPI |
| Display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 2.1-inch round, 480×480, IPS, 1000 nit, ST7701S, non-touch |
| Display prototype adapter | **Newhaven NHD-FFC40** | 1 | 40-pin 0.5 mm FFC to dual-row 2.54 mm through-hole; 52 × 40 mm; prototype/development adapter |
| Final display connector | **Molex 54104-4096** or compatible | 1 | 40-position, 0.5 mm pitch FFC/FPC connector for future compact carrier PCB |
| Backlight driver | **Adafruit TPS61169 Constant Current Boost Converter (PID 6354)** | 1 | 5 V input; configure for the panel's ~100 mA LED current; PWM dimming |
| Control | Rotary encoder with push switch | 1 | Exact model TBD |
| Power lead | USB-C cable | 1 | Instrument input is regulated 5 V through USB-C |
| 5 V supply | Regulated 5 V source | 1 | External to instrument |
| Wiring | Jumper/prototype wiring | as needed | Bench only |
| Fasteners | M2/M2.5 hardware and threaded inserts | as needed | Enclosure mounting |
| Enclosure | 3D-printed nominal 3 1/8-inch instrument case | 1 | ASA/ABS or suitable engineering filament preferred |

## Display connection decision

For the first bench prototype use the **Newhaven NHD-FFC40** rather than soldering directly to a 0.5 mm FFC connector. It converts the display's 40-pin fine-pitch flex connection to a dual-row 20 × 2 through-hole pattern on 2.54 mm pitch. The adapter is approximately 52 × 40 mm and has four mounting holes.

The NHD-FFC40 is a development aid, not necessarily the final enclosure solution. The compact flight-development carrier should use the manufacturer-recommended **Molex 54104-4096** or an electrically/mechanically compatible 40-pin 0.5 mm connector on a dedicated PCB.

## Display electrical facts

The Newhaven panel exposes RGB mode signals directly on its 40-pin FFC: VS, HS, PCLK, DE, six blue bits, six green bits, six red bits, RESETX and ST7701S serial configuration signals. Its LED pins are LED_K and LED_A. The manufacturer specifies approximately 6 V / 100 mA for the 1000-nit backlight.

## Still to freeze

- exact rotary encoder model and shaft dimensions
- final GPIO assignment after checking all ESP32-S3 strapping/reserved pins and RGB peripheral constraints
- final compact carrier PCB layout
- rear USB-C strain-relief arrangement
- enclosure mounting-hole geometry from the actual aircraft panel

## Future optional items

- GNSS receiver for aided attitude development
- independent watchdog/power supervisor
- ambient-light sensor for automatic dimming
- external temperature sensor for enclosure/thermal testing
- dedicated compact carrier PCB after prototype validation
