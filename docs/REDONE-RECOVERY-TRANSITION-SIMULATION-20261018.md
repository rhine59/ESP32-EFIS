# RedOne factory recovery → Partition A offline transition rehearsal

**Date:** 18 October 2026. **Physical recovery boot NO-GO; Partition B NO-GO.**

The read-only `hardware/boot-recovery-lab/tools/recovery_transition_sim.py` consumes a local 8 KiB OTA metadata snapshot, never connects to USB or modifies flash, and models the installed ESP-IDF v5.4.4 factory boot selection (both OTA sectors erased) followed by the deployed recovery application's `bootA` command (first OTA sector rewritten to sequence 1).

The physical snapshot starts with two CRC-valid, VALID records and selects `ota_0`. Erased OTA metadata has no selectable OTA record; the ESP-IDF default boot selection prefers the factory recovery app. After the modeled `bootA` write, both `NEW` and `UNDEFINED` OTA-state variants select `ota_0` under the offline decoder. This does not model image validation failures, unexpected power loss, hardware flash write errors, USB serial availability or actual bootloader execution.

Run:

```sh
python3 hardware/boot-recovery-lab/tools/recovery_transition_sim.py hardware/board-backups/redone-pre-recovery-20261018-otadata.bin
```

**Outstanding:** fresh full 16 MiB backup was not completed because the serial read was unusually slow; the previous full backup is intact but its OTA metadata is stale. The rescue route has not been physically tested on expendable hardware. Neither the simulator nor this document authorises a host-side flash write, factory boot selection or eFuse change.
