# Hardware Design

## Processor

The baseline processor is an **ESP32-S3 N8R8-class board**, with 8 MB PSRAM preferred. PSRAM is useful for one or more 480×480 display buffers, sprites and anti-aliased graphics.

The ESP32-S3 will handle:

- BMI088 acquisition over SPI
- calibration and alignment correction
- AHRS/filter execution
- validity monitoring
- horizon graphics
- rotary encoder input
- display brightness control

## IMU

The initial sensor is the **Bosch BMI088**, chosen as a practical development IMU with separate 3-axis accelerometer and 3-axis gyroscope and good vibration-oriented characteristics.

The sensor board must be mounted rigidly and its axis orientation documented. The firmware should contain an explicit sensor-to-aircraft axis transform rather than relying on the breakout board being physically mounted in only one orientation.

Preferred connection: **SPI**.

## Display

Baseline display:

- 2.1-inch round IPS
- 480×480 pixels
- ST7701S-class controller
- high-brightness / high-nit variant
- non-touch preferred
- RGB pixel interface with SPI controller setup where applicable

The active display diameter is approximately 53 mm for common panels in this class, which fits well inside a 3 1/8-inch instrument bezel.

## User input

One rotary encoder with integral push switch is planned.

Likely functions:

- rotate: brightness/menu selection
- short press: acknowledge/select
- deliberate long press: zero/cage/calibration function, subject to safety design

Critical functions must not be easy to trigger accidentally in flight.

## Power

The prototype instrument is powered from a regulated **5 V supply via USB-C**.

The 12 V aircraft electrical system, conversion, surge suppression and reverse-polarity protection are outside the enclosure during the development phase.

The enclosure must provide cable clearance and strain relief so the USB-C receptacle on the ESP32 board does not carry vibration or cable load.

## Enclosure

Target format is a **3 1/8-inch aircraft instrument-style housing**.

Planned printed parts:

1. front bezel/display carrier
2. main cylindrical/recessed body
3. rigid IMU carrier/alignment plate
4. removable rear cover

The IMU carrier is intentionally separate so its orientation and stiffness can be controlled independently of the display mounting.

PLA is not preferred for a sun-heated cockpit. ASA, ABS or another suitable engineering filament should be evaluated.

## Thermal considerations

The high-brightness LCD backlight may be a significant heat source. The final enclosure should be tested at elevated ambient temperature and in direct solar loading. Ventilation slots may be required, but must not compromise structural integrity or introduce excessive glare/light leakage.

## Mechanical design principle

Electronics that affect attitude measurement should not be allowed to move relative to the airframe. Display cosmetic alignment and IMU reference alignment are different requirements; the latter is the more important one.
