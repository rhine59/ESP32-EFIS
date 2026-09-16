# ESP32 EFIS — Preliminary power budget

**Status date:** 16 September 2026

This document records the preliminary electrical power/current budget for the ESP32 EFIS prototype. Values are **design estimates, not measured prototype results**. They must be replaced or supplemented with measured figures during hardware commissioning.

## Design summary

For the current single-display EFIS architecture, a reasonable preliminary expectation is approximately **250–350 mA from the 5 V rail in normal operation** with Wi-Fi inactive, or about **1.25–1.75 W**.

Wi-Fi activity, particularly OTA operation/transmission, can create substantially higher short-duration ESP32-S3 demand. The prototype therefore uses a **good regulated 5 V supply rated for at least 2 A**. This is intentional engineering margin and is **not** a prediction that the EFIS continuously consumes 2 A.

The final aircraft input stage should likewise not be tightly sized around the expected average consumption. A preliminary design allowance of **at least 1 A continuous capability from the nominal 12 V aircraft supply** leaves substantial margin for startup, converter losses, full backlight, Wi-Fi/OTA transients and future peripherals. Final converter/fuse/wiring choices require measured prototype data and aircraft electrical-system requirements.

## Preliminary 5 V budget

| Load | Preliminary 5 V input-equivalent allowance | Notes |
|---|---:|---|
| ESP32-S3-WROOM-1-N16R2 + PSRAM, active graphics | ~70–120 mA | Workload-dependent; excludes high Wi-Fi TX peaks. |
| Newhaven LCD logic | ~20–30 mA | Preliminary allowance pending measurement. |
| Newhaven backlight via TPS61169, 100% | ~130–145 mA | Display backlight is approximately 6 V / 100 mA; 5 V input figure includes a converter-loss allowance. |
| BMI088 | ~5–10 mA allowance | Measure with actual configured accel/gyro rates. |
| BMP585 | <2 mA allowance | Small relative to display/processor load. |
| RM3100 | ~5–15 mA allowance | Configuration-dependent; remote sensor. |
| MCP23008 + PEC09 encoder | ~1–3 mA allowance | Encoder itself is passive apart from pull-up current. |
| Miscellaneous conversion/control losses | ~20–40 mA | Preliminary system allowance. |
| **Expected normal total, Wi-Fi inactive** | **~250–350 mA @ 5 V** | **~1.25–1.75 W; to be measured.** |
| **Development/OTA transient design region** | **~500–700+ mA @ 5 V** | Not a continuous-consumption prediction. |

These values are deliberately approximate because the actual ESP32 clock/workload, display brightness, regulator efficiencies, sensor configurations and wiring will affect the result.

## Display/backlight significance

The selected Newhaven `NHD-2.1-480480AF-ASXP` has a backlight requirement of approximately **6.0 V / 100 mA** at the specified operating point. This is about **0.6 W delivered to the backlight**. Because the prototype starts from 5 V, the TPS61169 boosts the voltage and therefore draws more than 100 mA from the 5 V source at full brightness after conversion losses are included.

Backlight brightness is consequently one of the useful variables to measure. It is also likely to offer a meaningful reduction in normal power consumption when full daytime brightness is unnecessary.

## ESP32-S3 and Wi-Fi

Normal graphics/sensor operation and Wi-Fi/OTA operation must be treated separately in the power measurements. Wi-Fi transmission can cause short-duration current peaks well above the normal CPU/graphics demand.

The maintenance-only networking policy therefore has an electrical benefit as well as an operational one: normal instrument operation does not require continuous Wi-Fi activity. OTA tests must nevertheless verify that Wi-Fi/transmit/flash activity does not cause rail droop, display corruption, resets or sensor faults.

## Approximate aircraft-side consumption

For a first-order example only, if the completed EFIS consumes **1.5 W** and a 12 V → 5 V aircraft converter is **90% efficient**:

```text
Aircraft input current = 1.5 W / (12 V × 0.90)
                       ≈ 0.139 A
```

This suggests an eventual normal aircraft-side current of roughly **0.12–0.18 A** is plausible for the present architecture, with higher short-duration demand during maintenance/Wi-Fi activity.

This is **not yet a measured or validated aircraft current specification**. The final aircraft power design must use measured worst-case current, supply-voltage range, startup/inrush behaviour, wiring drop, converter temperature/derating, protection requirements and appropriate fuse/circuit protection.

## Prototype supply requirement

For bench development use:

- regulated **5 V DC**;
- **2 A minimum supply rating**;
- good-quality short USB-C/power wiring;
- common ground for processor, display/backlight and sensors;
- do not introduce the aircraft 12 V supply until the 5 V prototype is stable and instrumented.

A 2 A-rated source provides useful margin for development. It does not remove the need to check voltage at the electronics during worst-case load.

## Hardware commissioning measurements

Record current and rail voltage for at least these states:

| Test | Required observation |
|---|---|
| Power-on/inrush | Peak input current and minimum 5 V/3.3 V rail voltage. |
| Backlight off | Baseline processor/display-logic/sensor consumption. |
| Backlight 25% | Steady 5 V current/power. |
| Backlight 50% | Steady 5 V current/power. |
| Backlight 75% | Steady 5 V current/power. |
| Backlight 100% | Steady 5 V current/power and driver temperature. |
| Normal Horizon rendering | Current with normal renderer and all available sensors. |
| Altimeter/Compass pages | Confirm page rendering does not materially alter load. |
| Wi-Fi association/connection test | Peak and steady current; watch rail stability. |
| OTA download | Peak/average current while Wi-Fi and flash operations are active. |
| OTA activation/reboot | Startup transient and rail stability. |
| Sensor fault/disconnect tests | Confirm electrical faults do not destabilise common rails. |

Measurements should preferably include both average current and captured transient peaks. A slow USB power display alone may miss ESP32 Wi-Fi peaks; use suitable instrumentation if unexplained resets or rail disturbances appear.

## Acceptance before final aircraft power design

Do not freeze the aircraft DC/DC converter, input fuse/protection or final PCB power layout from this estimated budget alone. First establish measured:

1. maximum steady 5 V consumption at full backlight;
2. worst observed startup/Wi-Fi/OTA transient;
3. minimum stable 5 V and 3.3 V rails during that transient;
4. actual 12 V → 5 V converter efficiency across the aircraft supply range;
5. thermal performance in the enclosure;
6. adequate design margin after measurement.

The resulting measured figures become the authoritative power budget and should be recorded in this file with the test configuration and date.
