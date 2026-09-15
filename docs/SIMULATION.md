# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## One instrument at a time

QEMU acceptance is deliberately performed one instrument at a time. The **Artificial Horizon / PFD functional and presentation pass is accepted and parked**. Its tested pitch/bank geometry and revised round-EFIS bezel remain unchanged while the project moves on.

The active stage is **Altimeter only**. QEMU is locked to `PANEL_ALTIMETER`. Compass testing remains parked until Altimeter acceptance is complete.

## Artificial Horizon acceptance record

The accepted attitude suite covered level, ±10° and ±20° pitch, ±30° and ±60° bank, combined +10° pitch/+30° right bank, attitude failure and explicit recovery. The accepted presentation uses a dark circular inner bezel, fixed bank scale/pointer and a yellow aircraft reference fixed at display centre. Positive pitch moves the horizon down, negative pitch moves it up, and the attitude sphere moves opposite aircraft bank. `ATT FAIL` prevents a failed attitude from remaining plausibly usable.

## Active Altimeter QEMU suite

The Altimeter pointer mathematics has passed the initial visual functional check. The current presentation uses the circular EFIS bezel, 0–9 dial numerals, differentiated hundreds/thousands/ten-thousands hands, digital altitude readout and fail-obvious `ALT FAIL` state.

The suite is now expanded to fourteen six-second states:

1. `ALT 0`
2. `ALT 500`
3. `ALT 1000`
4. `ALT 2500`
5. `ALT 5000`
6. `ALT 9500`
7. `ALT 9900`
8. `ALT 10000`
9. `ALT 10100`
10. `ALT 10500`
11. `ALT 12500`
12. `ALT SWEEP`
13. `ALT FAIL`
14. `RECOVERY ALT`

The fixed-altitude scenarios set the underlying `altitude_ft` value rather than manipulating pointer geometry, so all hands and warning indications are derived from the same altitude source.

### Above-10,000-ft hatching

The approved Altimeter presentation includes a striped/hatching warning field associated with flight above 10,000 ft. It is driven by calculated altitude rather than decorative artwork. At and below 10,000 ft no hatching is shown. Above 10,000 ft the hatching is progressively exposed over the next 1,000 ft and remains fully exposed thereafter. Dedicated 9,900, 10,000, 10,100, 10,500 and 12,500 ft QEMU states verify the threshold and progressive reveal.

### Kollsman pressure-setting window

The pressure-setting window is a **Kollsman window in hectopascals (hPa)**. The UI displays the selected QNH numerically with an explicit `HPA` unit. The project does not use inches of mercury for this instrument. When settings mode is active the Kollsman/QNH window is highlighted to identify the active encoder-controlled setting.

The displayed QNH is not itself an altitude simulation control. The next functional stage is to exercise QNH through the pressure-to-altitude calculation path, using simulated pressure plus selected QNH and verifying that changing QNH changes indicated altitude correctly. The final encoder path will use the persisted `qnh_hpa` UI setting.

### Pointer acceptance

The hundreds pointer completes one revolution per 1,000 ft. The thousands pointer completes one revolution per 10,000 ft. The ten-thousands pointer completes one revolution per 100,000 ft. Particular attention remains on 500, 1,000, 9,500 and 10,000 ft because these expose half-scale and carry/wrap relationships.

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

## Display resolution and graphics quality

The selected Newhaven NHD-2.1-480480AF-ASXP has a native resolution of **480×480 pixels**, so QEMU deliberately uses exactly 480×480. The firmware uses RGB565. Enlarging QEMU on a desktop makes primitive graphics look coarser than at the physical 2.1-inch panel size. After Horizon, Altimeter and Compass functionality is accepted, a common graphics-quality pass is planned for typography, smoother primitives, line weights and bezel shading.

## Following stage

After the above-10,000-ft warning presentation is accepted, the next Altimeter test is the **QNH/pressure calculation and encoder interaction**. Once that passes, freeze the Altimeter geometry and switch QEMU to a Compass-only acceptance sequence.
