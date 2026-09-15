# Bench and QEMU simulation

Simulation is development-only and must never be used as a fallback for failed flight data. `CONFIG_EFIS_BENCH_SIMULATION` defaults OFF. Every synthetic presentation carries a permanent red **SIM** annunciation. Aircraft builds must keep simulation and QEMU disabled; missing or stale real data must fail visibly.

## One instrument at a time

QEMU acceptance is deliberately performed one instrument at a time. The current stage is **Artificial Horizon / PFD only** and `ui.panel` is locked to `PANEL_HORIZON`. Altimeter and Compass testing remain parked until attitude presentation is accepted.

## Artificial Horizon acceptance suite

The current sequence contains twelve six-second states and repeats continuously:

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
12. `RECOVERY LEVEL` — explicit valid level state immediately after failure, proving recovery does not leave stale invalid/frozen state.

The on-screen black/yellow test banner gives test number, scenario and countdown, so terminal watching is unnecessary. The console also logs transitions.

## PFD presentation reference

The Artificial Horizon presentation now follows the approved round-EFIS visual reference rather than the earlier bare framebuffer presentation. The renderer keeps the already-tested pitch and bank geometry, but adds a dark circular inner bezel, contrasting inner lip, conventional fixed bank scale at 10°, 20°, 30°, 45° and 60°, and a fixed triangular bank pointer. The yellow aircraft reference remains fixed at the display centre.

Altitude is presented in a compact black/white box at the right and heading in a compact box below the attitude sphere, with valid numeric values highlighted in green. Development-only `TEST MODE - ATTITUDE` and red `SIM` annunciations remain deliberately conspicuous. The test overlay is not part of the intended aircraft presentation.

Attitude invalidity now replaces the central plausible attitude area with a prominent black/red `ATT FAIL` annunciation and red crossed invalid indication. The underlying data may still exist in memory for diagnostics, but it must not remain visually usable as though valid.

## Acceptance criteria

The fixed yellow aircraft reference must not move and must lie on the zero-pitch horizon in LEVEL. Positive pitch moves the horizon downward; negative pitch moves it upward. The attitude sphere moves opposite aircraft bank: in left bank the horizon slopes down to the left/up to the right, and vice versa for right bank. Pitch ladder and horizon must rotate together. Combined pitch/bank must preserve both transformations. Fixed bezel/bank markings must not rotate with the attitude sphere. `ATTITUDE FAIL` must make a plausible attitude unusable immediately while unrelated valid altitude/heading remain available. `RECOVERY LEVEL` must restore a fresh valid level presentation. The red **SIM** annunciation remains visible throughout.

## Build and run scripts

From the repository root:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
zsh scripts/build-qemu.sh
zsh scripts/run-qemu.sh
```

For a clean emulator rebuild use `zsh scripts/build-qemu.sh --clean`. QEMU uses the real 480×480 RGB565 geometry but bypasses physical LCD, MCP23008, encoder, backlight and sensors. `sdkconfig.qemu.defaults` disables physical PSRAM emulation while the normal hardware build retains the ESP32-S3-WROOM-1-N16R2 PSRAM configuration. Never flash `build-qemu` to hardware.

Physical bench simulation leaves hardware I/O active and substitutes explicitly synthetic instrument data. It is separate from QEMU and must never be enabled for aircraft use.

## Next stage

Once this twelve-state Horizon/PFD suite and revised bezel presentation are accepted, freeze the attitude renderer and switch QEMU to an Altimeter-only acceptance sequence. Compass/heading follows separately.
