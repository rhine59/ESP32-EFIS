# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## One instrument at a time

QEMU acceptance is deliberately performed one instrument at a time. The **Artificial Horizon / PFD** and **Altimeter** functional/presentation passes are accepted and parked. Their accepted geometry and behaviour should remain unchanged while Compass development proceeds.

The active stage is now **Compass only**. QEMU is locked to `PANEL_COMPASS`.

## Artificial Horizon acceptance record

The accepted attitude suite covered level, ±10° and ±20° pitch, ±30° and ±60° bank, combined +10° pitch/+30° right bank, attitude failure and explicit recovery. The accepted presentation uses a dark circular inner bezel, fixed bank scale/pointer and a yellow aircraft reference fixed at display centre. Positive pitch moves the horizon down, negative pitch moves it up, and the attitude sphere moves opposite aircraft bank. `ATT FAIL` prevents a failed attitude from remaining plausibly usable.

## Altimeter acceptance record

The Altimeter presentation and QNH/pressure calculation are accepted for the current QEMU phase. The accepted presentation uses the circular EFIS bezel, 0–9 dial numerals, differentiated hundreds/thousands/ten-thousands hands, digital altitude readout, conventional rectangular Kollsman/QNH window in hectopascals and fail-obvious `ALT FAIL` state.

The accepted above-10,000-ft warning has no hatching at or below 10,000 ft, progressively reveals hatching over the next 1,000 ft and remains fully exposed thereafter. The pressure-setting window is hPa only. The discarded slice-shaped Kollsman concept is not part of the design.

The accepted functional QNH test held simulated static pressure at 927.0 hPa while changing `ui.qnh_hpa` through 1013, 1003, 1023, 950 and 1050 hPa. Lower QNH produced lower indicated altitude, higher QNH produced higher indicated altitude, and invalid pressure produced `ALT FAIL`. The reusable `baro_altitude` module therefore remains the calculation path for static pressure plus selected QNH.

Physical BMP585 acquisition, stale-data timing and rotary encoder direction/detent validation remain hardware-integration tests and are not simulated as real hardware in QEMU.

## Active Compass QEMU suite

The Compass is now the only QEMU instrument under test. The first functional suite contains twelve repeating six-second states:

1. `HDG NORTH` — 000°
2. `HDG NE` — 045°
3. `HDG EAST` — 090°
4. `HDG SE` — 135°
5. `HDG SOUTH` — 180°
6. `HDG SW` — 225°
7. `HDG WEST` — 270°
8. `HDG NW` — 315°
9. `HDG 350-010` — moving through north to verify 359° → 000° wrap
10. `HDG ROTATE` — continuous rotation to expose discontinuities or reversed card movement
11. `HEADING FAIL` — heading invalidity must be unmistakable
12. `HDG NORTH` — explicit recovery to a valid 000° indication

The initial compass renderer had graduations but no directional markings, making the fixed-heading tests impossible to judge visually. The QEMU functional harness now overlays large **N, E, S and W** labels on the rotating compass card and a central three-digit heading readout. These markings are derived from the same `heading_deg` value as the rose rotation, allowing card direction and cardinal alignment to be checked directly. This is a functional-test aid; the final Compass presentation will integrate permanent direction/heading markings into the production renderer.

The heading bug is fixed at **060°** during this initial QEMU pass. It is deliberately independent of aircraft heading, so its position relative to the rotating compass card can be checked. Physical encoder adjustment of the heading bug remains a hardware test because QEMU bypasses the MCP23008 and rotary encoder.

For a conventional rotating compass card, increasing aircraft heading should rotate the card in the opposite direction beneath the fixed lubber/reference line. At 000° the N should be under the top reference; at 090° E should be under it; at 180° S should be under it; and at 270° W should be under it. North wrap must be continuous without a full-circle jump in the wrong direction. Heading invalidity must fail visibly and must not leave a plausibly usable frozen heading.

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

## Display resolution and graphics quality

The selected Newhaven NHD-2.1-480480AF-ASXP has a native resolution of **480×480 pixels**, so QEMU deliberately uses exactly 480×480. The firmware uses RGB565. Enlarging QEMU on a desktop makes primitive graphics look coarser than at the physical panel size. After Compass functionality is accepted, a common graphics-quality pass is planned for typography, smoother primitives, line weights and bezel shading.

## Following stage

First accept Compass direction, cardinal/intercardinal geometry, north wrap, continuous rotation, heading-bug relationship and fail/recovery behaviour. Then integrate the accepted direction/heading presentation into the Compass renderer and refine its appearance without changing the heading mathematics. Hardware integration with the remote RM3100 magnetometer and encoder follows later on the physical prototype.
