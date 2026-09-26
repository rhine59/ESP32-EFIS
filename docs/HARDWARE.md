# Hardware Design

## Processor — optimised reference choice

The reference processor is now the **Espressif ESP32-S3-WROOM-1-N16R2** module mounted on a project-specific carrier PCB.

Key reasons for this choice:

- 16 MB Quad flash
- 2 MB Quad PSRAM
- enough PSRAM for double-buffered 480×480 RGB565 graphics
- Quad rather than Octal PSRAM, preserving GPIO35–37 for the pin-heavy display/IMU design
- active module with good current distributor availability
- smaller and mechanically cleaner than designing the instrument around a development board
- native USB available directly from the ESP32-S3

The processor handles:

- BMI088 acquisition over SPI
- calibration and alignment correction
- quaternion AHRS/filter execution
- validity monitoring
- 480×480 horizon graphics
- rotary encoder input through MCP23008
- display brightness PWM

The earlier **ESP32-S3-DevKitC-1-N8R2** remains useful for bench firmware development if already available, but is no longer the reference final hardware because that exact DevKit variant is obsolete at major distributors.

### Why not an 8 MB Octal-PSRAM ESP32-S3

The display requires 16 RGB data signals plus timing and sensor/control interfaces. Espressif documents GPIO35–37 as part of the Octal memory interface on Octal-PSRAM configurations. Losing those three pins makes the current design significantly harder.

For this project, **2 MB Quad PSRAM is a better system-level choice than 8 MB Octal PSRAM** because GPIO availability is more valuable than the extra memory.

Two RGB565 frame buffers require:

`480 × 480 × 2 bytes × 2 buffers = 921,600 bytes`

That fits comfortably inside 2 MB PSRAM.

## Custom processor carrier

The final PCB should carry the N16R2 module directly and provide:

- regulated 5 V instrument input via USB-C
- 3.3 V regulator sized for ESP32-S3 transient current plus peripherals
- local bulk and high-frequency decoupling
- native USB D-/D+ routing to GPIO19/GPIO20
- EN/reset network
- BOOT access on GPIO0
- test/programming pads
- RGB display connector
- shared LCD-configuration/BMI088 SPI connector
- I²C/MCP23008 connector
- TPS61169 PWM/output wiring
- deliberate grounding and short high-speed return paths

Normal flight firmware should not require Wi-Fi or Bluetooth. They should remain disabled during ordinary attitude-display operation unless deliberately enabled for a maintenance function.

## IMU — reference part frozen

The reference IMU board is the **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** using SPI.

Approximate board dimensions are 22 × 14 mm with a 1.27 mm-pitch connector. The accelerometer and gyroscope are separate logical SPI devices with separate chip selects. Firmware must explicitly perform the accelerometer's documented SPI-mode transition after reset.

The sensor is rigidly mounted and its axes are explicitly mapped to aircraft longitudinal, lateral and vertical axes. Soft foam suspension is not used as the primary structural mounting method.

## Display — reference part frozen

The reference display is the **Newhaven NHD-2.1-480480AF-ASXP**:

- 2.1-inch round IPS TFT
- 480 × 480 pixels
- 1000 nit typical luminance
- ST7701S controller/driver
- no touch layer
- project pixel interface: **16-bit RGB565 parallel RGB**
- ST7701S configuration: 9-bit serial/SPI-style initialization
- 40-pin 0.5 mm FFC
- active area 53.28 × 53.28 mm
- outline 58.18 × 60.71 × 2.26 mm
- TFT supply approximately 3.0–3.3 V
- backlight approximately 6.0 V / 100 mA
- operating temperature -20 °C to +70 °C

RGB565 is chosen instead of the panel's full 18-bit mode to save two direct ESP32 GPIOs.

## Backlight

The prototype uses the **Adafruit TPS61169 constant-current boost converter, PID 6354**, configured for approximately 100 mA maximum LED current. Brightness is controlled by ESP32 PWM.

The backlight is not powered from an ESP32 GPIO or from the ESP32's 3.3 V regulator output.

## Low-speed GPIO

The **Microchip MCP23008** handles low-speed functions including:

- LCD configuration chip select
- LCD hardware reset
- rotary encoder A
- rotary encoder B
- rotary encoder push switch

Its interrupt output is connected directly to the ESP32.

## User input

The reference control family is **Bourns PEC09**, using an incremental rotary encoder with push switch. Exact shaft length/knob suffix remains to be physically frozen.

Likely functions:

- rotate: brightness/menu selection
- short press: acknowledge/select
- deliberate long press: cage/calibration action subject to final safety logic

## Power

Development power is a regulated **5 V input via USB-C**. Aircraft 12 V conversion, surge suppression and reverse-polarity protection remain outside the enclosure during this phase.

The custom carrier will regulate 5 V down to 3.3 V for the ESP32-S3 and logic. The 5 V rail also supplies the dedicated backlight boost/current driver.

## Enclosure integration

The 3 1/8-inch enclosure now provides:

1. optical-window/front-bezel assembly
2. Newhaven display carrier
3. rigid BMI088 carrier
4. rear-service electronics carrier
5. rotary encoder control pod
6. USB-C cable strain relief
7. removable rear cover

The existing electronics carrier was deliberately designed with edge-location rails so it can be revised for the final custom N16R2 PCB without redesigning the main enclosure.

## Thermal and mechanical considerations

The 1000-nit LCD backlight is likely to dominate heat generation. The complete assembly must be tested at elevated ambient temperature and under representative solar loading.

Electronics that affect attitude measurement must not move relative to the airframe. IMU reference alignment is more important than cosmetic display alignment.

## Boot control, diagnostic testability and production networking

The PEC09 rotary/push control is the normal physical controller for the boot menu and maintenance dialogs: rotate to move selection and short-press to enter/confirm. The boot menu offers **START EFIS**, **FULL TEST** and **FIRMWARE UPDATE**, with START EFIS selected by default.

Production hardware should be designed for the bootable electrical test harness: preserve labelled rail/test points and, where practical, permit safe identity, rail and protected-interface diagnostics. Display/backlight testing still requires visual confirmation. External aircraft-connected interfaces must never be driven into an unsafe state by test mode.

Wi-Fi credentials are persistent in ESP-IDF NVS. Production configuration requires NVS encryption for stored credentials. Wi-Fi remains maintenance-only and is explicitly entered from the firmware-update path; it is not silently enabled during normal flight presentation.
