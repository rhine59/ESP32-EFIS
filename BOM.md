# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

**Procurement status updated:** 16 September 2026 from RS and DigiKey delivery paperwork and subsequent delivery-status updates supplied by the project owner. Supplier links remain purchasing aids; exact part number remains authoritative.

## Project stages

- **Stage 1 — Bench hardware / bring-up:** power, MCU, single display, controls and basic wiring required to begin physical development.
- **Stage 2 — Sensor + GNSS integration / instrument validation:** attitude, pressure, magnetic and GNSS sources; validate GPS latitude/longitude, fix/freshness and reported horizontal-accuracy handling as well as attitude/altitude/heading.
- **Stage 3 — Aircraft survey / measurements:** measure static system, installation clearances, remote magnetometer location/routing and GNSS antenna/receiver installation requirements.
- **Stage 4 — Physical interfaces / enclosure freeze:** optical window, static fittings, magnetometer harness, GNSS antenna/receiver interface, mounting and final enclosure details.
- **Stage 5 — Custom carrier PCB:** fabricate/populate the integrated carrier only after bench and physical interfaces are mature.
- **Stage 6 — Aircraft installation / validation:** final aircraft power protection, retained wiring/connectors, GNSS installation hardware, mounting hardware and installation-specific items.

## Purchasing status

| Item | Exact/reference choice | Stage | Needed | Received | Status |
|---|---|---|---:|---:|---|
| MCU module | **ESP32-S3-WROOM-1-N16R2** | 1 | 2 purchased (**1 installed + 1 spare**) | 2 | **RECEIVED** — DigiKey 5402-ESP32-S3-WROOM-1-N16R2CT-ND; prototype hosts one ESP32 only |
| Temporary MCU carrier/programmer | **Espressif ESP-Module-Prog-1** — manufacturer P/N `ESP-MODULE-PROG-1`; specifically the **Prog-1**, not Prog-1R. Solderless spring-pin carrier/programmer suitable for bench use with ESP32-S3-WROOM-1; exposes module signals for temporary development | 1 | 1 | 0 | **NEEDED — SOURCE IDENTIFIED:** Mouser UK # `356-ESPMODULEPROG1`, £9.79 ex VAT, 53 in stock when checked 16-Sep-2026. Alternate: DigiKey UK # `1965-ESP-MODULE-PROG-1-ND`, £9.76 ex VAT / £11.712 inc VAT, 51 in stock when checked. |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP**, one physical display | 1 | 1 | 0 | **ORDERED / IN TRANSIT** — project owner confirms display is on the way; mark RECEIVED only after physical arrival |
| Display bench adapter | **Newhaven NHD-FFC40** | 1 | 1 | 1 | **RECEIVED** — RS stock 723891 |
| Display FFC | 40-position 0.5 mm FFC/FPC, compatible orientation | 1 | 2 | 0 | **NEEDED — verify orientation/length** |
| Backlight driver | **Adafruit TPS61169 PID 6354** | 1 | 1 | 1 | **RECEIVED** — DigiKey 1528-6354-ND |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | 1 | 1 | 1 | **RECEIVED** |
| GPIO expander | **Microchip MCP23008-E/P** | 1 | 1 | 1 | **RECEIVED** |
| Bench PSU | **Korad KA3005P** preferred economical option; **Siglent SPD3303X-E** premium alternative | 1 | 1 | 0 | **NEEDED — choose one only** |
| Bench PSU lead kit | Banana leads plus croc/bare-wire/header/USB-C breakout as required | 1 | 1 set | 0 | **NEEDED unless already owned** |
| USB-C bench cable | Good-quality power/data cable | 1 | 1 | 0 | **NEEDED unless already owned** |
| Solderless breadboard | Full-size good-quality board | 1 | 1 | 0 | **NEEDED unless already owned** |
| Prototyping wire | 22–26 AWG solid-core assortment | 1 | 1 set | 0 | **NEEDED unless already owned** |
| Header pins | 2.54 mm breakaway male/female | 1 | 1 set | 0 | **NEEDED unless already owned** |
| Attitude IMU | **Bosch Shuttle Board 3.0 BMI088** | 2 | 1 | 1 | **RECEIVED** — DigiKey 828-SHUTTLEBOARD3.0BMI088-ND |
| BMI088 bench interposer | Verified **1.27 mm-pitch** mating solution | 2 | 1 | 0 | **NEEDED — verify connector first** |
| Pressure module | **Adafruit BMP585 Ported I2C PID 6413** | 2 | 1 | 0 | **NEEDED** |
| Pressure cable | STEMMA QT/Qwiic JST-SH 4-pin, 100–200 mm | 2 | 2 | 0 | **NEEDED** |
| QT breadboard adapter | **Adafruit PID 5961** or verified equivalent | 2 | 1 | 0 | **NEEDED** |
| Magnetic heading sensor | **PNI RM3100-CB P/N 14754** | 2 | 1 | 0 | **NEEDED** |
| GNSS receiver | Must report lat/lon, fix type/validity, freshness and explicit horizontal-accuracy estimate | 2 | 1 | 0 | **SELECTION REQUIRED before order** |
| GNSS bench antenna | Compatible with selected receiver | 2 | 1 | 0 | **BLOCKED by receiver selection** |

### Temporary ESP32-S3 carrier/programmer — exact purchasing reference

For the bare **ESP32-S3-WROOM-1-N16R2**, use **Espressif ESP-Module-Prog-1**. This replaces any generic or unspecified temporary breakout/carrier in the purchasing plan. It is preferable to an unverified third-party breakout because it provides a solderless module mounting arrangement for temporary bench development and can be used as a small development/programming board.

**Primary UK source:** Mouser UK — manufacturer part `ESP-MODULE-PROG-1`, Mouser part `356-ESPMODULEPROG1`. Checked 16-Sep-2026: **53 in stock, can dispatch immediately, £9.79 each ex VAT**.

**Alternate UK source:** DigiKey UK — manufacturer part `ESP-MODULE-PROG-1`, DigiKey part `1965-ESP-MODULE-PROG-1-ND`. Checked 16-Sep-2026: **51 in stock, £9.76 ex VAT / £11.712 inc VAT**.

Order **one only**. The Stage-1 prototype uses one of the two received ESP32-S3-WROOM-1-N16R2 modules; the second remains an untouched spare. Do **not** substitute `ESP-Module-Prog-1R` without rechecking its spring-pin layout against the module.

### Delivery evidence — 16 September 2026

RS paperwork confirms **NHD-FFC40**, RS stock 723891, quantity 1. DigiKey paperwork confirms **ESP32-S3-WROOM-1-N16R2 quantity 2**, **TPS61169 PID 6354 quantity 1**, **PEC09-2320F-T0015 quantity 1**, **MCP23008-E/P quantity 1**, and **Bosch Shuttle Board 3.0 BMI088 quantity 1**.

The project owner subsequently confirmed that the **Newhaven NHD-2.1-480480AF-ASXP display is on the way**. It is therefore recorded as **ORDERED / IN TRANSIT**, not yet RECEIVED.

## Stage 1 — immediate purchase/verification list

1. Await physical arrival of the **Newhaven NHD-2.1-480480AF-ASXP** and then mark it RECEIVED after inspection.
2. Buy the correct **40-position 0.5 mm FFC/FPC cable(s)** only after verifying contact orientation and length against the display and NHD-FFC40.
3. Buy **1 × Espressif ESP-Module-Prog-1**, preferably Mouser UK `356-ESPMODULEPROG1`; DigiKey UK `1965-ESP-MODULE-PROG-1-ND` is the identified alternate. The second N16R2 remains a spare.
4. Buy **one** current-limited bench PSU. Current preference: Korad KA3005P for the economical route; Siglent SPD3303X-E if the extra outputs/features are wanted.
5. Obtain PSU leads, USB-C cable, breadboard, prototype wire and headers where not already in the workshop.

Stage 1 gate: safe/current-limited 5 V power, programmable/mounted single MCU, working single-display connection/backlight and encoder/GPIO-expander bring-up.

## Stage 2 — immediate purchase/selection list

1. Verify and obtain the **1.27 mm mating adapter/interposer for the BMI088 Shuttle Board 3.0**; do not buy a guessed 2.54 mm adapter.
2. Buy **Adafruit BMP585 Ported I2C PID 6413**.
3. Buy **two STEMMA QT/Qwiic JST-SH cables** and **one PID 5961 QT breadboard adapter** (or verified equivalents).
4. Buy **PNI RM3100-CB P/N 14754**.
5. Select the **GNSS receiver** before purchasing it. It must expose an explicit horizontal-accuracy estimate in addition to position/fix/freshness; the adopted UI colour coding depends on this field.
6. Buy the **GNSS bench antenna only after receiver selection** establishes connector and active/passive requirements.

Stage 2 gate: validated BMI088 attitude, BMP585 pressure/altitude, RM3100 magnetic source and GNSS position/fix/freshness/accuracy handling, including independent fail-obvious source failures.

## Stage-specific items not yet ready to order

| Item | Stage | Prerequisite |
|---|---|---|
| Static-system survey materials / measurement aids | 3 | Identify existing static tube OD/ID, material, tee point, run length and panel clearance |
| RM3100 installation survey aids | 3 | Establish magnetically quiet location, cable length and routing |
| GNSS installation survey aids | 3 | Establish sky view, receiver/antenna location, RF/wiring route and interference environment |
| Front optical window | 4 | Freeze dimensions/specification after physical trial |
| Static tee/tubing/fittings/sealing hardware | 4 | Stage 3 static-system measurements and leak-test design |
| Final RM3100 cable/connector/gland/bracket | 4 | Stage 3 magnetic survey |
| Final GNSS antenna/cable/connector/gland/harness | 4 | Receiver selection and Stage 3 GNSS installation survey |
| Enclosure inserts/final mechanical fasteners | 4 | Physical enclosure/display/panel trial |
| **4-layer custom EFIS carrier PCB** | 5 | Display/sensor/control/power/GNSS interfaces validated |
| Final PCB production components/connectors | 5 | Frozen KiCad schematic/layout/BOM |
| Aircraft 12 V DC/DC, transient/reverse protection/filtering | 6 | Measured prototype power data and defined aircraft supply environment |
| Final aircraft wiring/connectors/circuit protection | 6 | Current, converter, routing and installation requirements validated |
| Final panel mounting hardware | 6 | Physical fit trial complete |

## Bench PSU reference

Only one bench PSU is required. **Korad KA3005P** was checked at £88.35 ex VAT / £106.02 inc VAT on 16-Sep-2026 and remains the preferred economical single-output option. **Siglent SPD3303X-E** was checked at £312 ex VAT / £374.40 inc VAT and remains the premium multi-output alternative. Recheck price and stock before purchase.

## Sensor/source status

| Function | Selected source | Status |
|---|---|---|
| Attitude | **Bosch BMI088** | Frozen; prototype Shuttle Board received |
| Static pressure / altitude | **Bosch BMP585**, initially Adafruit PID 6413 | Frozen sensor; module to purchase |
| Magnetic heading | **PNI RM3100-CB 14754**, remote mounted | Frozen; module to purchase |
| GNSS position / track / groundspeed | Receiver TBD; explicit position/fix/freshness/horizontal-accuracy reporting required | Functional requirement frozen; hardware selection open |

GNSS is independent of attitude, barometric altitude and magnetic heading. `TRK` and `GS` are GNSS-derived; `HDG` remains the heading solution and `IAS` is not derived from GNSS.

## Bench consumables / useful spares

These are Stage 1–2 consumables; buy as required rather than treating every line as mandatory before first power-up.

| Item | Qty | Notes |
|---|---:|---|
| 0.1 uF ceramic capacitors | 10 | General local decoupling/prototyping |
| 1 uF / 10 uF ceramic capacitors | 5 each | Bench power decoupling |
| 4.7 kOhm resistors | 10 | I2C/pull-up experiments; fit only where required |
| 10 kOhm resistors | 10 | Pull-up/down prototyping |
| Heat-shrink assortment | 1 | Bench loom protection/strain relief |
| Small cable ties/lacing | 1 pack | Bench cable management |
| M2/M2.5/M3 suitable non-magnetic/stainless hardware | 1 set | Keep ferrous material away from RM3100 during magnetic tests |

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible data must invalidate the relevant indication rather than freezing a plausible value. GNSS loss must not invalidate otherwise-valid attitude or magnetic heading, and GNSS validity must not imply those sources are valid.

See `docs/PROCUREMENT_STATUS_2026-09-16.md`, `docs/GNSS_DISPLAY.md`, `docs/POWER_BUDGET.md`, `docs/PROJECT_STATUS.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.
