# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## One instrument at a time

QEMU acceptance is deliberately performed one instrument at a time. The **Artificial Horizon / PFD functional and presentation pass is now accepted and parked**. Its tested pitch/bank geometry and revised round-EFIS bezel should remain unchanged while the project moves to the next instrument. A later common graphics-quality pass may improve fonts, anti-aliasing, line quality and shading without changing the accepted attitude geometry.

The next development stage is **Altimeter only**. QEMU should be locked to `PANEL_ALTIMETER` while altitude behaviour is developed and accepted. Compass testing remains parked until the Altimeter stage is complete.

## Artificial Horizon acceptance record

The accepted attitude sequence contains twelve six-second states:

1. `LEVEL` — 0° pitch, 0° bank; aircraft reference centred on the horizon.
2. `PITCH +10` — +10° pitch.
3. `PITCH -10` — -10° pitch.
4. `PITCH +20` — +20° pitch edge case.
5. `PITCH -20` — -20° pitch edge case.
6. `BANK LEFT 30` — -30° roll.
7. `BANK RIGHT 30` — +30° roll.
8. `BANK LEFT 60` — -60° roll edge case.
9. `BANK RIGHT 60` — +60° roll edge case.
10. `PITCH +10 BANK R30` — combined +10° pitch and +30° right bank.
11. `ATTITUDE FAIL` — attitude invalid while altitude and heading remain valid.
12. `RECOVERY LEVEL` — explicit valid level state immediately after failure.

The accepted presentation uses a dark circular inner bezel, contrasting inner lip, fixed bank scale at 10°, 20°, 30°, 45° and 60°, fixed triangular bank pointer and a yellow aircraft reference fixed at the display centre. Positive pitch moves the horizon down, negative pitch moves it up, and the attitude sphere moves opposite aircraft bank. Pitch ladder and horizon rotate together. The failure presentation uses a conspicuous `ATT FAIL` indication rather than leaving a plausible frozen attitude usable.

## Altimeter development stage

The Altimeter will use the same development method that proved effective for attitude: one instrument on screen, deterministic test values, on-screen test number/name/countdown, permanent red `SIM` annunciation, explicit failure state and explicit recovery state.

The initial Altimeter acceptance sequence is planned to include:

1. `ALT 0` — zero-foot datum.
2. `ALT 500` — low-altitude half-thousand indication.
3. `ALT 1000` — first thousand crossing.
4. `ALT 2500` — normal intermediate indication.
5. `ALT 5000` — mid-scale reference.
6. `ALT 9500` — approach to 10,000 ft.
7. `ALT 10000` — 10,000 ft crossing and pointer relationship.
8. `ALT SWEEP` — deterministic changing altitude to verify continuous pointer motion and wrap/carry behaviour.
9. `ALT FAIL` — altitude invalid and no plausible frozen altitude left usable.
10. `RECOVERY ALT` — fresh valid altitude immediately after failure.

Before this sequence is accepted, the current development altimeter artwork should be replaced with a proper aircraft-instrument presentation: clear circular bezel, strong major/minor tick hierarchy, large readable numerals and unmistakable hundreds/thousands indication. The exact visual design will be reviewed in QEMU before being frozen.

### QNH testing

QNH is a separate functional test from the basic display sequence. The adjustable pressure setting must be exercised through the rotary control and persisted UI setting. Changing QNH must affect indicated altitude in the expected direction and magnitude once the BMP585 pressure-to-altitude model is connected. QNH tests must not be simulated merely by directly changing the displayed altitude value; they must exercise the pressure/QNH calculation path.

Altitude invalidity and stale pressure data must fail visibly. The firmware must never substitute synthetic altitude or retain a plausible frozen value in an aircraft-use build.

## Build and run scripts

From the repository root:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
zsh scripts/build-qemu.sh
zsh scripts/run-qemu.sh
```

For a clean emulator rebuild use:

```bash
zsh scripts/build-qemu.sh --clean
zsh scripts/run-qemu.sh
```

QEMU uses the real 480×480 RGB565 geometry but bypasses physical LCD, MCP23008, encoder, backlight and sensors. `sdkconfig.qemu.defaults` disables physical PSRAM emulation while the normal hardware build retains the ESP32-S3-WROOM-1-N16R2 PSRAM configuration. Never flash `build-qemu` to hardware.

Physical bench simulation leaves hardware I/O active and substitutes explicitly synthetic instrument data. It is separate from QEMU and must never be enabled for aircraft use.

## Display resolution and graphics quality

The selected Newhaven NHD-2.1-480480AF-ASXP has a native resolution of **480×480 pixels**, so the QEMU framebuffer deliberately uses exactly 480×480. There is no higher native pixel mode available from the selected panel. The firmware uses RGB565, which is appropriate for the ESP32-S3 RGB display path and this EFIS presentation.

QEMU is primarily a geometry and functional-development environment. Enlarging its 480×480 window on a desktop can make primitive graphics appear coarser than they will at the physical 2.1-inch display size. After Horizon, Altimeter and Compass functionality is accepted, a common graphics-quality pass is planned to improve typography, line/circle smoothness, anti-aliasing or pre-rendered graphics where practical, line weights and bezel shading without changing accepted instrument behaviour.

## Following stage

After Altimeter presentation, altitude/failure/recovery behaviour and QNH interaction are accepted, freeze the Altimeter geometry and switch QEMU to a Compass-only acceptance sequence. A final common graphics-quality pass follows functional acceptance of all three instruments.
