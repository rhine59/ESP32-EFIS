# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## One instrument at a time

QEMU acceptance is deliberately performed one instrument at a time. The **Artificial Horizon / PFD functional and presentation pass is accepted and parked**. Its tested pitch/bank geometry and revised round-EFIS bezel remain unchanged while the project moves on. A later common graphics-quality pass may improve fonts, anti-aliasing, line quality and shading without changing accepted attitude geometry.

The active stage is now **Altimeter only**. QEMU is locked to `PANEL_ALTIMETER`; Compass testing remains parked until the Altimeter stage is complete.

## Artificial Horizon acceptance record

The accepted attitude suite covered level, ±10° and ±20° pitch, ±30° and ±60° bank, combined +10° pitch/+30° right bank, attitude failure and explicit recovery. The accepted presentation uses a dark circular inner bezel, fixed bank scale/pointer and a yellow aircraft reference fixed at display centre. Positive pitch moves the horizon down, negative pitch moves it up, and the attitude sphere moves opposite aircraft bank. `ATT FAIL` prevents a failed attitude from remaining plausibly usable.

## Active Altimeter QEMU suite

The firmware contains a deterministic ten-state Altimeter sequence. Each state lasts six seconds and repeats continuously:

1. `ALT 0`
2. `ALT 500`
3. `ALT 1000`
4. `ALT 2500`
5. `ALT 5000`
6. `ALT 9500`
7. `ALT 10000`
8. `ALT SWEEP` — deterministic changing altitude.
9. `ALT FAIL` — altitude validity false.
10. `RECOVERY ALT` — explicit fresh 2,500 ft valid state after failure.

The fixed-altitude scenarios set the underlying `altitude_ft` value rather than manipulating pointer geometry. The hundreds pointer completes one revolution per 1,000 ft, thousands pointer one per 10,000 ft and ten-thousands pointer one per 100,000 ft. The initial functional pointer test has been accepted, including the important 500, 1,000, 9,500 and 10,000 ft relationships.

## Altimeter presentation under review

The Altimeter has now received its dedicated presentation pass while retaining the already-tested pointer mathematics. The display uses the same round-instrument visual family as the accepted Horizon: dark circular bezel, bright inner lip, black face and high-contrast white markings.

The dial has 50 graduations around the circumference with stronger major marks and large 0–9 cardinal altitude numerals. The three hands are deliberately differentiated by length and thickness: the long thin hand represents hundreds of feet, the medium hand thousands and the short heavy hand ten-thousands. A central digital altitude window provides an additional unambiguous numerical cross-check while this supplementary instrument is being developed.

A dedicated QNH window now shows the current `qnh_hpa` UI value and highlights its border/label when settings mode is active. The current QEMU altitude suite displays a `TEST MODE - ALT` banner rather than the previous attitude-specific banner. The permanent red `SIM` annunciation remains present for all synthetic data.

`ALT FAIL` now replaces the central usable altitude presentation with a prominent red failure annunciation/cross rather than allowing a plausible frozen altitude to remain readable. Recovery must restore fresh valid altitude.

### QNH testing — next functional step

QNH remains separate from the basic altitude-display suite. The adjustable pressure setting must be exercised through the rotary control and persisted UI setting. Changing QNH must affect indicated altitude through the BMP585 pressure/QNH calculation path; it must not be faked by directly changing the displayed altitude value. This is the next functional stage after the redesigned Altimeter presentation is visually accepted.

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

After the redesigned Altimeter presentation is accepted, test QNH/encoder behaviour through the pressure-to-altitude path. Then freeze the Altimeter geometry and switch QEMU to a Compass-only acceptance sequence.
