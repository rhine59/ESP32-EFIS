# Pressure and heading sensor architecture

This project is a supplementary/non-primary flight instrument. Sensor validity, freshness and installation effects must be checked explicitly; missing data must never be replaced by plausible-looking stale data.

## Pressure sensor — frozen choice

**Bosch Sensortec BMP581** is the reference static-pressure sensor for the altimeter/PFD.

Why:
- 300–1250 hPa full-accuracy range
- typical absolute accuracy about ±0.3 hPa and relative accuracy ±0.06 hPa in Bosch's stated conditions
- very low pressure noise (0.08 Pa at highest resolution)
- low temperature coefficient and 12-month drift specification
- up to 480 Hz sampling
- I2C/SPI and 3.3 V-compatible supplies
- active, inexpensive component with good UK distribution

Prototype/bench module: **Adafruit BMP581 breakout, PID 6407**, because it is easy to wire and currently available through DigiKey UK. The final carrier PCB should use the bare BMP581, not the breakout.

### Static pressure plumbing

The BMP581 itself has no hose barb. The final carrier must place the sensor in a small pressure plenum/chamber connected to the aircraft static line through a sealed rear-cover fitting. The chamber must expose the sensor pressure port without adhesive, conformal coating, gasket material or debris obstructing it.

The first enclosure revision provides a reinforced rear static-service boss with a 3 mm pilot hole. The final hole is drilled/machined to the purchased fitting rather than guessing a thread/barb now. A leak test is mandatory.

Firmware will apply pilot-selected QNH to measured static pressure. Sensor startup, range, rate-of-change, temperature and stale-data checks are required before altitude_valid can become true.

## Magnetometer — frozen choice

**PNI RM3100-CB (P/N 14754)** is the reference absolute magnetic-field source.

Why:
- three-axis magneto-inductive architecture
- ±1100 µT field range
- 13 nT sensitivity / about 15 nT noise at the documented high-resolution setting
- I2C and SPI
- -40 to +85 °C operating range
- compact 14.22 × 15.75 × 7.14 mm board
- PNI specifically documents rugged/vibration performance for the CB module
- UK supply is available through Solsta

The RM3100-CB is **remote-mounted**, not installed immediately behind the display/processor. The objective is to move it away from the ESP32, DC/DC converter, high-current backlight wiring, steel fasteners and other panel magnetic disturbances.

### Remote installation

The magnetometer needs a rigid non-magnetic mount with known FWD/UP/lateral axes and a locking/strain-relieved cable. The rear enclosure has a reinforced magnetometer-service boss with a 3 mm pilot hole; enlarge it only after the final connector/gland is selected.

The remote cable should carry 3.3 V, ground and the selected digital bus. SPI is preferred if cable integrity can be demonstrated; otherwise a carefully engineered low-speed I2C link may be used only after cable-length/noise testing. Do not run the magnetometer harness alongside high-current backlight or aircraft power wiring.

## Heading fusion

The compass page must not use raw magnetometer azimuth alone. Final heading is produced from calibrated 3-axis magnetic field plus attitude from the BMI088 AHRS, including tilt compensation, hard-iron offset, soft-iron matrix and installation alignment. Magnetic/true reference and variation handling must be explicit.

GNSS course over ground, if added later, is **TRK**, not HDG.

## Bench development

Until sensors arrive, `CONFIG_AH_BENCH_SIMULATION=y` supplies clearly synthetic values for screen development. Simulation must be disabled for aircraft-use firmware.
