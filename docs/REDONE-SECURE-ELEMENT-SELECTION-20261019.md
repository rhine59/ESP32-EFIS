# RedOne secure-element evaluation — 19 October 2026

**Status:** candidate comparison for a separate test board, NOT an approved production BOM or hardware provisioning. Physical Partition B remains **NO-GO**.

## Candidates and evidence

| Candidate | Monotonic capability | Evaluation decision |
| --- | --- | --- |
| Microchip ATECC608B | Two hardware monotonic counters, each documented with maximum 2,097,151; an interrupted increment can skip a count | Useful counter prototype, but Microchip marks the base ATECC608B **not recommended for new designs**. Check supported successor, configuration, availability and authenticatable read path before any BOM choice. |
| NXP EdgeLock SE050 | Secure-object monotonic counter creation/management in the IoT applet; I2C host interface | **Preferred evaluation candidate**, subject to actual part variant, counter ACLs, authentication, secure-channel provisioning, update endurance and power-failure evidence. No hardware guarantee has been tested. |

Sources:
- Microchip ATECC608B product: https://www.microchip.com/en-us/product/ATECC608B
- Microchip monotonic counter command: https://onlinedocs.microchip.com/oxy/GUID-0D9D3905-C601-42C6-96F8-E8127F9AD3FA-en-US-1/GUID-EABA157C-F433-421D-ADC3-EC4B495E96FB.html
- NXP SE050 datasheet: https://www.nxp.com/docs/en/data-sheet/SE050-DATASHEET.pdf
- NXP SE050 APDU specification: https://www.nxp.com/docs/en/application-note/AN12413.pdf

## Engineering choice and version mapping

The published build number is an int32 and may jump (the current staged review uses `20261019`). **Do not increment a hardware counter millions of times to match a build number.** Instead keep an authenticated binding between a monotonic counter *generation* and a signed build floor, with a crash-consistent update protocol. Neither an ordinary NVS mapping nor a phone-supplied value is sufficient. A concrete authenticated binding scheme, recovery policy and test vectors must be designed and reviewed before the C backend is enabled.

Counter increments may be skipped on power loss. Treat the actual observed counter as authoritative; do not assume exact `+1`. After any ambiguous response, require a fresh authenticated read, reconcile the bound release record, and refuse further installation if the mapping is missing or inconsistent.

## Test-board interface (provisional)

- ESP32-S3 **3.3 V I2C** controller to SE050 SDA/SCL, shared ground, appropriately sized pull-ups to 3.3 V, and supply decoupling per the selected module schematic.
- Assign GPIOs only after checking the RedOne pin allocation and avoiding strapping, USB, flash, PSRAM and display/sensor conflicts. No GPIO assignments are approved yet.
- Prefer a vendor evaluation board or breakout for first tests; confirm level shifting and power domain before connecting. Do not attach to the existing RedOne.
- Test cold boot, disconnected bus, stuck SDA, bad response MAC, nonce replay, wrong identity, interrupted update, exhausted counter, corrupted binding, missing recovery and simultaneous reset.
- Do not provision permanent keys or lock device configuration during the first functional tests. Use disposable test identities, isolated test keys and explicit irreversible-operation approval later.

## Required deliverables before enabling a provider

1. Exact orderable part and vendor-supported SDK, configuration and monotonic counter ACL evidence.
2. Protocol design for authenticated fresh counter reads and non-replayable build-floor binding.
3. Host model and dedicated-board power-cut matrix demonstrating no downgrade or recovery lockout.
4. Verified factory recovery compatibility and separate security-epoch policy.
5. Reviewed ESP-IDF provider implementation with default-deny behavior; signed image verification remains a separate gate.

**Current implementation:** no SE050 or ATECC provider is wired into `redone_floor_backend_t`. Simulations and host checks cannot authorise physical firmware transfer, boot selection, flash changes or eFuse writes.
