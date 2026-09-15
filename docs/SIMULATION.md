# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## Instrument acceptance status

The **Artificial Horizon / PFD, Altimeter and Compass graphics passes are accepted and parked**. The complete 480×480 instrument graphics-quality stage is accepted. Physical hardware work is currently paused because prototype hardware is unavailable; software/QEMU/simulator work may continue without claiming physical validation.

Graphics work must preserve the accepted indication direction, mathematics and failure behaviour.

## Artificial Horizon acceptance record

The accepted attitude suite covers level, ±10° and ±20° pitch, ±30° and ±60° bank, combined +10° pitch/+30° right bank, attitude failure and explicit recovery. Positive pitch moves the horizon down, negative pitch moves it up, and the attitude sphere moves opposite aircraft bank. `ATT FAIL` prevents a failed attitude from remaining plausibly usable.

The accepted graphics keep `PITCH_PIXELS_PER_DEG` at **6.8 px/degree**, use a regularised horizon line, differentiated 5°/10° pitch marks with centre gaps, and a fixed yellow aircraft symbol with black contrast outline. The centre datum remains at exact display centre.

The accepted fixed bank-angle scale marks **10°, 20°, 30°, 45° and 60° on both sides** plus zero. The 30° and 60° marks are stronger. A white triangular roll pointer with black contrast outline moves with measured roll: left bank moves left/counter-clockwise and right bank moves right/clockwise.

## Altimeter acceptance record

The accepted presentation uses the circular EFIS bezel, 0–9 dial numerals, differentiated hundreds/thousands/ten-thousands hands, digital altitude readout, compact mechanical-style Kollsman pressure scale at 3 o'clock, the 9 o'clock >10,000-ft hatching sector and fail-obvious `ALT FAIL` state.

The Kollsman display is a curved circumferential sector centred at **3 o'clock**, spanning approximately **8 hPa total** at 2° per hPa. Selected QNH aligns with a fixed index while pressure graduations move. The exact **1013.25 hPa** datum is a heavier radial tick. Selected QNH remains 950–1050 hPa in integer 1 hPa increments.

The >10,000-ft hatching is a 60° annular sector centred at 9 o'clock. It is absent at/below 10,000 ft, progressively appears from 10,000 to 11,000 ft and remains fully visible thereafter.

The accepted functional QNH test held simulated static pressure at 927.0 hPa while changing QNH through 1013, 1003, 1023, 950 and 1050 hPa. Lower QNH produced lower indicated altitude, higher QNH higher indicated altitude, and invalid pressure produced `ALT FAIL`.

The formal Altimeter graphics suite used fourteen states: 0, 500, 1,000, 2,500, 5,000, 9,500, 9,900, 10,000, 10,100, 10,500 and 12,500 ft, moving sweep, `ALT FAIL`, and recovery.

## Compass acceptance record

The accepted Compass suite used 000°, 045°, 090°, 135°, 180°, 225°, 270°, 315°, moving 350°→010° north crossing, continuous rotation, `HEADING FAIL`, and recovery to 000°.

The renderer carries large N/E/S/W labels and a three-digit heading. Increasing aircraft heading rotates the card oppositely beneath the fixed reference. The outlined yellow selected-heading bug is calculated from `heading_bug_deg - heading_deg`; the acceptance suite held it at 060°.

`HEADING FAIL` must not be replaced by a frozen plausible heading.

## Full QEMU demonstration mode

The normal QEMU application now runs a **28-step continuous demonstration** intended both for regression viewing and video capture. Each step lasts three seconds and uses the production instrument renderer plus the existing synthetic scenario engine.

The demonstration sequence is:

- Horizon: level, pitch +10, pitch -10, bank left 30, bank right 30, combined pitch/bank, `ATTITUDE FAIL`, recovery
- Altimeter: 0, 2,500, 9,500, 10,000, 10,100, 10,500 and 12,500 ft, altitude sweep, `ALT FAIL`, recovery
- Compass: north, north-east, east, south, west, north-west, 350→010 wrap, continuous rotation, `HEADING FAIL`, recovery north

The selected heading bug is fixed at 060° during the QEMU demonstration. The on-screen test overlay identifies the current scenario and step. The complete loop is approximately **84 seconds** and then repeats.

This concise demonstration does not replace the formal acceptance records above; it samples the accepted behaviour for presentation and regression purposes.

## Swift simulator synchronisation

The native Swift iPhone/iPad simulator mirrors the accepted Horizon, Altimeter and Compass presentation. It also provides automated selectors for the complete 12-state Horizon, 14-state Altimeter and 12-state Compass acceptance suites. QEMU remains authoritative for the actual ESP32 RGB565 renderer.

## Build, run and record

From the repository root:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
zsh scripts/build-qemu.sh --clean
zsh scripts/run-qemu.sh
```

To make a macOS video recording of the full QEMU demonstration:

```bash
zsh scripts/record-qemu-demo.sh
```

The recording helper starts QEMU, asks the user to click the QEMU graphics window for macOS window capture, stops automatically and writes the `.mov` under `docs/media/`. See `DEMONSTRATION.md`.

QEMU uses the real 480×480 RGB565 geometry but bypasses physical LCD, MCP23008, encoder, backlight and sensors. `sdkconfig.qemu.defaults` disables physical PSRAM emulation. Never flash `build-qemu` to hardware.

## Display resolution and graphics-quality stage

The selected Newhaven NHD-2.1-480480AF-ASXP has a native resolution of **480×480 pixels**, so QEMU uses exactly 480×480 RGB565. Enlarging QEMU on a desktop makes primitive graphics look coarser than at the physical panel size.

The **480×480 graphics-quality stage is complete and accepted for the Artificial Horizon, Altimeter and Compass**. Sensor and physical integration remain separately gated and must not inherit an acceptance status merely from emulator success.
