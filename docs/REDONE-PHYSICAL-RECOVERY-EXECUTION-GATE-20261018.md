# RedOne physical factory recovery — independent execution gate

**18 October 2026 — OFFLINE EVIDENCE PASS; PHYSICAL EXECUTION NO-GO.**

`hardware/boot-recovery-lab/tools/recovery_execution_gate.py` independently verifies the board MAC argument, known full 16 MiB backup SHA-256 and length, known current 8 KiB OTA selection snapshot and exact backup match, known full 1 MiB factory recovery SHA-256 and exact backup match, image headers and selection of `ota_0`. It is read-only, does not open a serial port and does not contain any flash-writing operation. A supplied board MAC is **not** a fresh live measurement; repeat physical identification at the time of any supervised test.

All ten offline evidence checks passed with the existing verified local backup and independently captured snapshots. This does not establish that the USB recovery console is accessible when booted, that the recovery `bootA` operation works on physical hardware, or that a host-side OTA metadata rescue write is safe. Consequently the tool always reports `independent_physical_rescue_validation=false`, `physical_factory_boot_authorized=false`, `host_flash_write_authorized=false` and `partition_b_authorized=false`, even on a passing preflight.

Run read-only:

```sh
python3 hardware/boot-recovery-lab/tools/recovery_execution_gate.py \
  hardware/board-backups/redone-pre-recovery-20261018-fullflash.bin \
  hardware/board-backups/redone-pre-recovery-20261018-otadata.bin \
  /tmp/redone-live-factory-recovery-20261018.bin \
  --board-mac 3c:0f:02:d6:1f:dc
```

**Next practical milestone:** validate a controlled OTA-selection-only rescue on a disposable matching ESP32-S3 board, then independently review the supervised recovery test plan and seek explicit approval. Until then, do not issue `bootA`, `bootB`, `esp_ota_set_boot_partition(factory)`, any OTA metadata erase/write, or generic firmware flashing on the existing RedOne. The existing device is not approved for flight reliance.
