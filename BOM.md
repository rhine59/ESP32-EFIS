# Bill of Materials

This BOM is the current project baseline and will be refined when exact breakout/module part numbers are frozen.

| Item | Current choice | Qty | Notes |
|---|---|---:|---|
| MCU board | ESP32-S3 N8R8 class development board | 1 | 8 MB PSRAM preferred for display buffering |
| IMU | Bosch BMI088 breakout | 1 | Must support SPI and expose gyro/accelerometer interfaces clearly |
| Display | 2.1-inch round 480×480 high-brightness IPS, ST7701S class | 1 | Prefer high-nit/sunlight-readable version, non-touch |
| Control | Rotary encoder with push switch | 1 | Brightness/menu/cage/acknowledge functions |
| Power lead | USB-C cable | 1 | Use a short, mechanically restrained cable in aircraft installation |
| 5 V supply | Regulated 5 V source | 1 | External to instrument during prototype stage |
| Wiring | Dupont/jumper leads for bench build | as needed | Replace with secure connectors in flight prototype |
| Prototype board | Breadboard/perfboard as needed | 1 | Bench development only |
| Fasteners | M2/M2.5 hardware and threaded inserts | as needed | For display/PCB/enclosure mounting |
| Enclosure | 3D printed 3 1/8-inch instrument case | 1 | ASA/ABS or suitable engineering filament preferred |
| Front lens | Anti-glare/anti-reflective cover, optional | 1 | To be evaluated after sunlight testing |

## Not yet purchased / finalised

- Exact BMI088 breakout board
- Exact 1000-nit-class display module
- Exact ESP32-S3 development board variant
- Encoder model and shaft dimensions
- Rear USB-C connector/strain-relief arrangement
- Enclosure inserts, screws and material

## Future optional items

- GNSS receiver for future aided attitude development
- Independent watchdog/power supervisor
- Ambient-light sensor for automatic dimming
- External temperature sensor for enclosure/thermal testing
- Dedicated PCB after prototype validation
