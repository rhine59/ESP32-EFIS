# ESP-IDF Firmware

Target: **ESP32-S3-WROOM-1-N16R2**, framework baseline **ESP-IDF v5.4.4**.

The firmware is structured as a **multi-panel supplementary flight instrument** with three 480×480 pages:

1. Artificial Horizon / PFD
2. Classic Altimeter
3. Compass

A short PEC09 encoder press advances to the next panel. A long press of about 0.8 seconds enters/leaves the current panel's settings. Rotation changes Horizon brightness, Altimeter QNH or Compass heading bug. UI settings are persisted in NVS.

Per-panel operating documentation is in [`../docs/user-guides/`](../docs/user-guides/README.md).

## Safety and data validity

`instrument_data_t` keeps values separate from their validity flags. Renderers must never treat stale, failed or absent sensor data as valid, and the system must not replace failed real data with synthetic values or freeze a plausible indication.

Synthetic bench data is opt-in and defaults OFF. When it is enabled, the data model sets its `simulated` flag and every firmware-rendered page carries a permanent high-contrast red **SIM** marker.

This remains a **supplementary/non-primary flight-development instrument**.

## Source layout

```text
main/
├── app_main.c              physical/QEMU startup and main UI loop
├── instrument_ui.c/.h      PEC09 control and NVS-backed settings
├── instrument_screens.c/.h three-panel renderer and validity contract
├── instrument_sim.c/.h     explicit synthetic development data
├── horizon_renderer.c/.h   horizon graphics
├── bmi088.c/.h             BMI088 SPI bring-up
├── mcp23008.c/.h           LCD control plus encoder input I/O
├── st7701s.c/.h            physical panel controller initialization
├── Kconfig.projbuild       simulation/QEMU development options
└── idf_component.yml       managed QEMU RGB component dependency
```

## Physical display configuration

- Newhaven `NHD-2.1-480480AF-ASXP`
- ST7701S
- 480×480 RGB565, 16-bit RGB bus
- 30 MHz pixel clock
- HFP/HBP/HS = 50/50/4
- VFP/VBP/VS = 50/50/2
- two 460,800-byte framebuffers fit within the physical module's 2 MB Quad PSRAM

The ST7701S is configured first over 3-wire/9-bit serial; the same GPIOs are then reused for BMI088 SPI. The project adapts Newhaven's panel sequence from 18-bit to the ST7701S 16-bit `VIPF=101` mode; physical-panel verification remains required.

## QEMU backend

`CONFIG_EFIS_QEMU` is emulator-only and depends on `CONFIG_EFIS_BENCH_SIMULATION`. The QEMU path bypasses physical LCD, MCP23008, encoder, backlight and sensor initialization and renders to Espressif's `esp_lcd_qemu_rgb` virtual 480×480 RGB565 display.

The normal hardware defaults enable external Quad PSRAM for the N16R2. QEMU builds override this with `# CONFIG_SPIRAM is not set` in `sdkconfig.qemu.defaults`; otherwise ESP-IDF asserts in `esp_psram_init()` before `app_main()` because the emulated configuration does not provide the physical PSRAM device.

Keep QEMU in the separate `build-qemu` directory and never flash that image to aircraft hardware.

## macOS shell setup

After the one-time ESP-IDF/QEMU installation, use the repository environment script in every new shell:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
cd "$EFIS_FIRMWARE_DIR"
```

The script pins the known ESP-IDF v5.4.4 interpreter at `~/.espressif/tools/python/v5.4.4/venv/bin/python`, prevents a second ESP-IDF Python environment from silently taking over an existing CMake build, and adds the installed QEMU binary to PATH when Espressif's export step omits it.

## Normal hardware build

```bash
cd "$EFIS_FIRMWARE_DIR"
idf.py set-target esp32s3
idf.py build
```

Normal `sdkconfig.defaults` keeps physical PSRAM enabled and bench simulation disabled.

## Clean QEMU build and run

```bash
cd "$EFIS_FIRMWARE_DIR"
rm -rf build-qemu

idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  set-target esp32s3

idf.py -B build-qemu \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.qemu.defaults" \
  build

idf.py -B build-qemu qemu --graphics monitor
```

See [`../docs/MACOS_BUILD_AND_QEMU_SETUP.md`](../docs/MACOS_BUILD_AND_QEMU_SETUP.md), [`../docs/SIMULATION.md`](../docs/SIMULATION.md) and [DEPLOYMENT.md](DEPLOYMENT.md).

## Current implementation direction

The attitude path remains first: configure BMI088 ranges/ODR, acquire and timestamp samples, calibrate gyro bias, apply the aircraft-axis transform, run quaternion AHRS and acceleration-confidence logic, then feed validated live pitch/roll to the Horizon panel.

The Altimeter path uses the selected ported BMP585 architecture and needs live pressure/QNH processing. The Compass architecture uses the selected remote PNI RM3100-CB as the absolute-heading source, with appropriate AHRS fusion and independent validity/freshness monitoring.

## Planned boot state machine and maintenance functions

The adopted physical boot UI is controlled by the PEC09 rotary/push encoder and offers **START EFIS** (default), **FULL TEST**, and **FIRMWARE UPDATE**. FULL TEST will run the staged electrical/component harness documented in `../docs/ELECTRICAL_TEST_HARNESS.md`. FIRMWARE UPDATE will first establish Wi-Fi through a rotary-operated connection dialog before any OTA manifest request.

Wi-Fi SSID/credentials persist in a dedicated ESP-IDF NVS namespace. Production firmware requires encrypted NVS for credentials; credentials must not be redisplayed after entry or emitted in logs/diagnostics. These boot/test/network functions are design requirements until their firmware implementation and validation status is explicitly advanced.


## Persistent operational fault log

Normal-operation hardware and software faults must be captured in a persistent, bounded ESP32 non-volatile fault/event log. The boot menu includes **FAULT LOG**, navigated with the PEC09 rotary/push control. Repeated instances of the same continuing fault are coalesced/count-incremented where practical to limit flash wear rather than written on every poll.

Records include stable fault code, source/subsystem, severity, occurrence information, firmware/build identity and safe diagnostic context. Valid timestamps may be added when a trustworthy time source is available. Wi-Fi credentials and other secrets must never be logged. Log clearing is explicit and confirmed; reboot/update must not erase the history. Runtime failure indications remain immediate and independent of the persistent log.


## Product licence subsystem — planned

Provision a local/offline licence verifier using signed licence payloads. Production units have a stable provisioned device/product ID; an authorised off-device tool signs licences with a private key while firmware contains only the corresponding public verification key. Verified licence state is persisted in protected non-volatile storage.

The rotary boot/maintenance menu gains **LICENSE** for Status, Install/Replace and Reset. USB/service installation is the baseline; a later authenticated network path may be added. Reset is explicit/confirmed, clears installed licence state, is logged, and does not alter Wi-Fi credentials. Firmware updates normally preserve the licence. Licence and OTA signing keys are separate.

Licensing must not create plausible-but-invalid flight indications or suppress required failure annunciation. Core versus optionally licensed functions must be explicitly defined before production.
