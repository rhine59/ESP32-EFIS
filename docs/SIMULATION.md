# Bench screen simulation

The firmware contains an explicit synthetic-data source so the complete three-page UI can be exercised before pressure and heading hardware is available.

## Purpose
Simulation is for display, encoder, persistence and graphics testing only. It supplies changing pitch, roll, altitude and heading values to exercise the Horizon/PFD, classic altimeter hands and rotating compass card.

## Current simulated motion
- pitch: slow ±8° sinusoid
- roll: slow ±28° sinusoid
- altitude: approximately 1550–3350 ft
- heading: continuous 12°/s rotation through 000/359
- all simulated validity flags are true

## Enabling
`firmware/main/app_main.c` currently contains:

```c
#define BENCH_SIMULATION true
```

The serial log prints an explicit warning at boot when simulation is enabled.

## Mandatory flight-build rule
Before any aircraft-use firmware build, set `BENCH_SIMULATION` to `false`. With simulation disabled, absent real sensor pipelines remain invalid. Synthetic values must never be used as a fallback for sensor failure.

A later firmware cleanup should move this switch into a dedicated ESP-IDF Kconfig build option and make the production/aircraft configuration default OFF.

## Bench test sequence
1. flash the development build and verify the serial `BENCH SIMULATION: ENABLED` warning;
2. observe changing PFD test state;
3. short-push to Altimeter and confirm all hands move smoothly and wrap correctly;
4. long-push, rotate QNH, exit settings, power-cycle and verify persistence;
5. short-push to Compass and verify the card rotates beneath the fixed aircraft/lubber line;
6. set heading bug and verify persistence;
7. cycle back to Horizon/PFD;
8. rebuild with simulation disabled and verify unavailable real data becomes visibly invalid.
