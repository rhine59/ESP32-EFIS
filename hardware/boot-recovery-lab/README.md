# EFIS boot and recovery bench lab

Target: ESP32-S3-N16R8 development module, 16 MB flash. No PSRAM dependency. The production EFIS is N16R2. This lab does **not** yet implement Wi-Fi upload, physical recovery-button selection or ROM fallback automation.

## Images

`EFIS IMAGE A v1.0.0` and `EFIS IMAGE B v1.1.0` are minimal ESP-IDF/FreeRTOS applications. Each prints its identity, running partition, next update partition and a two-second heartbeat over the console. No board-specific LED GPIO is assumed; many ESP32-S3 boards use addressable LEDs requiring separate support.

Partition table reserves a factory recovery slot (1 MB) and two application slots (5 MB each), plus NVS/OTA metadata. **This is a provisional bench layout, not the final production partition table.** The factory slot is not populated with a recovery application yet.

## Build on Mac

```sh
source "$HOME/.espressif/v5.4.4/esp-idf/export.sh"
./hardware/boot-recovery-lab/build-images.sh
```

Outputs (ignored from Git): `images/efis-A-v1.0.0.bin`, `images/efis-B-v1.1.0.bin`. Each has its own build directory to prevent cross-contamination.

## Flashing and tests

Before flashing, confirm the serial port and module identification. Flashing overwrites existing software and may erase settings. The initial complete image flash requires the ESP-IDF bootloader, partition table, OTA metadata and an application; **do not write only an app `.bin` to address zero**. Use `idf.py -B build-A -p /dev/cu.usbmodem1234561 flash monitor` only after approving overwriting the connected board. A subsequent A/B switch requires an OTA update sender or test control command, which is the next lab milestone; copying B to the inactive slot alone does not select it for boot.

The code currently confirms pending OTA images after basic startup; this is intentionally only a lab health check, not production EFIS commissioning validation. Do not connect the lab image to aircraft instrumentation.

Next: implement a simple authenticated offline update sender and deliberate rollback/failure-injection modes, then implement the factory recovery image and tested physical selection mechanism described in `docs/EFIS_BOOT_AND_RECOVERY_ARCHITECTURE.md`.

## Physical bench checkpoint — 10 October 2026

Mac connected to ESP32-S3-N16R8 using `/dev/cu.usbmodem1101` after entering ROM download mode. `esptool flash_id` confirmed ESP32-S3 rev 0.2, 16 MB flash and 8 MB PSRAM. Both A and B images built successfully (~198 KB each). `idf.py -B build-A -p /dev/cu.usbmodem1101 flash` successfully wrote and verified the bootloader, partition table, OTA metadata and Image A, then reset. Serial heartbeat was **not yet observed**; verify boot/console configuration before claiming running Image A. Image B has **not** been flashed and OTA/rollback has **not** been exercised.

## Console/boot diagnosis — 10 October 2026

The initial firmware used `CONFIG_ESP_CONSOLE_USB_CDC=y`, whereas this development board exposes native USB-Serial/JTAG. Updated the lab defaults to `CONFIG_ESP_CONSOLE_USB_SERIAL_JTAG=y`, rebuilt both A/B images successfully and reflashed A (all flash hashes verified). The USB port still showed no application heartbeat. A deliberate reset pulse produced the ROM diagnostic `boot:0x0 (DOWNLOAD(USB/UART0))` and `waiting for download`, proving the board is remaining in ROM download mode rather than executing the flash image. **Next physical action:** release BOOT/GPIO0 and press RESET/EN once without BOOT held, then capture serial output. Do not proceed to A/B OTA until the application heartbeat is confirmed. The Mac USB device path was `/dev/cu.usbmodem1101` during this session.

## A/B switch test — 10 October 2026

**PASS: physical ESP32-S3 partition switching.** With the board running factory Image A, the Mac wrote lab Image B directly to `ota_0` (`0x120000`) and a lab console command `boot0` called `esp_ota_set_boot_partition()`. Serial output confirmed Image B v1.1.0 running from `ota_0` and confirming its pending OTA state. The Mac then staged Image A in `ota_1` (`0x620000`); command `boot1` selected it. Serial output confirmed `Loaded app from partition at offset 0x620000`, `IMAGE A — 1.0.0`, `Running partition: ota_1, next update: ota_0`, successful pending-image confirmation and repeated heartbeats. These are **boot-selection tests with direct serial flashing**, not yet end-to-end network/phone OTA or automatic failure rollback tests. The lab application now accepts `status`, `boot0`, and `boot1` on USB serial; these controls are strictly for bench use.

## Staged bench OTA API (development, not yet hardware validated)

The bench-only HTTP update flow now separates `POST /update` (stage),
`POST /verify` (validate the staged lab image) and `POST /activate`
(explicitly select the boot partition and reboot). `GET /status` is also
authenticated. Every request requires `X-Lab-Token` matching the unique
32-or-more-character token provisioned into NVS namespace `lab_auth`, string
key `token`. **No default token is accepted.** No NVS provisioning workflow
is implemented yet; until one is built and validated, the API fails closed.

This is not production authentication: transport is plain HTTP over a bench
WPA2 access point, and the Wi-Fi password remains a shared development value.
The server does not independently verify a signed release, the staged state
is volatile, and the HTTP upload is not resumable. Do not flash this build
or enable an aircraft OTA workflow until those gaps are resolved. The existing
recovery image and running application remain unchanged.

## 18 October 2026 — partition safety and fail-closed Wi-Fi

The bench partition CSV is now aligned with the physically read 16 MB RedOne
layout (`firmware/partitions.csv`): recovery at `0x20000`, OTA A at
`0x120000`, OTA B at `0x420000`. This prevents the build from silently
using the obsolete 5 MB OTA slot layout. **Never run `idf.py flash` for this
bench project on a provisioned board:** that would write a normal lab app
into the factory recovery slot. Only a reviewed app-only update to an inactive
OTA slot may be considered after verification of the boot state and image.

Bench SoftAP and HTTP are disabled unless NVS `lab_auth` contains a unique
`ap_password` (16–63 chars) and `token` (32–64 chars). No default Wi-Fi
password or API token exists, and NVS is never automatically erased.
Credential provisioning and authenticated transport remain TODO; these
changes alone do not make this a production OTA service.

## Offline bench credential generation (no flashing)

`python3 tools/prepare_bench_credentials.py --output private-credentials`
creates a mode-0600 private credential file and a 24 KB NVS image with
random per-device Wi-Fi and API credentials. It refuses to overwrite a
nonempty output directory and does **not** connect to or write to the ESP32.
The private directory is ignored by Git.

**CRITICAL:** This is a *whole-partition* NVS image, not an in-place NVS
update. Flashing it would erase existing NVS values, including settings
needed by other firmware. It must **not** be flashed to the current RedOne.
A non-destructive on-device provisioning mechanism, secure credential
exchange to the phone, and authenticated encrypted transport are required
before proceeding with live OTA. The tool is a generation/format test only.

## Non-destructive USB provisioning — bench implementation

The **new** boot-lab app accepts `provision` on its physically connected USB
serial console. It reads an AP password and API token (one line each), checks
lengths, and commits only `lab_auth/ap_password` and `lab_auth/token` using
ESP-IDF NVS APIs. It never calls `nvs_flash_erase()`, and existing unrelated
NVS keys remain intact. Reboot to start the provisioned AP.

**Not yet flashed or hardware tested.** This command is unavailable in the
currently installed firmware. Terminal software may echo/log input; do not
use a logging terminal, and treat the USB link as physically trusted only.
There is no secure channel, device attestation, signature verification, or
phone pairing yet. The offline generated whole-partition NVS image remains
DO-NOT-FLASH.
