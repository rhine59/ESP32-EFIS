# Bench and QEMU simulation

The firmware contains an explicit synthetic-data source so the complete three-page UI can be exercised before all flight sensors and display hardware are available. Simulation is development-only and must never be used as a fallback for failed flight data.

## Safety behaviour

`CONFIG_EFIS_BENCH_SIMULATION` defaults to **OFF**. Synthetic data carries an explicit `simulated` flag through the instrument data model. Every firmware-rendered screen displays a permanent high-contrast red **SIM** marker whenever synthetic values are active. The serial log also reports `BENCH SIMULATION: ENABLED - SYNTHETIC DATA`.

For any aircraft-use build, simulation and QEMU mode must both remain disabled. Before loading firmware for aircraft use, verify the boot log reports `BENCH SIMULATION: OFF`. Missing or failed real sensors must produce invalid indications, never synthetic or frozen plausible values.

## Deterministic simulator scenarios

The QEMU simulator is a repeatable test harness rather than an uncontrolled flight animation. Each scenario begins from a known reference state of pitch 0°, roll 0°, altitude 2500 ft and heading 000°, with all sources valid unless that scenario deliberately fails one.

The scenario sequence is:

1. `LEVEL` — 0° pitch, 0° roll, 2500 ft, heading 000°.
2. `PITCH +10` — fixed +10° pitch.
3. `PITCH -10` — fixed -10° pitch.
4. `BANK LEFT 30` — fixed -30° roll.
5. `BANK RIGHT 30` — fixed +30° roll.
6. `ALTITUDE 1000-5000` — controlled sweep between 1000 and 5000 ft.
7. `HEADING 350-010` — controlled heading movement through the 359°/000° wrap.
8. `ATTITUDE FAIL` — attitude validity false while altitude and heading remain valid.
9. `ALTITUDE FAIL` — altitude validity false while attitude and heading remain valid.
10. `HEADING FAIL` — heading validity false while attitude and altitude remain valid.
11. `ALL FAIL` — attitude, altitude and heading validity all false.

QEMU advances to the next scenario every eight seconds and also advances the displayed panel. The serial console logs each scenario transition as `QEMU SCENARIO: ...`, making screenshots and observed behaviour reproducible. Failure scenarios are specifically intended to prove the fail-obvious display contract: invalid data must not remain as a plausible frozen instrument indication.

## Physical bench simulation

Enable **ESP32 EFIS development options → Enable synthetic bench flight data** with `idf.py menuconfig`. This leaves the real LCD, MCP23008, encoder and BMI088 hardware paths active while substituting synthetic flight values. The same deterministic simulator data source is used, starting with the LEVEL scenario; automatic QEMU scenario sequencing is confined to QEMU mode.

ESP-IDF boolean Kconfig symbols that are disabled are normally absent from `sdkconfig.h`; the firmware therefore tests development symbols with `#ifdef` rather than assuming they expand to zero.

## QEMU virtual display

QEMU mode is a separate Kconfig option, `CONFIG_EFIS_QEMU`, and depends on bench simulation. It bypasses physical LCD, MCP23008, encoder, backlight and BMI088 initialization and uses Espressif's `esp_lcd_qemu_rgb` virtual RGB panel in RGB565 mode at the real 480×480 instrument resolution.

The managed component dependency is pinned to compatible major version `espressif/esp_lcd_qemu_rgb ^1.0.2`. The virtual framebuffer supports RGB565 and the ESP-IDF QEMU launcher can open the graphics window with `--graphics`.

The physical ESP32-S3-WROOM-1-N16R2 target uses external Quad PSRAM, so `sdkconfig.defaults` enables `CONFIG_SPIRAM`. The QEMU target overrides that hardware setting with `# CONFIG_SPIRAM is not set` in `sdkconfig.qemu.defaults`. Without this override the emulator reaches `esp_psram_init()` during CPU startup, asserts in `s_psram_chip_init`, and continuously reboots before `app_main()` can run. This is an emulator-only override; PSRAM remains enabled for normal hardware builds.

### First-time QEMU setup on macOS

Use the full setup procedure in `MACOS_BUILD_AND_QEMU_SETUP.md`. For normal development shells the preferred entry point is:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
```

The helper pins ESP-IDF v5.4.4 and its known Python environment and adds the installed Espressif QEMU binary to PATH when required.

### Build the emulator configuration

After configuration changes, use a clean QEMU build:

```bash
rm -rf build-qemu
idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  set-target esp32s3
idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  build
```

This keeps emulator configuration separate from the normal hardware build and prevents QEMU/synthetic settings leaking into an aircraft build.

### Run with graphics and capture a log

```bash
rm -f qemu.log
idf.py -B build-qemu qemu --graphics monitor 2>&1 | tee qemu.log
```

Expected behaviour: a 480×480 QEMU graphics window appears, the test scenarios advance every eight seconds, the Horizon/PFD, Altimeter and Compass are exercised, and every page carries the red **SIM** marker. The console reports `BENCH SIMULATION: ENABLED - SYNTHETIC DATA`, `QEMU MODE: ENABLED - NO PHYSICAL SENSOR OR DISPLAY I/O`, `QEMU TEST HARNESS`, and each `QEMU SCENARIO` transition.

Exit the ESP-IDF monitor/QEMU session with `Ctrl-]`. If necessary, QEMU can be terminated from another shell with `pkill -f qemu-system-xtensa`.

## QEMU acceptance sequence

A useful complete run is long enough to observe all eleven scenarios. Verify the fixed attitude cases have the expected sign and magnitude, the altitude hands sweep without discontinuity, heading crosses 359°/000° correctly, and each individual failure invalidates only its affected presentation. `ALL FAIL` must make all three data domains invalid. At no point may a failed source leave its previous valid value displayed as though it were current.

The red **SIM** annunciation must remain present throughout all valid and invalid synthetic scenarios. Its presentation may be refined for screen space, but it must remain unmistakable.

## References

Espressif ESP-IDF QEMU documentation and the Espressif Component Registry entry for `esp_lcd_qemu_rgb` are the authoritative references for emulator installation and the virtual RGB framebuffer API.
