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
- **Backlight driver:** Adafruit **TPS61169**, PID 6354, plug-in Revision-A module
- **Low-speed GPIO expansion:** Microchip **MCP23008**, SMD on custom carrier
- **Control:** Bourns **PEC09-class** incremental rotary encoder with push switch
- **Power:** regulated **5 V input via USB-C**
- **Instrument format:** conventional **3 1/8-inch aircraft instrument** panel format
- **Front window:** 2.0 mm hard-coated anti-reflective optical polycarbonate, 62.0 mm prototype diameter

The earlier ESP32-S3 DevKit remains useful for bench work if already available, but it is no longer part of the final mechanical/electrical architecture.

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

Revision A is now electrically and mechanically defined.

Board target:

- **68 mm diameter**
- **1.6 mm FR-4** starting thickness
- **four 2.7 mm mounting holes on 60 mm PCD**
- four-layer stack preferred
- ESP32 antenna at 12 o'clock with explicit RF keepout/cutout
- USB-C at 6 o'clock aligned to rear service slot
- board mounts directly to rear-cover standoffs

The former printed DevKit electronics carrier has been retired.

Authoritative PCB design files:

- `hardware/schematics/CARRIER_PCB_SCHEMATIC.md`
- `hardware/schematics/carrier-netlist.csv`
- `hardware/pcb/README.md`

The enclosure CAD also generates a printable:

`enclosure/stl/ESP32_Artificial_Horizon_Custom_PCB_Fit_Gauge.stl`

That gauge should be printed and fitted before ordering PCBs.

## Project goals

The firmware will:

1. Sample the BMI088 gyroscope and accelerometer at high rate.
2. Calibrate sensor offset, scale and alignment.
3. Run a quaternion-based AHRS/filter on the ESP32-S3.
4. Derive pitch and roll from the attitude solution.
5. Render the horizon, bank scale, pitch ladder, aircraft symbol and warning states smoothly.
6. Detect stale, implausible or failed sensor data and clearly flag the attitude as invalid rather than freezing the last valid display.

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
├── firmware/
│   └── include/pins.h
├── hardware/
│   ├── pcb/README.md
│   └── schematics/
│       ├── CARRIER_PCB_SCHEMATIC.md
│       └── carrier-netlist.csv
└── enclosure/
    ├── images/
    ├── source/
    └── stl/
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

## Status

The processor choice, custom carrier schematic architecture, net map, PCB mechanical envelope and enclosure interface are now defined.

The next major development task is to build the **actual KiCad Revision-A schematic/PCB project**, run ERC/DRC, produce fabrication outputs, and in parallel start the first ESP-IDF display firmware for a static artificial-horizon test screen.
