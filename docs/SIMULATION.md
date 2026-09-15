# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## Instrument acceptance status

The **Artificial Horizon / PFD graphics pass and Altimeter graphics pass are accepted and parked**. The Compass functional pass remains accepted; the active 480×480 graphics-quality stage is now the **Compass**.

Graphics work must preserve the accepted indication direction, mathematics and failure behaviour.

## Artificial Horizon acceptance record

The accepted attitude suite covers level, ±10° and ±20° pitch, ±30° and ±60° bank, combined +10° pitch/+30° right bank, attitude failure and explicit recovery. Positive pitch moves the horizon down, negative pitch moves it up, and the attitude sphere moves opposite aircraft bank. `ATT FAIL` prevents a failed attitude from remaining plausibly usable.

The accepted graphics keep `PITCH_PIXELS_PER_DEG` at **6.8 px/degree**, use a regularised horizon line, differentiated 5°/10° pitch marks with centre gaps, and a fixed yellow aircraft symbol with black contrast outline. The centre datum remains at exact display centre.

The accepted fixed bank-angle scale marks **10°, 20°, 30°, 45° and 60° on both sides** plus zero. The 30° and 60° marks are stronger. A white triangular roll pointer with black contrast outline moves with measured roll: left bank moves left/counter-clockwise and right bank moves right/clockwise. The bank scale is presentation only and does not alter roll mathematics.

The native Swift simulator mirrors this accepted Horizon presentation. QEMU remains authoritative for pixel-level ESP32 rendering.

## Altimeter acceptance record

The Altimeter presentation and QNH/pressure calculation are accepted. The accepted presentation uses the circular EFIS bezel, 0–9 dial numerals, differentiated hundreds/thousands/ten-thousands hands, digital altitude readout, compact mechanical-style Kollsman pressure scale at 3 o'clock, the 9 o'clock >10,000-ft hatching sector and fail-obvious `ALT FAIL` state.

The accepted Kollsman display replaces the former lower rectangular QNH box. It is a curved circumferential sector centred at **3 o'clock**, spanning approximately **8 hPa total** at 2° per hPa. The selected QNH is aligned with a fixed 3-o'clock index while the pressure graduations move around it. Pressure numbers and hatch marks are maintained at constant radii from the instrument centre and the window contains no `QNH`, `HPA` or `KOLLSMAN` text. The exact **1013.25 hPa** standard-pressure datum is represented by a substantially heavier radial tick. This datum is a presentation reference only: selected QNH remains 950–1050 hPa in integer 1 hPa increments and the accepted pressure/altitude mathematics are unchanged.

The accepted above-10,000-ft logic has no hatching at or below 10,000 ft, progressively reveals hatching over the next 1,000 ft and remains fully exposed thereafter. The hatching is an **annular sector centred at the 9 o'clock position**. The sector occupies a 60° arc on the left side of the dial and sits inside the numeral ring. At or below 10,000 ft it is absent; from 10,000 to 11,000 ft the sector progressively grows through its 60° arc; at and above 11,000 ft the full sector remains visible. This is a presentation change only: the accepted 10,000/11,000-ft thresholds are unchanged.

The accepted functional QNH test held simulated static pressure at 927.0 hPa while changing `ui.qnh_hpa` through 1013, 1003, 1023, 950 and 1050 hPa. Lower QNH produced lower indicated altitude, higher QNH produced higher indicated altitude, and invalid pressure produced `ALT FAIL`. The reusable `baro_altitude` module therefore remains the calculation path for static pressure plus selected QNH.

The Altimeter graphics suite used fourteen six-second states: **0, 500, 1,000, 2,500, 5,000, 9,500, 9,900, 10,000, 10,100, 10,500 and 12,500 ft**, a moving altitude sweep, `ALT FAIL`, and explicit recovery to 2,500 ft. The final compact Kollsman geometry was visually accepted in QEMU.

The native Swift simulator mirrors both the accepted 9 o'clock altitude-hatching sector and the compact 3 o'clock Kollsman presentation. QEMU remains authoritative for the RGB565 implementation.

Physical BMP585 acquisition, stale-data timing and rotary encoder direction/detent validation remain hardware-integration tests and are not simulated as real hardware in QEMU.

## Compass acceptance record

The Compass QEMU functional pass is accepted. The functional suite used twelve repeating six-second states: 000°, 045°, 090°, 135°, 180°, 225°, 270°, 315°, a moving 350°→010° north crossing, continuous rotation, `HEADING FAIL`, and explicit recovery to 000°.

The accepted Compass renderer carries large **N, E, S and W** labels on the rotating card and a central three-digit heading readout. These derive from the same `heading_deg` value as card rotation. For increasing aircraft heading the card rotates in the opposite direction beneath the fixed lubber/reference line. At 000° N is under the top reference; at 090° E is under it; at 180° S is under it; and at 270° W is under it. North wrap is continuous.

The accepted heading bug is a distinct outlined yellow triangular bug. It represents a selected magnetic heading and its screen position is calculated from `heading_bug_deg - heading_deg`; it is not a fixed screen pointer. The acceptance suite held the bug at 060° while aircraft heading changed. Physical encoder adjustment remains a hardware test because QEMU bypasses the MCP23008 and rotary encoder.

`HEADING FAIL` is the accepted fail-obvious state and must not be replaced by a frozen plausible heading.

### Active Compass graphics review

QEMU is now locked to `PANEL_COMPASS` for the graphics-quality pass. The review preserves the accepted heading/card direction, north wrap, selected-heading bug mathematics and fail-obvious behaviour while allowing typography, spacing, line weights, primitive quality and failure-state presentation to be refined.

The graphics suite exercises the eight cardinal/intercardinal headings, the 350°→010° north crossing, continuous rotation, `HEADING FAIL`, and recovery to north. Particular attention must be paid to the failure state: a failed heading must not leave a frozen or otherwise plausible usable compass presentation.

## Simulator synchronisation

The native Swift iPhone/iPad simulator is maintained in step with QEMU acceptance behaviour. QEMU remains authoritative for the actual ESP32 480×480 renderer; accepted visual changes should be reflected in the Swift simulator and its documentation as part of the same change.

The temporary QEMU-only Compass label/readout overlay has been retired. Compass labels and readout are supplied by the production renderer, so QEMU directly exercises production instrument graphics.

## Build and run scripts

From the repository root:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
zsh scripts/build-qemu.sh --clean
zsh scripts/run-qemu.sh
```

QEMU uses the real 480×480 RGB565 geometry but bypasses physical LCD, MCP23008, encoder, backlight and sensors. `sdkconfig.qemu.defaults` disables physical PSRAM emulation while the normal hardware build retains the ESP32-S3-WROOM-1-N16R2 PSRAM configuration. Never flash `build-qemu` to hardware.

## Display resolution and graphics-quality stage

The selected Newhaven NHD-2.1-480480AF-ASXP has a native resolution of **480×480 pixels**, so QEMU deliberately uses exactly 480×480. The firmware uses RGB565. Enlarging QEMU on a desktop makes primitive graphics look coarser than at the physical panel size.

The graphics pass may improve typography, primitive smoothness, line weights, spacing, alignment, clipping and bezel/failure presentation. It must not change accepted attitude, altitude/QNH or heading/bug mathematics.

The active graphics stage is now the Compass. After the Compass graphics pass is accepted, development moves to the real sensor pipeline: BMI088 attitude, BMP585 pressure/QNH altitude and RM3100 heading, including explicit stale/invalid-data handling before physical prototype testing.
