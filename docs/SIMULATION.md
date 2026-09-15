# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## One instrument at a time

QEMU acceptance is deliberately performed one instrument at a time. The **Artificial Horizon / PFD functional and presentation pass is accepted and parked**. The Altimeter presentation is also accepted, including its circular EFIS presentation, above-10,000-ft warning hatching and conventional rectangular Kollsman pressure-setting window in hPa. The earlier experimental idea of a slice-shaped Kollsman window is explicitly discarded.

The active stage is now **Altimeter QNH/pressure calculation**. Compass testing remains parked until this passes.

## Artificial Horizon acceptance record

The accepted attitude suite covered level, ±10° and ±20° pitch, ±30° and ±60° bank, combined +10° pitch/+30° right bank, attitude failure and explicit recovery. The accepted presentation uses a dark circular inner bezel, fixed bank scale/pointer and a yellow aircraft reference fixed at display centre. Positive pitch moves the horizon down, negative pitch moves it up, and the attitude sphere moves opposite aircraft bank. `ATT FAIL` prevents a failed attitude from remaining plausibly usable.

## Altimeter presentation acceptance

The Altimeter pointer mathematics and presentation have passed the visual functional check. The accepted presentation uses the circular EFIS bezel, 0–9 dial numerals, differentiated hundreds/thousands/ten-thousands hands, digital altitude readout, conventional rectangular Kollsman/QNH window in hectopascals and fail-obvious `ALT FAIL` state.

The hundreds pointer completes one revolution per 1,000 ft. The thousands pointer completes one revolution per 10,000 ft. The ten-thousands pointer completes one revolution per 100,000 ft.

### Above-10,000-ft hatching

The accepted Altimeter includes a striped/hatching warning field driven by calculated altitude. At and below 10,000 ft no hatching is shown. Above 10,000 ft the hatching is progressively exposed over the next 1,000 ft and remains fully exposed thereafter. The previous acceptance suite checked 9,900, 10,000, 10,100, 10,500 and 12,500 ft specifically around this transition.

### Kollsman pressure-setting window

The pressure-setting window is a **Kollsman window in hectopascals (hPa)**. It displays selected QNH numerically with an explicit `HPA` unit. The project does not use inches of mercury for this instrument. When settings mode is active the window is highlighted to identify the encoder-controlled setting. The window remains a conventional rectangular pressure-setting window; no slice-shaped treatment is planned.

## Active QNH / pressure calculation test

A reusable `baro_altitude` module now converts static pressure plus selected QNH to indicated altitude using the ISA tropospheric barometric relation. It validates pressure and QNH before returning an altitude so invalid inputs fail rather than silently producing a plausible indication.

The current QEMU suite holds simulated static pressure at **927.0 hPa** while changing the actual `ui.qnh_hpa` value used by the calculation. This proves that the altitude indication is derived through the pressure/QNH calculation path rather than by directly changing the displayed altitude.

The six repeating states are:

1. `QNH 1013` — 927.0 hPa static pressure, QNH 1013 hPa
2. `QNH 1003` — same static pressure, lower QNH; indicated altitude must decrease
3. `QNH 1023` — same static pressure, higher QNH; indicated altitude must increase
4. `QNH 950` — lower supported setting limit
5. `QNH 1050` — upper supported setting limit
6. `PRESS FAIL` — invalid pressure input; the altitude must become invalid and show `ALT FAIL`

The QNH range remains **950–1050 hPa in 1 hPa increments**. `instrument_ui` already persists `qnh_hpa` in NVS and the physical rotary encoder adjusts it when Altimeter settings mode is active. QEMU bypasses the physical MCP23008/encoder hardware, so this stage verifies the calculation and UI value path; physical encoder direction, detents and persistence will be checked on the prototype hardware.

Altitude invalidity and stale pressure data must fail visibly. The firmware must never substitute synthetic altitude or retain a plausible frozen value in an aircraft-use build.

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

The selected Newhaven NHD-2.1-480480AF-ASXP has a native resolution of **480×480 pixels**, so QEMU deliberately uses exactly 480×480. The firmware uses RGB565. Enlarging QEMU on a desktop makes primitive graphics look coarser than at the physical panel size. After Horizon, Altimeter and Compass functionality is accepted, a common graphics-quality pass is planned for typography, smoother primitives, line weights and bezel shading.

## Following stage

If the QNH/pressure sequence passes, the Altimeter calculation and presentation can be frozen for the current development phase. Physical BMP585 acquisition and encoder hardware validation remain hardware-integration tasks. QEMU then switches to a **Compass-only acceptance sequence**.
