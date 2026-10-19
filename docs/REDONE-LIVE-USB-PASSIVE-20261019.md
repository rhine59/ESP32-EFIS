# Existing RedOne: passive USB serial observation — 19 October 2026

**Connection:** Mac `/dev/cu.usbmodem101`, 115200 baud. Serial port existed, was not held by another process, and opened successfully using pyserial 3.5 in the ESP-IDF 5.4.4 Python environment. No bytes were written to the serial device, and no esptool, flashing, boot-selection or reset command was executed.

Observed during a short passive read:

```text
I (38752343) BOOT_LAB: IMAGE B v1.1.0 heartbeat 19377
```

The `IMAGE B` text is an application diagnostic label, **not** the actual running OTA slot. Prior authenticated/read-only evidence indicated `ota_0` was running. This passive heartbeat alone does not verify the active partition, firmware authenticity, signed update readiness, boot-health or recovery bootability. Serial opening can alter USB control-line state depending on the adapter and firmware; the observation is not evidence of a reset-free physical session.

**Physical deployment:** NO-GO. No partition data or eFuses were modified. Continue with passive monitoring and authenticated read-only status only until specific physical-change approval and safety gates are satisfied.
