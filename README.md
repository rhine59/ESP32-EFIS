# ESP32 Artificial Horizon

An experimental aircraft artificial-horizon / attitude-indicator project based on an ESP32-S3, a BMI088 IMU and a high-brightness round 480×480 IPS display.

> **Safety status:** This project is experimental and is not a certified or approved primary flight instrument. It must not be relied upon as the sole source of attitude information in flight. Any aircraft installation must comply with the applicable airworthiness, electrical, structural and operational requirements.

## Current hardware baseline

- **Processor:** ESP32-S3 N8R8 class board (8 MB PSRAM preferred)
- **IMU:** Bosch BMI088, using SPI
- **Display:** 2.1-inch round 480×480 high-brightness IPS display, ST7701S class, RGB pixel interface with SPI configuration
- **Controls:** rotary encoder with push switch
- **Power:** regulated **5 V input via USB-C**
- **Instrument format:** standard **3 1/8-inch aircraft instrument** style enclosure
- **Enclosure:** planned 3D-printable front bezel, main body, IMU carrier and removable rear cover

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
  │
  │ SPI: gyro + accelerometer
  ▼
ESP32-S3
  │
  ├── calibration
  ├── quaternion AHRS/filter
  ├── validity monitoring
  ├── pitch / roll
  │
  └── RGB display engine
        │
        ▼
2.1-inch 480×480 high-nit round IPS
```

## Power arrangement

The prototype will be powered from a clean, regulated **5 V USB-C supply**. Aircraft 12 V conversion is intentionally outside the instrument at this stage. This keeps the first prototype simple and avoids mixing display/AHRS development with aircraft transient-protection design.

The final enclosure should provide enough rear or lower-rear clearance for a USB-C plug and include mechanical strain relief so vibration is not transferred directly into the ESP32 USB connector.

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
│   └── SAFETY.md
├── firmware/
├── hardware/
│   └── schematics/
└── enclosure/
    ├── source/
    └── stl/
```

## Development phases

### Phase 1 — Bench prototype

- ESP32-S3
- BMI088 breakout
- 2.1-inch 480×480 high-brightness round display
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

- 3 1/8-inch front bezel
- rigid BMI088 mounting plane
- display carrier
- ESP32 mounting points
- USB-C cable access and strain relief
- rotary encoder mounting
- removable rear cover
- STL and parametric source files

### Phase 4 — Flight-development prototype

Only after extensive bench and motion testing. The device remains an experimental secondary display unless independently demonstrated and approved for another use.

## Important design principles

### The IMU must be rigidly mounted

The BMI088 board should be mounted on a stiff, repeatable reference plane. Its axes must be known relative to the aircraft longitudinal, lateral and vertical axes. Soft foam mounting is not appropriate for the primary attitude sensor because it can introduce sensor motion relative to the airframe.

### Do not blindly trust accelerometer tilt

An accelerometer measures specific force, not gravity alone. During aircraft acceleration, turning and turbulence, the apparent gravity vector can be misleading. The AHRS must therefore use the gyroscopes for short-term attitude propagation and apply accelerometer correction carefully and slowly when the measured acceleration is consistent with gravity.

### Fail visibly

If sensor data is stale, communications fail, values become implausible, or the attitude solution loses confidence, the display must show an unmistakable invalid indication instead of continuing to show a plausible but stale horizon.

Example:

```text
ATTITUDE
 INVALID
```

## Status

The hardware architecture is selected. The next tasks are to freeze the exact BMI088 breakout and high-brightness ST7701S display module, define GPIO assignments and wiring, then begin the first ESP32-S3 firmware and enclosure geometry.
