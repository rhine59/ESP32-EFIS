# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## Instrument acceptance status

The **Artificial Horizon / PFD, Altimeter and Compass functional/presentation passes are now accepted and parked**. Their accepted geometry, indication direction and failure behaviour should not be changed accidentally during subsequent work.

The next development stage is a common 480×480 graphics-quality pass. This may improve typography, primitive smoothness, line weights, alignment, clipping and bezel treatment, but it must preserve the accepted instrument mathematics and behaviour recorded below.

## Artificial Horizon acceptance record

The accepted attitude suite covered level, ±10° and ±20° pitch, ±30° and ±60° bank, combined +10° pitch/+30° right bank, attitude failure and explicit recovery. The accepted presentation uses a dark circular inner bezel, fixed bank scale/pointer and a yellow aircraft reference fixed at display centre. Positive pitch moves the horizon down, negative pitch moves it up, and the attitude sphere moves opposite aircraft bank. `ATT FAIL` prevents a failed attitude from remaining plausibly usable.

## Altimeter acceptance record

The Altimeter presentation and QNH/pressure calculation are accepted. The accepted presentation uses the circular EFIS bezel, 0–9 dial numerals, differentiated hundreds/thousands/ten-thousands hands, digital altitude readout, conventional rectangular Kollsman/QNH window in hectopascals and fail-obvious `ALT FAIL` state.

The accepted above-10,000-ft warning has no hatching at or below 10,000 ft, progressively reveals hatching over the next 1,000 ft and remains fully exposed thereafter. The pressure-setting window is hPa only. The discarded slice-shaped Kollsman concept is not part of the design.

The accepted functional QNH test held simulated static pressure at 927.0 hPa while changing `ui.qnh_hpa` through 1013, 1003, 1023, 950 and 1050 hPa. Lower QNH produced lower indicated altitude, higher QNH produced higher indicated altitude, and invalid pressure produced `ALT FAIL`. The reusable `baro_altitude` module therefore remains the calculation path for static pressure plus selected QNH.

Physical BMP585 acquisition, stale-data timing and rotary encoder direction/detent validation remain hardware-integration tests and are not simulated as real hardware in QEMU.

## Compass acceptance record

The Compass QEMU pass is accepted. The functional suite used twelve repeating six-second states: 000°, 045°, 090°, 135°, 180°, 225°, 270°, 315°, a moving 350°→010° north crossing, continuous rotation, `HEADING FAIL`, and explicit recovery to 000°.

The accepted Compass renderer carries large **N, E, S and W** labels on the rotating card and a central three-digit heading readout. These derive from the same `heading_deg` value as card rotation. For increasing aircraft heading the card rotates in the opposite direction beneath the fixed lubber/reference line. At 000° N is under the top reference; at 090° E is under it; at 180° S is under it; and at 270° W is under it. North wrap is continuous.

The accepted heading bug is a distinct outlined yellow triangular bug. It represents a selected magnetic heading and its screen position is calculated from `heading_bug_deg - heading_deg`; it is not a fixed screen pointer. The acceptance suite held the bug at 060° while aircraft heading changed. Physical encoder adjustment remains a hardware test because QEMU bypasses the MCP23008 and rotary encoder.

`HEADING FAIL` is the accepted fail-obvious state and must not be replaced by a frozen plausible heading.

## Simulator synchronisation

The native Swift iPhone/iPad simulator is maintained in step with the QEMU acceptance behaviour. QEMU remains authoritative for the actual ESP32 480×480 renderer; changes to an accepted instrument should be reflected in the Swift simulator and its documentation as part of the same change.

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

The next stage is a common graphics-quality pass across all three accepted instruments. The goals are improved typography, smoother circles/diagonals where practical, consistent line weights and spacing, cleaner alignment, reliable circular-display clipping and consistent bezel/failure presentation. This is a presentation pass: accepted attitude, altitude/QNH and heading/bug mathematics must remain unchanged.

After graphics acceptance, development moves to the real sensor pipeline: BMI088 attitude, BMP585 pressure/QNH altitude and RM3100 heading, including explicit stale/invalid-data handling before physical prototype testing.
