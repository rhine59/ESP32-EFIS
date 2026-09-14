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

The exact ESP32-S3 development-board part number is still to be frozen after the display GPIO requirement is mapped in detail.

## IMU — reference part frozen

The reference IMU board is now the **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088**.

Reasons for choosing it:

- it uses the genuine Bosch BMI088
- it is official Bosch evaluation hardware
- Bosch publishes mechanical and electrical documentation
- both SPI and I²C are available
- it is compact enough to fit easily inside the instrument body

Project interface: **SPI**.

Approximate shuttle-board dimensions are **22 mm × 14 mm**, with **1.27 mm-pitch** interconnects. The 1.27 mm pitch is smaller than normal breadboard spacing, so the prototype will use a carrier/adapter rather than unsupported flying wires.

The BMI088 exposes accelerometer and gyroscope functions as separate devices. The firmware will provide separate chip-select control and explicitly perform the BMI088 accelerometer SPI-mode initialisation sequence after power-up.

The sensor board must be mounted rigidly and its axis orientation documented. Firmware will contain an explicit sensor-to-aircraft axis transform rather than relying on the PCB being installed in only one physical orientation.

## Display — reference part frozen

The reference display is the **Newhaven Display NHD-2.1-480480AF-ASXP**.

Key specifications:

- 2.1-inch round IPS TFT
- 480 × 480 pixels
- **1000 nit** luminance
- ST7701S controller/driver
- no touch layer
- 18-bit parallel RGB or 1-lane MIPI DSI
- project interface: **18-bit parallel RGB**
- 40-pin, 0.5 mm-pitch FFC
- active area: **53.28 × 53.28 mm**
- outline: **58.18 × 60.71 × 2.26 mm**
- TFT supply: approximately 3.0 V
- backlight: approximately **6.0 V / 100 mA**
- operating temperature: -20 °C to +70 °C
- EMI-shielded FPC
- manufacturer-specified anti-glare construction

The 1000-nit backlight is the main reason for choosing this panel over the common 300–650 nit 2.1-inch alternatives.

## Backlight-power implication

The instrument receives **5 V through USB-C**, but the selected display backlight is specified at about **6 V / 100 mA**. Therefore the final electronics must include a small boost/constant-current LED-driver stage between the 5 V input rail and LCD backlight.

The backlight must not be connected directly to the ESP32 3.3 V rail or driven directly from a GPIO.

Brightness control will be performed through the LED-driver enable/PWM/current-control input once the exact driver is selected.

## User input

One rotary encoder with integral push switch is planned.

Likely functions:

- rotate: brightness/menu selection
- short press: acknowledge/select
- deliberate long press: zero/cage/calibration function, subject to safety design

Critical functions must not be easy to trigger accidentally in flight.

## Power

The instrument is powered from a regulated **5 V supply via USB-C**.

The 12 V aircraft electrical system, conversion, surge suppression and reverse-polarity protection are outside the enclosure during this development phase.

The 5 V supply must have enough current capacity for:

- ESP32-S3 processor and PSRAM
- LCD logic
- backlight boost converter and 1000-nit LED load
- BMI088 and other low-power peripherals

A conservative power budget will be established once the ESP32 board and backlight driver are chosen.

The enclosure must provide cable clearance and strain relief so the USB-C receptacle on the ESP32 board does not carry vibration or cable load.

## Enclosure

Target format is a **3 1/8-inch aircraft instrument-style housing**.

Planned printed parts:

1. front bezel/display carrier
2. main cylindrical/recessed body
3. rigid BMI088 shuttle-board carrier/alignment plate
4. removable rear cover

The display carrier will be designed around the Newhaven outline of 58.18 × 60.71 mm and its 40-pin FFC exit. The BMI088 carrier will be designed around the Bosch 22 × 14 mm shuttle-board envelope and must preserve a defined aircraft-axis reference.

PLA is not preferred for a sun-heated cockpit. ASA, ABS or another suitable engineering filament should be evaluated.

## Thermal considerations

The 1000-nit LCD backlight may be a significant heat source. The final enclosure should be tested at elevated ambient temperature and under direct solar loading. Ventilation may be required, but must not compromise structural integrity or introduce excessive glare/light leakage.

## Mechanical design principle

Electronics that affect attitude measurement must not move relative to the airframe. Display cosmetic alignment and IMU reference alignment are different requirements; the latter is the more important one.
