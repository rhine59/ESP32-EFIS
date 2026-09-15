# Bench and QEMU simulation

The firmware contains an explicit synthetic-data source so the UI can be exercised before all flight sensors and display hardware are available. Simulation is development-only and must never be used as a fallback for failed flight data.

## Safety behaviour

`CONFIG_EFIS_BENCH_SIMULATION` defaults to **OFF**. Synthetic data carries an explicit `simulated` flag through the instrument data model. Every firmware-rendered screen displays a permanent high-contrast red **SIM** marker whenever synthetic values are active.

For any aircraft-use build, simulation and QEMU mode must both remain disabled. Missing or failed real sensors must produce invalid indications, never synthetic or frozen plausible values.

## One instrument at a time

QEMU acceptance testing is deliberately performed one instrument at a time so the observer does not have to correlate a rapidly changing scenario with a separately changing page. The current development stage is **Artificial Horizon / PFD only**. QEMU locks `ui.panel` to `PANEL_HORIZON`; Altimeter and Compass acceptance sequences will be enabled only after the Horizon/PFD is accepted.

The attitude sequence contains six eight-second tests:

1. `LEVEL` — pitch 0°, roll 0°.
2. `PITCH +10` — fixed +10° pitch.
3. `PITCH -10` — fixed -10° pitch.
4. `BANK LEFT 30` — fixed -30° roll.
5. `BANK RIGHT 30` — fixed +30° roll.
6. `ATTITUDE FAIL` — attitude validity false while altitude and heading remain valid.

The sequence repeats continuously. The console logs `QEMU ATTITUDE TEST n/6`, but the essential test information is also rendered directly on the QEMU display so terminal watching is not required.

## On-screen test overlay

The PFD displays a black/yellow test banner containing `TEST MODE - ATTITUDE`, the test number, scenario name and seconds remaining. The red **SIM** marker remains separately visible. Test metadata exists only for the development presentation and does not alter the normal hardware UI path.

The PFD also shows heading and altitude source regions while attitude is being tested, allowing the attitude-failure scenario to demonstrate that unrelated valid sources remain available. A failed attitude source must produce the conspicuous large red X over the attitude presentation.

## Physical bench simulation

Enable **ESP32 EFIS development options → Enable synthetic bench flight data** with `idf.py menuconfig`. This leaves the real LCD, MCP23008, encoder and BMI088 hardware paths active while substituting synthetic values. The QEMU on-screen test metadata and automatic acceptance sequence are confined to QEMU mode.

## QEMU virtual display

QEMU mode uses Espressif's `esp_lcd_qemu_rgb` virtual RGB panel in RGB565 at the real 480×480 resolution and bypasses physical LCD, MCP23008, encoder, backlight and BMI088 initialization.

The physical ESP32-S3-WROOM-1-N16R2 uses external Quad PSRAM. QEMU overrides the hardware default with `# CONFIG_SPIRAM is not set` in `sdkconfig.qemu.defaults`; otherwise ESP-IDF asserts in `s_psram_chip_init` before `app_main()`.

### Start the environment

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
```

### Build

```bash
idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  build
```

Use `rm -rf build-qemu` first after emulator configuration/Kconfig changes.

### Run

```bash
idf.py -B build-qemu qemu --graphics monitor
```

Expected current behaviour is one fixed Artificial Horizon/PFD screen cycling through the six labelled attitude tests. Exit with `Ctrl-]`.

## Current attitude acceptance criteria

Check each labelled state against the displayed geometry rather than trying to identify it from motion alone. LEVEL must be level; positive and negative pitch must move in the correct direction and by a repeatable amount; left and right 30° bank must have the correct sign; ATTITUDE FAIL must replace a plausible attitude presentation with an unmistakable red invalid indication while valid altitude and heading remain independently presented. The red **SIM** annunciation must remain visible throughout.

After these tests and the PFD presentation are accepted, the next QEMU stage will lock the display to the Altimeter and exercise altitude-specific cases. Compass/heading testing follows separately.

## References

Espressif ESP-IDF QEMU documentation and the Espressif Component Registry entry for `esp_lcd_qemu_rgb` are the authoritative references for emulator installation and the virtual RGB framebuffer API.
