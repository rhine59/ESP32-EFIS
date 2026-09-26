# EFIS Electrical Power-On Self-Test (POST) and Test Harness

**Status:** STAGED DESIGN — 26 September 2026  
**Role:** supplementary/non-primary flight-development instrument.

## Requirement

The EFIS firmware shall provide a complete electrical/component test harness that can be selected at boot. It shall exercise every component/interface for which a meaningful automated test is possible, display an unambiguous **PASS / FAIL / NOT TESTED** result, and report stable documented failure codes.

The harness is a maintenance/commissioning facility. A successful POST does **not** establish airworthiness and does not replace electrical, environmental, vibration, installation or airborne validation.

## Boot modes

Normal boot remains the default. A deliberate boot gesture/service command shall enter **FULL TEST** before normal instrument operation. The exact gesture is to be frozen after the physical encoder is validated.

FULL TEST shall:
1. identify firmware/build and hardware revision;
2. run tests in a deterministic order;
3. show the test currently running;
4. retain all failures rather than stopping at the first failure where safe;
5. finish with overall PASS or FAIL and a list of failure codes;
6. make results available to the service/debug interface;
7. permit safe re-run without rewriting calibration or operational settings.

A short automatic POST may later run on every normal boot. Destructive/stress tests belong only in FULL TEST.

## Failure-code format

Codes use `ECCC-NN`:

- `E` = electrical/component test failure;
- `CCC` = subsystem;
- `NN` = specific failure.

Subsystems:

| Prefix | Subsystem |
|---|---|
| PWR | power / rails |
| MCU | ESP32 / memory / reset |
| DSP | display / RGB interface |
| BKL | backlight |
| CTL | encoder / MCP23008 / controls |
| IMU | BMI088 |
| BAR | BMP585 / static pressure |
| MAG | RM3100 magnetometer |
| GNS | GNSS |
| USB | USB-C / service interface |
| DAT | external avionics data interface |
| NVS | non-volatile storage |
| OTA | OTA partitions / boot state |
| NET | Wi-Fi/network maintenance interface |
| TMP | thermal/temperature monitoring |

## Initial failure-code register

| Code | Meaning | Initial diagnostic action |
|---|---|---|
| EPWR-01 | required input supply outside permitted range | verify source, connector and protection stage |
| EPWR-02 | 5 V rail outside tolerance | inspect DC/DC stage/load |
| EPWR-03 | 3.3 V rail outside tolerance | inspect regulator/load/short |
| EMCU-01 | ESP32 internal startup/self-test failure | capture reset reason/log |
| EMCU-02 | PSRAM unavailable or memory test failed | verify exact module/configuration |
| EMCU-03 | flash read/integrity test failed | verify flash/image |
| EDSP-01 | display controller initialization failed | verify FFC/orientation/init bus |
| EDSP-02 | RGB/display timing test failed or no expected response where detectable | verify RGB/timing/power |
| EBKL-01 | backlight control test failed | verify TPS61169/control path |
| ECTL-01 | MCP23008 not detected | verify I2C/power/address |
| ECTL-02 | encoder input test failed | verify encoder/wiring/GPIO expander |
| EIMU-01 | BMI088 accelerometer not detected | verify SPI/power/CS |
| EIMU-02 | BMI088 gyroscope not detected | verify SPI/power/CS |
| EIMU-03 | BMI088 identity/configuration invalid | verify device/configuration |
| EIMU-04 | BMI088 data implausible/stuck during test | inspect sensor/mount/interface |
| EBAR-01 | BMP585 not detected | verify I2C/power/cable |
| EBAR-02 | BMP585 identity/configuration invalid | verify device/configuration |
| EBAR-03 | pressure/temperature reading implausible | inspect sensor/static plumbing |
| EMAG-01 | RM3100 not detected | verify remote sensor/interface |
| EMAG-02 | magnetic sensor data implausible/stuck | inspect sensor/cable/interference |
| EGNS-01 | configured GNSS device not detected | verify selected GNSS/interface |
| EGNS-02 | GNSS data stream malformed/unsupported | verify protocol/baud/USB driver |
| EGNS-03 | GNSS present but no fix | informational/environmental failure; check antenna/view of sky |
| EUSB-01 | USB service interface initialization failed | verify USB PHY/connector/config |
| EDAT-01 | RS-232 avionics interface self-test failed | verify transceiver/UART |
| EDAT-02 | RS-485 interface self-test failed (if fitted) | verify transceiver/UART |
| EDAT-03 | CAN interface self-test failed (if fitted) | verify transceiver/controller |
| ENVS-01 | NVS read/write scratch test failed | inspect flash/NVS partition |
| ENVS-02 | configuration CRC/schema invalid | recover defaults only with explicit maintenance action |
| EOTA-01 | OTA partition table/state invalid | inspect partition table/otadata |
| EOTA-02 | active image integrity/version metadata invalid | service firmware |
| ENET-01 | Wi-Fi hardware/driver initialization failed | inspect firmware/radio state |
| ETMP-01 | monitored temperature outside test limit | stop stress test and inspect thermal condition |

## Testability rules

A test must distinguish **component failure** from **test unavailable**. For example, lack of satellites must not be reported as a failed GNSS receiver if valid GNSS messages are being received; it is a no-fix/environmental condition. Optional/unfitted hardware reports NOT FITTED/NOT TESTED rather than FAIL.

Where practical, production PCB design should add testability features: rail sensing/test points, loopback capability for protected serial interfaces, device identity reads, and safe diagnostic hooks. No test mode may drive an aircraft-connected line into an unsafe state.

Display and backlight tests require human-visible patterns/brightness steps in addition to any electrical checks because the ESP32 cannot prove correct pixels merely by successfully writing the interface.

## Result presentation

Example:

```text
EFIS FULL ELECTRICAL TEST
HW: Rev A     FW: 0.x.x

PWR  PASS
MCU  PASS
DSP  PASS / VISUAL CHECK REQUIRED
BKL  PASS / VISUAL CHECK REQUIRED
CTL  PASS
IMU  FAIL   EIMU-02
BAR  PASS
MAG  NOT FITTED
GNS  PASS   NO FIX
USB  PASS
DAT  NOT FITTED
NVS  PASS
OTA  PASS

OVERALL: FAIL
FAILURES: EIMU-02
```

The final screen remains displayed until acknowledged and the full structured result should also be emitted over the service/debug interface.

## Implementation stages

1. **Stage A:** software harness framework, result model, code registry, simulated pass/fail tests.
2. **Stage B:** Phase-1 hardware tests for MCU/flash/PSRAM/display/backlight/MCP23008/encoder.
3. **Stage C:** BMI088 and BMP585 tests.
4. **Stage D:** RM3100 and selected GNSS tests.
5. **Stage E:** production power sensing and protected avionics-interface loopback tests.
6. **Stage F:** regression harness and manufacturing/maintenance test procedure.

Every implemented test requires both a known-good PASS case and an injected/realistic FAIL case before being marked validated.


## Persistent runtime fault history

The electrical test code registry also provides stable identifiers for faults detected during normal operation where applicable. Runtime hardware/software faults are persisted in a bounded, wear-conscious non-volatile fault log and reviewed from **FAULT LOG** on the rotary boot menu.

Store fault transitions/significant events rather than continuously rewriting the same active fault. Entries retain fault code, subsystem/source, severity, occurrence count, firmware/build identity and non-secret diagnostic context. Add trustworthy timestamps only when a valid time source exists; do not invent a wall-clock time when it does not. Credentials are prohibited from the log.

The boot viewer must allow scrolling through entries, viewing details and deliberately clearing the log with confirmation. Power cycling, normal boot and firmware update do not silently erase fault history. Persistent logging supplements, but never delays or replaces, immediate fail-obvious runtime annunciation.
