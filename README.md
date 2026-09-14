# ESP32 Artificial Horizon

An experimental **supplementary/non-primary** aircraft artificial-horizon / attitude-indicator project based on an ESP32-S3, Bosch BMI088 IMU and a high-brightness round 480×480 IPS display.

> **Safety status:** This project is experimental and is not a certified or approved primary flight instrument. It must not be relied upon as the sole source of attitude information in flight. Any aircraft installation must comply with the applicable airworthiness, electrical, structural and operational requirements.

## Current hardware baseline

- **Processor reference:** Espressif **ESP32-S3-WROOM-1-N16R2** module — 16 MB flash, 2 MB Quad PSRAM, mounted on a project-specific carrier PCB
- **IMU:** Bosch **SHUTTLE BOARD 3.0 BMI088**, using SPI
- **Display:** Newhaven **NHD-2.1-480480AF-ASXP**, 2.1-inch round 480×480, 1000 nit, ST7701S
- **Display prototype adapter:** Newhaven **NHD-FFC40**
- **Pixel interface:** 16-bit RGB565 plus display timing signals; 9-bit serial initialization for ST7701S
- **Backlight driver:** Adafruit **TPS61169**, PID 6354, configured for approximately 100 mA maximum LED current
- **Low-speed GPIO expansion:** Microchip **MCP23008**
- **Control reference:** compact **Bourns PEC09** incremental rotary encoder with push switch
- **Power:** regulated **5 V input via USB-C**
- **Instrument format:** conventional **3 1/8-inch aircraft instrument** panel format
- **Front window:** 2.0 mm hard-coated anti-reflective optical polycarbonate, 62.0 mm prototype diameter

The earlier `ESP32-S3-DevKitC-1-N8R2` remains acceptable for bench development if already available, but the final design no longer depends on that obsolete DevKit. The active `ESP32-S3-WROOM-1-N16R2` module is preferred because its **2 MB Quad PSRAM is enough for double 480×480 RGB565 frame buffers while preserving GPIO35–37**, which Octal-PSRAM variants consume.

## Project goals

The project aims to produce a compact, smooth and sunlight-readable supplementary attitude display showing pitch and roll in the familiar blue/brown artificial-horizon format.

The firmware will:

1. Sample the BMI088 gyroscope and accelerometer at high rate.
2. Calibrate sensor offset, scale and alignment.
3. Run a quaternion-based AHRS/filter on the ESP32-S3.
4. Derive pitch and roll from the attitude solution.
5. Render the horizon, bank scale, pitch ladder, aircraft symbol and warning states at a smooth display frame rate.
6. Detect stale, implausible or failed sensor data and clearly flag the attitude as invalid rather than freezing the last valid display.

## Architecture

```text
BMI088
  |
  | SPI: gyro + accelerometer
  v
ESP32-S3-WROOM-1-N16R2
  |
  +-- calibration
  +-- quaternion AHRS/filter
  +-- validity monitoring
  +-- pitch / roll
  |
  +-- RGB565 display engine ---> Newhaven 480x480 round IPS
  |
  +-- I2C ---> MCP23008 ---> encoder + low-speed controls
  |
  +-- PWM ---> TPS61169 ---> 1000-nit LCD backlight
```

## Power arrangement

The prototype is powered from a clean, regulated **5 V USB-C supply**. Aircraft 12 V conversion is intentionally outside the instrument at this stage.

The final processor carrier will derive 3.3 V locally for the ESP32-S3 and logic, while the LCD backlight remains on its dedicated constant-current boost driver.

## Enclosure

The flight-development enclosure architecture includes:

- 80.30 mm reference panel opening
- 79.60 mm cylindrical locating body
- 88 × 88 mm rounded-square front flange
- four panel mounting holes on a 62.9 × 62.9 mm square pattern
- 58 mm body depth
- 3 mm nominal structural wall
- 62.0 mm × 2.0 mm hard-coated AR front window
- removable front retaining bezel
- front-side compact rotary-encoder control pod
- removable Newhaven display carrier
- rigid, axis-defined BMI088 cradle
- rear-service electronics carrier
- TPS61169 and MCP23008/prototype mounting zones
- harness tie points
- removable rear cover
- USB-C service opening
- separate cable-jacket strain-relief clamp
- rear M5 brass-insert mounting provisions

The electronics carrier will be revised around the final **custom N16R2 carrier PCB outline** once the PCB dimensions and connector positions are frozen.

![Flight-development enclosure](enclosure/images/flight-development-case-preview.svg)

See **[docs/ENCLOSURE.md](docs/ENCLOSURE.md)** for exact geometry, assembly order, printing guidance and verification requirements.

## Enclosure CAD sources

```text
enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad
enclosure/source/ESP32_Artificial_Horizon_Electronics_and_Controls.scad
```

GitHub Actions regenerates the printable STL set automatically.

## Repository layout

```text
.
├── README.md
├── BOM.md
├── docs/
│   ├── HARDWARE.md
│   ├── DISPLAY.md
│   ├── AHRS.md
│   ├── WIRING.md
│   ├── CALIBRATION.md
│   ├── TESTING.md
│   ├── SAFETY.md
│   ├── PARTS_SELECTION.md
│   └── ENCLOSURE.md
├── firmware/
│   ├── README.md
│   └── include/
│       └── pins.h
├── hardware/
│   └── schematics/
└── enclosure/
    ├── images/
    ├── source/
    └── stl/
```

## Development phases

### Phase 1 — Bench prototype

- ESP32-S3 development hardware or custom N16R2 carrier
- Bosch BMI088 Shuttle Board 3.0
- Newhaven 2.1-inch 480×480 1000-nit display
- NHD-FFC40 prototype adapter
- TPS61169 backlight driver
- MCP23008 low-speed GPIO expander
- PEC09-class rotary encoder
- 5 V USB-C power

### Phase 2 — AHRS development

- gyro and accelerometer calibration
- sensor-axis alignment
- quaternion attitude propagation
- gravity-based long-term correction
- acceleration rejection / confidence weighting
- invalid-attitude detection

### Phase 3 — Mechanical prototype

The major enclosure architecture is represented in CAD. Remaining mechanical work is primarily physical-fit validation and tuning around the actual parts and final custom processor carrier PCB.

### Phase 4 — Flight-development prototype

Only after extensive bench, motion, thermal and vibration testing. The device remains a supplementary experimental display unless independently demonstrated and approved for another use.

## Important design principles

### The IMU must be rigidly mounted

The BMI088 board is carried on a stiff, repeatable reference plane. Its axes must be known relative to the aircraft longitudinal, lateral and vertical axes.

### Do not blindly trust accelerometer tilt

An accelerometer measures specific force, not gravity alone. During aircraft acceleration, turning and turbulence, the apparent gravity vector can be misleading. The AHRS therefore uses gyroscopes for short-term attitude propagation and applies accelerometer correction carefully when measured acceleration is consistent with gravity.

### Fail visibly

If sensor data is stale, communications fail, values become implausible, or the attitude solution loses confidence, the display must show an unmistakable invalid indication instead of continuing to show a plausible but stale horizon.

```text
ATTITUDE
 INVALID
```

## Status

The hardware architecture is now optimised around the **active ESP32-S3-WROOM-1-N16R2 module** rather than an obsolete DevKit. The next major development step is the **first real ESP-IDF firmware build**, followed by the custom processor-carrier schematic/PCB and physical-fit update to the electronics carrier.
