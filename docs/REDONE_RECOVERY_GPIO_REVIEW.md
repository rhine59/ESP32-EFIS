# RedOne physical recovery input — schematic review

Status: **hardware change required; no GPIO approved yet**.

Reviewed `hardware/schematics/CARRIER_PCB_SCHEMATIC.md`, `hardware/schematics/carrier-netlist.csv`, and `hardware/kicad/carrier_rev_a/README.md`.

## Existing controls

- RESET switch asserts EN low; this resets the chip but does not choose factory Recovery.
- BOOT switch asserts GPIO0 low; when sampled at reset this selects ESP32-S3 ROM download mode, **not** the recovery application. Preserve it as the last-resort USB service path.
- Rotary encoder push switch is connected to MCP23008 GP4, via I2C on GPIO47/48. The second-stage bootloader would need additional I2C setup to read it. Do **not** assume it can be read safely at early boot; it also depends on an external expander.
- GPIO44 is listed as SPARE_DEBUG/test pad. It is a **candidate only**, not an approved recovery input. Check silicon restrictions, board revision, external wiring, default pull state, test-pad accessibility, serial/UART use, and production power sequencing before allocation.

## Proposed production change

Add a recessed, labelled RECOVERY switch with a defined pull-up to 3V3 and switch to GND, routed directly to an approved non-strapping ESP32-S3 GPIO. Include ESD/debounce as appropriate. Maintain accessible BOOT and RESET controls. The bootloader must sample the recovery input before selecting OTA A/B, with an explicit and testable override to the factory Recovery partition. The input must not depend on the normal application, the LCD, MCP23008, Wi-Fi or either OTA partition.

## Software gate

Do not commit an enabled GPIO override until the pin and circuit are validated. Standard ESP-IDF does not provide the proposed application-selection behaviour simply because a factory partition exists. Prototype a bootloader override in a separate bench target and test against ESP-IDF v5.4.4. Also implement failure accounting for repeated watchdog resets; an invalid image and a boot loop require different detection strategies. OTA rollback by itself does not cover all failure scenarios.

## Hardware validation cases

1. Power cycle without RECOVERY: A boots, B remains erased.
2. Hold RECOVERY before power on: factory Recovery boots despite valid A.
3. Hold RECOVERY with A/B corrupted and otadata erased: factory Recovery boots.
4. Release RECOVERY and restart: normal selected validated application boots.
5. Hold BOOT during reset: ROM USB download mode remains accessible.
6. Switch bounce, brownout and a stuck RECOVERY input do not corrupt boot metadata.

No hardware flash or eFuse/security changes are authorized by this review.
