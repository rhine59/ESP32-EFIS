# ESP32 EFIS

Experimental **supplementary/non-primary** multifunction electronic flight instrument for a non-certified aircraft, based on ESP32-S3 and a 2.1-inch round 480×480 high-brightness display.

> **Safety:** experimental development hardware/software. It is not a certified or approved primary flight instrument and must not be relied upon as the sole source of attitude, altitude or heading information.

## Current development status

The project is being developed and accepted **one instrument at a time** using the real 480×480 geometry in Espressif QEMU before moving to physical-display integration.

**Artificial Horizon / PFD:** functional geometry and the current presentation have been accepted and are parked. QEMU testing has verified level, ±10°/±20° pitch, ±30°/±60° bank, combined pitch/bank, attitude failure and recovery. The accepted presentation has a round EFIS-style bezel, fixed bank scale/pointer and fixed central aircraft reference. Its attitude mathematics should remain unchanged during the next stage.

**Altimeter:** next active development stage. The plan is to redesign the current development artwork into a proper aircraft-style altimeter and then run a dedicated on-screen QEMU sequence at 0, 500, 1,000, 2,500, 5,000, 9,500 and 10,000 ft, followed by a deterministic sweep, altitude failure and recovery. QNH/encoder behaviour will be tested separately through the pressure-to-altitude calculation path.

**Compass:** parked until Altimeter acceptance is complete.

After all three instruments are functionally accepted, a common graphics-quality pass is planned for typography, line/circle smoothness, anti-aliasing/pre-rendering where practical, line weights and bezel shading.

## Instrument pages

The EFIS has three round-instrument pages selected by the PEC09 rotary/push control:

1. **Horizon/PFD** — BMI088-based AHRS, pitch/roll, roll scale and validated auxiliary altitude/heading fields.
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

## Firmware and development environment

`firmware/` is an **ESP-IDF v5.4.4** project named `esp32_efis`. It contains the physical display/control path, fail-obvious data validity, NVS-backed UI settings, explicit synthetic bench simulation, and an Espressif QEMU virtual-display backend.

On macOS, the standard new-shell setup is:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
```

The normal scripted QEMU workflow is:

```bash
zsh scripts/build-qemu.sh
zsh scripts/run-qemu.sh
```

For a completely clean emulator rebuild:

```bash
zsh scripts/build-qemu.sh --clean
zsh scripts/run-qemu.sh
```

For physical ESP32-S3 hardware:

```bash
source scripts/efis-env.sh
zsh scripts/build-hardware.sh
```

`scripts/efis-env.sh` pins the project to the known ESP-IDF v5.4.4 Python environment and also finds the Espressif QEMU installation when its bin directory is not exported automatically. Do not mix ESP-IDF Python environments within one build directory.

The QEMU configuration is deliberately isolated in `build-qemu` and `sdkconfig.qemu.defaults`. It enables synthetic data and the virtual 480×480 RGB565 display, and disables physical external PSRAM because the emulator does not provide the N16R2's real Quad-PSRAM device in this configuration. Physical hardware builds continue to enable the module's 2 MB PSRAM through `sdkconfig.defaults`.

Bench/QEMU simulation is development-only. Every synthetic firmware screen carries a conspicuous red **SIM** marker. Never flash a QEMU build to aircraft hardware. See `docs/SIMULATION.md`, `docs/MACOS_BUILD_AND_QEMU_SETUP.md` and `firmware/README.md`.

## iPhone/iPad simulator

`simulator/` contains a native SwiftUI ESP32 EFIS simulator for rapid display development. It provides the three pages, manual pitch/roll/altitude/heading controls, QNH and heading-bug controls, AUTO FLIGHT and independent sensor-failure injection. Synthetic data is explicitly identified and is not a flight-data source.

See `simulator/README.md`.

## Display baseline

The Newhaven panel's **native and maximum display resolution is 480×480 pixels**. QEMU deliberately uses the same 480×480 framebuffer, so instrument geometry is developed at the real pixel dimensions. The panel uses 16-bit RGB565 with 9-bit serial controller initialization. Current RGB timing is 30 MHz PCLK, HFP/HBP 50/50, HS pulse 4, VFP/VBP 50/50 and VS pulse 2. Two 480×480 RGB565 framebuffers require 921,600 bytes, fitting in the N16R2's 2 MB Quad PSRAM on physical hardware.

The desktop QEMU view is not a prediction of apparent physical sharpness when enlarged on a Mac display. The real 2.1-inch panel has a much higher apparent pixel density than an enlarged emulator window. Rendering quality can also be improved substantially within 480×480 through better typography, smoother primitives and refined artwork.

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
├── scripts/
│   ├── efis-env.sh
│   ├── build-qemu.sh
│   ├── run-qemu.sh
│   └── build-hardware.sh
├── simulator/
├── hardware/
└── enclosure/
```

## Development principles

The BMI088 is rigidly mounted with known aircraft-axis alignment. Gyros provide short-term attitude propagation while acceleration-sensitive corrections are confidence weighted. Pressure, heading and attitude sources have independent validity/freshness handling. GNSS track, if later introduced, is labelled **TRK**, not heading; groundspeed is **GS**, never IAS.

The active path is firmware + simulator + sensor integration. Detailed carrier-PCB work remains parked until the pressure and remote-magnetometer physical interfaces are mature enough to freeze connector placement.
