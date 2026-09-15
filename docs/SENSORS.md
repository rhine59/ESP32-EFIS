# Pressure and heading sensor architecture

This project is a supplementary/non-primary flight instrument. Sensor validity, freshness and installation effects must be explicit; missing data must never be replaced by plausible stale data.

## Pressure sensor — frozen choice

**Bosch Sensortec BMP585** is the reference static-pressure sensor for the Altimeter/PFD.

Why BMP585 rather than BMP581/BMP390/DPS310:
- 300–1250 hPa full-accuracy range
- ±6 Pa typical relative accuracy and 0.08 Pa RMS pressure noise
- ±0.5 Pa/K typical temperature coefficient
- gel-filled cavity / enhanced resistance to water, dust and harsh environments
- I2C/I3C/SPI and 3.3 V-compatible supplies
- active component with strong UK stock
- same modern BMP58x family while giving this aircraft installation useful environmental robustness

Its maximum absolute accuracy is specified at ±50 Pa in Bosch's current data, so QNH/reference-pressure setting remains essential as with any barometric altimeter.

### Prototype module

Use **Adafruit BMP585 Ported I2C/SPI breakout, PID 6413** for bench and first flight-development plumbing. It provides a practical ported module and is available through DigiKey. This is preferable to inventing a pressure chamber around an unported bench breakout.

For a later custom carrier, decide after pressure tests whether to retain a separately mounted ported BMP585 module or integrate the bare BMP585 with a purpose-designed sealed plenum. Do not freeze the bare-sensor pneumatic geometry until the ported prototype has been characterized.

### Static plumbing

The enclosure provides a reinforced STATIC service boss with a 3 mm pilot hole. Enlarge it only for the final bulkhead/tube fitting after the Skyranger static tubing has been measured. Support tubing independently, leak-test it, avoid kinks/excessive volume, and prevent cabin pressure leaking into the static line.

Firmware applies pilot-selected QNH to measured static pressure. Startup, range, rate-of-change, temperature and stale-data checks must pass before `altitude_valid` becomes true.

## Magnetometer — frozen choice

**PNI RM3100-CB (P/N 14754)** is the reference absolute magnetic-field source.

Reasons: three-axis magneto-inductive architecture; ±1100 µT range; 13 nT sensitivity / ~15 nT noise at the documented high-resolution setting; I2C/SPI; -40 to +85 °C; compact 14.22 × 15.75 × 7.14 mm board; documented rugged/vibration performance; UK supply through Solsta.

The RM3100-CB is remote-mounted away from the ESP32, DC/DC converter, backlight current, steel fasteners and other panel magnetic disturbances. It needs a rigid non-magnetic mount with known FWD/UP/lateral axes and a locking strain-relieved cable through the rear MAG service boss.

## Heading fusion

The compass does not use raw magnetometer azimuth alone. Heading is produced from calibrated 3-axis magnetic field plus BMI088 attitude, including tilt compensation, hard-iron offset, soft-iron matrix and installation alignment. Magnetic/true reference and variation handling must be explicit. GNSS course over ground is **TRK**, not HDG.

## Bench development

Until sensors arrive, `CONFIG_AH_BENCH_SIMULATION=y` supplies clearly synthetic values. Simulation must be disabled for aircraft-use firmware.
