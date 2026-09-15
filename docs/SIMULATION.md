# Bench and QEMU simulation

The firmware contains an explicit synthetic-data source so the complete three-page UI can be exercised before all flight sensors and display hardware are available. Simulation is development-only and must never be used as a fallback for failed flight data.

## Safety behaviour

`CONFIG_EFIS_BENCH_SIMULATION` defaults to **OFF**. Synthetic data carries an explicit `simulated` flag through the instrument data model. Every firmware-rendered screen displays a permanent high-contrast red **SIM** marker whenever synthetic values are active. The serial log also reports `BENCH SIMULATION: ENABLED - SYNTHETIC DATA`.

For any aircraft-use build, simulation and QEMU mode must both remain disabled. Before loading firmware for aircraft use, verify the boot log reports `BENCH SIMULATION: OFF`. Missing or failed real sensors must produce invalid indications, never synthetic or frozen plausible values.

## Current simulated motion

- pitch: slow ±8° sinusoid
- roll: slow ±28° sinusoid
- altitude: approximately 1550–3350 ft
- heading: continuous 12°/s rotation through 000/359
- all simulated validity flags are true

## Physical bench simulation

Enable **ESP32 EFIS development options → Enable synthetic bench flight data** with `idf.py menuconfig`. This leaves the real LCD, MCP23008, encoder and BMI088 hardware paths active while substituting synthetic flight values.

ESP-IDF boolean Kconfig symbols that are disabled are normally absent from `sdkconfig.h`; the firmware therefore tests development symbols with `#ifdef` rather than assuming they expand to zero.

## QEMU virtual display

QEMU mode is a separate Kconfig option, `CONFIG_EFIS_QEMU`, and depends on bench simulation. It bypasses physical LCD, MCP23008, encoder, backlight and BMI088 initialization and uses Espressif's `esp_lcd_qemu_rgb` virtual RGB panel in RGB565 mode at the real 480×480 instrument resolution. The QEMU display automatically cycles Horizon → Altimeter → Compass while the synthetic flight evolves.

The managed component dependency is pinned to compatible major version `espressif/esp_lcd_qemu_rgb ^1.0.2`. Espressif documents the virtual framebuffer as supporting RGB565 and the ESP-IDF QEMU launcher can open the graphics window with `--graphics`.

### First-time QEMU setup on macOS

With ESP-IDF v5.4.4 installed, install the optional Xtensa QEMU tool if it is not already present:

```bash
cd ~/.espressif/v5.4.4/esp-idf
python tools/idf_tools.py install qemu-xtensa
. ./export.sh
```

If QEMU reports missing host libraries, install the documented macOS dependencies with Homebrew: `libgcrypt`, `glib`, `pixman`, `sdl2`, and `libslirp`.

### Build the emulator configuration

From the repository root:

```bash
cd firmware
rm -rf build-qemu
idf.py -B build-qemu -D SDKCONFIG=build-qemu/sdkconfig \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  set-target esp32s3 build
```

This keeps the emulator configuration separate from the normal hardware `sdkconfig` and prevents QEMU/synthetic settings leaking into an aircraft build.

### Run with graphics

```bash
idf.py -B build-qemu -D SDKCONFIG=build-qemu/sdkconfig \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  qemu --graphics monitor
```

Expected behaviour: a 480×480 QEMU graphics window appears, synthetic instruments animate, the page changes automatically about every eight seconds, and every page carries the red **SIM** marker. The console must also report both `BENCH SIMULATION: ENABLED - SYNTHETIC DATA` and `QEMU MODE: ENABLED - NO PHYSICAL SENSOR OR DISPLAY I/O`.

## Bench test sequence

1. Enable simulation and verify both the serial warning and red **SIM** marker.
2. Observe changing PFD state.
3. On physical bench hardware, short-push to Altimeter and confirm all hands move smoothly and wrap correctly.
4. Long-push, rotate QNH, exit settings, power-cycle and verify persistence.
5. Short-push to Compass and verify the card rotates beneath the fixed aircraft/lubber line.
6. Set heading bug and verify persistence.
7. Cycle back to Horizon/PFD.
8. Rebuild with simulation disabled and verify `BENCH SIMULATION: OFF`; unavailable real data must become visibly invalid.

## References

Espressif ESP-IDF QEMU documentation and the Espressif Component Registry entry for `esp_lcd_qemu_rgb` are the authoritative references for emulator installation and the virtual RGB framebuffer API.
