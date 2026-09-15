# ESP32 EFIS

Experimental **supplementary/non-primary** multifunction electronic flight instrument for a non-certified aircraft, based on ESP32-S3 and a 2.1-inch round 480×480 high-brightness display.

> **Safety:** experimental development hardware/software. It is not a certified or approved primary flight instrument and must not be relied upon as the sole source of attitude, altitude or heading information.

## Instrument pages

The EFIS has three round-instrument pages selected by the PEC09 rotary/push control:

1. **Horizon/PFD** — BMI088-based AHRS, pitch/roll, roll scale and future validated auxiliary altitude/heading fields.
2. **Altimeter** — classic three-pointer presentation using the selected ported BMP585 static-pressure sensor and adjustable QNH.
3. **Compass** — rotating-card presentation using the selected remotely mounted PNI RM3100-CB absolute-heading source, fused with the AHRS as appropriate.

No missing sensor value is replaced by a plausible fallback. Invalid or stale data must be unmistakably invalid.

## Hardware baseline

- Espressif **ESP32-S3-WROOM-1-N16R2** — 16 MB Quad flash / 2 MB Quad PSRAM
- project-specific 68 mm carrier PCB, currently parked pending the remaining physical-interface decisions
- TI **TPS62162-Q1** 3.3 V regulator
- Bosch **BMI088 Shuttle Board 3.0** IMU
- **Adafruit ported BMP585 PID 6413** pressure board for the static-pressure development installation
- **PNI RM3100-CB** remotely mounted three-axis magnetometer
- Newhaven **NHD-2.1-480480AF-ASXP** 480×480 round IPS display
- Adafruit **TPS61169** backlight driver
- Microchip **MCP23008** GPIO expansion
- Bourns **PEC09-2320F-T0015** rotary encoder/push switch
- 5 V USB-C development power

See `BOM.md`, `docs/SENSORS.md`, `docs/HARDWARE.md` and `docs/WIRING.md` for the evolving authoritative detail.

## Firmware

`firmware/` is an **ESP-IDF v5.4.4** project named `esp32_efis`. It initializes the LCD/control hardware, maintains fail-obvious data validity, persists user settings in NVS and includes an explicit synthetic bench simulator for exercising all three pages before the complete sensor system is fitted.

Bench simulation is development-only and must be disabled in aircraft-use firmware. See `docs/SIMULATION.md` and `firmware/README.md`.

## iPhone/iPad simulator

`simulator/` contains a native SwiftUI ESP32 EFIS simulator for rapid display development. It provides the three pages, manual pitch/roll/altitude/heading controls, QNH and heading-bug controls, AUTO FLIGHT and independent sensor-failure injection. Synthetic data is explicitly identified and is not a flight-data source.

See `simulator/README.md`.

## Display baseline

The Newhaven panel uses 16-bit RGB565 with 9-bit serial controller initialization. Current RGB timing is 30 MHz PCLK, HFP/HBP 50/50, HS pulse 4, VFP/VBP 50/50 and VS pulse 2. Two 480×480 RGB565 framebuffers require 921,600 bytes, fitting comfortably in the N16R2's 2 MB Quad PSRAM while retaining GPIO35–37.

## Enclosure

The 3 1/8-inch flight-development enclosure retains the 80.30 mm panel-opening reference, 79.60 mm locating body, 88 mm square front flange, 62.9 mm panel-hole square, 58 mm target body depth, removable optical-window bezel, LCD carrier, rigid BMI088 carrier, 68 mm PCB rear mount, USB-C service opening and M5 insert provisions.

The multifunction revision adds rear service provisions for the static-pressure connection and remote magnetometer cable. Final hole/connector geometry remains intentionally pending until those actual fittings are frozen. See `docs/ENCLOSURE.md`.

## Repository layout

```text
.
├── README.md
├── BOM.md
├── docs/
│   └── user-guides/
├── firmware/
├── simulator/
├── hardware/
└── enclosure/
```

## Development principles

The BMI088 is rigidly mounted with known aircraft-axis alignment. Gyros provide short-term attitude propagation while acceleration-sensitive corrections are confidence weighted. Pressure, heading and attitude sources have independent validity/freshness handling. GNSS track, if later introduced, is labelled **TRK**, not heading; groundspeed is **GS**, never IAS.

The active path is firmware + simulator + sensor integration. Detailed carrier-PCB work remains parked until the pressure and remote-magnetometer physical interfaces are mature enough to freeze connector placement.
