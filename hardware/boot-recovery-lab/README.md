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
