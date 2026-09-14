# ESP32 Artificial Horizon

An experimental aircraft artificial-horizon / attitude-indicator project based on an ESP32-S3, a BMI088 IMU and a high-brightness round 480×480 IPS display.

> **Safety status:** This project is experimental and is not a certified or approved primary flight instrument. It must not be relied upon as the sole source of attitude information in flight. Any aircraft installation must comply with the applicable airworthiness, electrical, structural and operational requirements.

## Current hardware baseline

- **Processor:** Espressif **ESP32-S3-DevKitC-1-N8R2** — 8 MB flash, 2 MB Quad PSRAM
- **IMU:** Bosch **SHUTTLE BOARD 3.0 BMI088**, using SPI
- **Display:** Newhaven **NHD-2.1-480480AF-ASXP**, 2.1-inch round 480×480, 1000 nit, ST7701S
- **Display prototype adapter:** Newhaven **NHD-FFC40**
- **Pixel interface:** 16-bit RGB565 plus display timing signals; SPI used for ST7701S configuration
- **Backlight driver:** Adafruit **TPS61169**, PID 6354, configured for approximately 100 mA maximum LED current
- **Low-speed GPIO expansion:** Microchip **MCP23008**
- **Controls:** rotary encoder with push switch, exact model still to be frozen
- **Power:** regulated **5 V input via USB-C**
- **Instrument format:** conventional **3 1/8-inch aircraft instrument** panel format
- **Enclosure:** parametric flight-development enclosure with four-hole mounting flange and removable rear cover

## Project goals

The project aims to produce a compact, smooth and sunlight-readable attitude display showing pitch and roll in the familiar blue/brown artificial-horizon format.

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
ESP32-S3
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

The prototype is powered from a clean, regulated **5 V USB-C supply**. Aircraft 12 V conversion is intentionally outside the instrument at this stage. This keeps display/AHRS development separate from aircraft transient-protection and power-conditioning design.

The display backlight is powered through the dedicated constant-current boost driver rather than from an ESP32 GPIO or its 3.3 V rail.

The enclosure provides rear cable access, but the final installation still requires positive cable strain relief so vibration and cable loads are not transferred to the ESP32 USB connector.

## Enclosure

The current flight-development enclosure now includes:

- 78.60 mm panel-locating body for a nominal 79.375 mm / 3.125-inch round cutout
- 88 × 88 mm rounded-square front flange
- four panel mounting holes on a **62.9 × 62.9 mm square pattern**
- 3.8 mm panel mounting-hole diameter for #6 hardware clearance
- 53.6 mm circular display aperture
- display-specific rectangular rear pocket
- 3 mm nominal body wall
- 58 mm body depth
- removable spigoted rear cover
- four rear-cover screw bosses
- rear USB-C/cable opening
- top orientation/index feature

![Flight-development enclosure](enclosure/images/flight-development-case-preview.svg)

See **[docs/ENCLOSURE.md](docs/ENCLOSURE.md)** for dimensions, printing guidance, mounting references, limitations and the pre-flight-development inspection checklist.

The authoritative enclosure source is:

```text
enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad
```

GitHub Actions automatically regenerates the printable STL files from that source:

```text
enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Body.stl
enclosure/stl/ESP32_Artificial_Horizon_Flight_Development_Rear_Cover.stl
```

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

- ESP32-S3-DevKitC-1-N8R2
- Bosch BMI088 shuttle board
- Newhaven 2.1-inch 480×480 1000-nit display
- Newhaven FFC adapter
- TPS61169 backlight driver
- MCP23008 low-speed GPIO expander
- rotary encoder
- 5 V USB-C power
- initial sensor drivers and horizon graphics

### Phase 2 — AHRS development

- gyro and accelerometer calibration
- sensor-axis alignment
- quaternion attitude propagation
- gravity-based long-term correction
- acceleration rejection / confidence weighting
- invalid-attitude detection

### Phase 3 — Mechanical prototype

- 3 1/8-inch four-hole front flange
- rigid BMI088 mounting plane
- display carrier
- ESP32 retention
- USB-C cable access and strain relief
- rotary encoder mounting
- removable rear cover
- STL and parametric source files

The first flight-development enclosure CAD now exists, but the internal carriers and actual aircraft-panel fit still need physical measurement and testing.

### Phase 4 — Flight-development prototype

Only after extensive bench, motion, thermal and vibration testing. The device remains an experimental secondary display unless independently demonstrated and approved for another use.

## Important design principles

### The IMU must be rigidly mounted

The BMI088 board should be mounted on a stiff, repeatable reference plane. Its axes must be known relative to the aircraft longitudinal, lateral and vertical axes. Soft foam mounting is not appropriate for the primary attitude sensor because it can introduce sensor motion relative to the airframe.

### Do not blindly trust accelerometer tilt

An accelerometer measures specific force, not gravity alone. During aircraft acceleration, turning and turbulence, the apparent gravity vector can be misleading. The AHRS must therefore use the gyroscopes for short-term attitude propagation and apply accelerometer correction carefully and slowly when measured acceleration is consistent with gravity.

### Fail visibly

If sensor data is stale, communications fail, values become implausible, or the attitude solution loses confidence, the display must show an unmistakable invalid indication instead of continuing to show a plausible but stale horizon.

Example:

```text
ATTITUDE
 INVALID
```

### Mechanical fit must be verified, not assumed

The enclosure uses conventional 3 1/8-inch dimensions as the current design basis, but the actual Skyranger panel cutout, screw centres, panel thickness and behind-panel clearance must be measured before installation.

## Status

The main hardware architecture, display, IMU, backlight driver, prototype display adapter, ESP32 variant and first GPIO map are selected. A parametric flight-development enclosure and automatic STL build process are now in the repository.

The next major work is to complete the first ESP-IDF display/sensor firmware, freeze the rotary encoder, design the rigid internal IMU/electronics carrier, then validate the complete assembly through bench, motion, thermal and vibration testing before considering any aircraft installation.
