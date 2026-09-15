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
Bench simulation is controlled by the ESP-IDF Kconfig option `CONFIG_EFIS_BENCH_SIMULATION`, defined in `firmware/main/Kconfig.projbuild`.

The option defaults to **OFF**. This is deliberate: a normal build must never silently contain synthetic flight data.

Enable it only for an explicit bench or emulator build, for example with `idf.py menuconfig` under **ESP32 EFIS development options → Enable synthetic bench flight data**, then rebuild. The serial log prints an explicit warning at boot when simulation is enabled.

ESP-IDF boolean Kconfig symbols that are disabled are normally absent from `sdkconfig.h`; `app_main.c` therefore tests the symbol with `#ifdef CONFIG_EFIS_BENCH_SIMULATION` rather than assuming it expands to zero. This keeps the default-OFF configuration buildable and unambiguous.

## Mandatory flight-build rule
For any aircraft-use firmware build, `CONFIG_EFIS_BENCH_SIMULATION` must remain disabled. With simulation disabled, absent real sensor pipelines remain invalid. Synthetic values must never be used as a fallback for sensor failure.

Before loading firmware for aircraft use, verify the boot log reports `BENCH SIMULATION: OFF`.

## Bench test sequence
1. enable `CONFIG_EFIS_BENCH_SIMULATION`, flash the development build and verify the serial `BENCH SIMULATION: ENABLED - SYNTHETIC DATA` warning;
2. observe changing PFD test state;
3. short-push to Altimeter and confirm all hands move smoothly and wrap correctly;
4. long-push, rotate QNH, exit settings, power-cycle and verify persistence;
5. short-push to Compass and verify the card rotates beneath the fixed aircraft/lubber line;
6. set heading bug and verify persistence;
7. cycle back to Horizon/PFD;
8. rebuild with simulation disabled and verify the boot log reports `BENCH SIMULATION: OFF` and unavailable real data becomes visibly invalid.
