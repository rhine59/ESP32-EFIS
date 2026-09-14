# ESP32 Artificial Horizon

An experimental **supplementary/non-primary** aircraft artificial-horizon / attitude-indicator project based on an ESP32-S3, Bosch BMI088 IMU and a high-brightness round 480×480 IPS display.

> **Safety status:** This project is experimental and is not a certified or approved primary flight instrument. It must not be relied upon as the sole source of attitude information in flight. Any aircraft installation must comply with the applicable airworthiness, electrical, structural and operational requirements.

## Current hardware baseline

- **Processor:** Espressif **ESP32-S3-WROOM-1-N16R2** — 16 MB Quad flash, 2 MB Quad PSRAM
- **Processor carrier:** project-specific **68 mm custom PCB** on 60 mm mounting PCD
- **3.3 V regulator:** **TI TPS62162-Q1**, fixed 3.3 V / 1 A synchronous buck
- **USB:** native ESP32-S3 USB-C on GPIO19/20
- **IMU:** Bosch **SHUTTLE BOARD 3.0 BMI088**, SPI
- **Display:** Newhaven **NHD-2.1-480480AF-ASXP**, 2.1-inch round 480×480, 1000 nit, ST7701S
- **Pixel interface:** 16-bit RGB565 plus timing; 9-bit serial initialization
- **Backlight driver:** Adafruit **TPS61169**, PID 6354
- **Low-speed GPIO expansion:** Microchip **MCP23008**
- **Control:** Bourns **PEC09-class** incremental rotary encoder with push switch
- **Power:** regulated **5 V input via USB-C**
- **Instrument format:** conventional **3 1/8-inch aircraft instrument** panel format
- **Front window:** 2.0 mm hard-coated anti-reflective optical polycarbonate, 62.0 mm prototype diameter

The earlier ESP32-S3 DevKit remains useful for bench work if already available, but it is no longer part of the final mechanical/electrical architecture.

## Firmware status

The repository now contains a real **ESP-IDF v5.4.2 project** in `firmware/`.

The current proof-of-life firmware:

1. configures the BMI088 chip-select lines to a safe inactive state
2. initializes the MCP23008 over I²C
3. hardware-resets the Newhaven LCD through the MCP23008
4. runs the Newhaven-derived ST7701S 3-wire initialization sequence
5. selects the ST7701S 16-bit RGB pixel format
6. creates the ESP32-S3 native RGB LCD peripheral at 480×480 / RGB565
7. allocates two full framebuffers in PSRAM
8. draws a static artificial-horizon test pattern
9. enables the backlight only after a complete image exists

The build is checked automatically by `.github/workflows/build-firmware.yml` using Espressif's official ESP-IDF CI action.

See `firmware/README.md` for build, flash and bring-up instructions.

## Display timing correction

The current Newhaven datasheet gives the following recommended **RGB** timing baseline:

- PCLK: **30 MHz**
- HFP/HBP: **50 / 50**
- HS pulse: **4**
- VFP/VBP: **50 / 50**
- VS pulse: **2**

The earlier 18 MHz timing values in the project came from Newhaven's MIPI timing table and are no longer used as the RGB firmware baseline.

## Why N16R2

The `ESP32-S3-WROOM-1-N16R2` was selected because:

- 16 MB flash leaves generous firmware/assets/update headroom
- 2 MB Quad PSRAM is sufficient for double 480×480 RGB565 framebuffers
- Quad PSRAM preserves GPIO35–37
- Octal-PSRAM variants would consume GPIO33–37 and break the current pin map
- the bare module is substantially smaller than a DevKit
- native USB and all project connectors can be placed exactly for the instrument geometry

Two RGB565 framebuffers require about **921,600 bytes**, leaving useful PSRAM headroom.

## Electrical architecture

```text
5 V USB-C
   |
   +--> TPS62162-Q1 --> +3V3_SYS
   |                       |
   |                       +--> ESP32-S3-WROOM-1-N16R2
   |                       +--> Newhaven LCD logic
   |                       +--> BMI088
   |                       +--> MCP23008
   |
   +--> TPS61169 --> LCD backlight

ESP32-S3
   +--> RGB565 + timing --> Newhaven display
   +--> shared SPI -------> ST7701S init + BMI088
   +--> I2C -------------> MCP23008 --> encoder/LCD control
   +--> PWM -------------> TPS61169
```

## Custom carrier PCB

The custom carrier architecture and mechanical envelope are defined, but **detailed KiCad PCB work is currently parked** while firmware development proceeds.

Board target:

- 68 mm diameter
- 1.6 mm FR-4 starting thickness
- four 2.7 mm mounting holes on 60 mm PCD
- ESP32 antenna at 12 o'clock with explicit RF keepout/cutout
- USB-C at 6 o'clock aligned to rear service slot
- board mounts directly to rear-cover standoffs

Authoritative PCB design references remain in `hardware/` so the KiCad work can resume without redesigning the architecture.

## Project goals

The firmware will:

1. sample the BMI088 gyroscope and accelerometer at high rate
2. calibrate sensor offset, scale and alignment
3. run a quaternion-based AHRS/filter on the ESP32-S3
4. derive pitch and roll from the attitude solution
5. render the horizon, bank scale, pitch ladder, aircraft symbol and warning states smoothly
6. detect stale, implausible or failed sensor data and clearly flag the attitude as invalid rather than freezing the last valid display

## Enclosure

The flight-development enclosure includes:

- 80.30 mm reference panel opening
- 79.60 mm cylindrical locating body
- 88 × 88 mm rounded-square front flange
- four panel mounting holes on a 62.9 × 62.9 mm square pattern
- 58 mm body depth
- 62.0 mm × 2.0 mm hard-coated AR front window
- removable front bezel
- rotary-encoder control pod
- removable display carrier
- rigid BMI088 cradle
- direct 68 mm PCB mounting on rear standoffs
- removable rear cover
- USB-C service opening and cable-jacket strain relief
- rear M5 brass-insert mounting provisions

See `docs/ENCLOSURE.md` for mechanical detail.

## Repository layout

```text
.
├── README.md
├── BOM.md
├── docs/
├── firmware/
│   ├── CMakeLists.txt
│   ├── sdkconfig.defaults
│   ├── include/pins.h
│   └── main/
├── hardware/
└── enclosure/
```

## Important design principles

### The IMU must be rigidly mounted

The BMI088 board is carried on a stiff, repeatable reference plane. Its axes must be known relative to aircraft longitudinal, lateral and vertical axes.

### Do not blindly trust accelerometer tilt

An accelerometer measures specific force, not gravity alone. During acceleration, turning and turbulence, the apparent gravity vector can be misleading. Gyroscopes therefore provide short-term attitude propagation while accelerometer correction is applied only with appropriate confidence weighting.

### Fail visibly

If sensor data is stale, communications fail, values become implausible, or the attitude solution loses confidence, the display must show an unmistakable invalid indication instead of a plausible frozen horizon.

```text
ATTITUDE
 INVALID
```

## Current next step

The active development path is now **firmware**. Once the display proof-of-life build is compiling and running on the real hardware, the next stage is the BMI088 SPI driver, 200 Hz acquisition, stationary gyro calibration and first live quaternion pitch/roll solution.

The detailed KiCad carrier PCB task is deliberately parked and can be resumed later from the existing design files.
