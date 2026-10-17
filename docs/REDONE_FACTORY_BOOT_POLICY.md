# RedOne factory image and boot/recovery policy (approved design)

## Factory delivery

Ship ESP32-S3 with independently serviceable factory Recovery partition populated, OTA A populated with validated EFIS, OTA B erased/empty, and OTA selection data initialized to boot A. Provision unique device Wi-Fi credentials and maintenance identity during factory acceptance. Verify all three partition states and actual power-cycle boot behaviour. Never treat an uninitialized OTA selection partition as proof that A boots by default.

## Recovery entry requirements

1. **Manual hardware entry, mandatory:** provide a dedicated accessible recovery input sampled by bootloader code before application selection. GPIO and polarity are **TBD pending schematic review**, including ESP32-S3 strapping pins, pull resistors and startup timing. A menu in the normal application is not an acceptable recovery mechanism.
2. **Lollipop-requested entry:** authenticated command to healthy application, which requests one-time Recovery boot and restarts. Must not permanently replace the selected known-good application; restore normal boot after service.
3. **Failure entry:** bootloader must handle invalid A/B images, boot loops and failed health checks using an explicitly validated fallback policy. ESP-IDF rollback handles some unconfirmed OTA images, but **does not by itself guarantee factory Recovery on all failure modes**. A custom bootloader change or tested equivalent is required.

## Boot policy

Normal startup boots selected validated A or B. A new OTA image enters pending verification and must pass health checks before being marked valid; failed validation rolls back to the last known-good slot. If no bootable application remains, attempt Recovery. Manual recovery selection must override normal OTA choice. Recovery image is never written by standard application OTA, and USB service mode remains available if Wi-Fi is damaged.

## Acceptance gates

- Factory image A boots after fresh flash and full power removal; B is erased and Recovery separately boots.
- Manual recovery works with A and B erased/corrupt, with invalid OTA selection data, and across repeated resets.
- Lollipop-triggered recovery enters Recovery and can return to the previously selected application.
- Watchdog loops, interrupted OTA, bad signatures, power-loss mid-write, invalid configuration and broken Wi-Fi are tested.
- Recovery firmware, bootloader and application are built with compatible partition tables and secure boot/flash encryption policy.

**Status:** approved target architecture only. Dedicated GPIO, bootloader override, automatic failure fallback and hardware tests are not implemented or verified. Do not ship on the strength of this document alone.
