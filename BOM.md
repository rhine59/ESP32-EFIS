# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

**Procurement status updated:** 21 September 2026 from RS, DigiKey and Mouser delivery-note/packaging photographs, subsequent delivery-status updates, The Pi Hut invoice evidence, and photographic confirmation of delivered parts. `RECEIVED` is used when arrival is confirmed by a supplied delivery-note photograph or other explicit physical-arrival confirmation.

## Procurement rules

1. Keep an explicit purchase source against every BOM line that is ready to buy.
2. Manufacturer/supplier part number is authoritative; do not substitute a similar-looking part without checking electrical and mechanical compatibility.
3. A delivery-note photograph that clearly identifies the part and quantity is sufficient evidence to change that quantity to **RECEIVED**.
4. An order confirmation, invoice, dispatch notice or statement that an item is on the way changes status to **ORDERED / IN TRANSIT**, not RECEIVED.
5. For generic workshop items, the listed supplier is a practical UK source rather than a frozen manufacturer choice.
6. Recheck price, stock, VAT and carriage immediately before purchase.

## Project stages

- **Stage 1 — Bench hardware / bring-up:** power, MCU, single display, controls and basic wiring required to begin physical development.
- **Stage 2 — Sensor + GNSS integration / instrument validation:** attitude, pressure, magnetic and GNSS sources; validate GPS latitude/longitude, fix/freshness and reported horizontal-accuracy handling as well as attitude/altitude/heading.
- **Stage 3 — Aircraft survey / measurements:** measure static system, installation clearances, remote magnetometer location/routing and GNSS antenna/receiver installation requirements.
- **Stage 4 — Physical interfaces / enclosure freeze:** optical window, static fittings, magnetometer harness, GNSS antenna/receiver interface, mounting and final enclosure details.
- **Stage 5 — Custom carrier PCB:** fabricate/populate the integrated carrier only after bench and physical interfaces are mature.
- **Stage 6 — Aircraft installation / validation:** final aircraft power protection, retained wiring/connectors, GNSS installation hardware, mounting hardware and installation-specific items.

## Purchasing status and sources

| Item | Exact/reference choice | Stage | Needed | Received | Status | Purchase source / reference |
|---|---|---:|---:|---:|---|---|
| MCU module | **ESP32-S3-WROOM-1-N16R2** | 1 | 2 | 2 | **RECEIVED — delivery-note photo confirmed** | DigiKey UK — `5407-ESP32-S3-WROOM-1-N16R2CT-ND` |
| Temporary MCU carrier/programmer | **Espressif ESP-Module-Prog-1**, specifically Prog-1 not Prog-1R | 1 | 1 | 0 | **NEEDED — source identified** | Preferred Mouser UK `356-ESPMODULEPROG1`; alternate DigiKey UK |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 1 | 1 | **RECEIVED — Mouser packaging/delivery document photo confirmed 21 Sep 2026** | Mouser P/N `763-2.1-480480AFASXP`; manufacturer P/N `NHD-2.1-480480AF-ASXP` |
| Display bench adapter | **Newhaven NHD-FFC40** | 1 | 1 | 1 | **RECEIVED — RS delivery-note photo confirmed** | RS UK stock `723-891` |
| Display interconnect | **Integral 40-way display flex tail into NHD-FFC40** | 1 | 1 | 1 | **RECEIVED / PHYSICALLY IDENTIFIED — no separate FFC required** | Supplied as part of Newhaven display; verify orientation/continuity before power |
| Backlight driver | **Adafruit TPS61169 PID 6354** | 1 | 1 | 1 | **RECEIVED** | DigiKey UK `1528-6354-ND` |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | 1 | 1 | 1 | **RECEIVED** | DigiKey UK `PEC09-2320F-T0015-ND` |
| GPIO expander | **Microchip MCP23008-E/P** | 1 | 1 | 1 | **RECEIVED** | DigiKey UK `MCP23008-E/P-ND` |
| Bench PSU | Current-limited regulated bench PSU suitable for prototype bring-up | 1 | 1 | 1 | **AVAILABLE / USER CONFIRMED 21 Sep 2026** | Already owned |
| Bench PSU lead kit | Banana leads plus croc/bare-wire/header leads | 1 | 1 set | 1 set | **AVAILABLE / USER CONFIRMED 21 Sep 2026** | Already owned |
| USB-C bench cable | Data + power USB-C cable | 1 | 1 | 0 | **NEEDED unless owned** | RS UK / CPC Farnell |
| Solderless breadboard | **Mounted full-size breadboard, aluminium plate & binding posts** | 1 | 1 | 1 | **RECEIVED — item photo confirmed 18 Sep 2026** | **The Pi Hut product `103521`, invoice `#1622980`**; item £7.00; order total £10.80 inc shipping/VAT |
| Prototyping wire | 22–26 AWG solid-core assortment | 1 | 1 set | 1 set | **AVAILABLE / USER CONFIRMED 21 Sep 2026** | Already owned |
| Header pins | 2.54 mm breakaway male/female | 1 | 1 set | 1 set | **AVAILABLE / USER CONFIRMED 21 Sep 2026** | Already owned |
| Attitude IMU | **Bosch Shuttle Board 3.0 BMI088** | 2 | 1 | 1 | **RECEIVED** | DigiKey UK `828-SHUTTLEBOARD3.0BMI088-ND` |
| BMI088 bench interposer | Verified **1.27 mm-pitch** mating solution | 2 | 1 | 0 | **NEEDED — verify connector** | Supplier/part to freeze after physical verification |
| Pressure module | **Adafruit BMP585 Ported I2C/SPI PID 6413** | 2 | 1 | 0 | **NEEDED** | DigiKey UK `1528-6413-ND`; The Pi Hut/Pimoroni alternate |
| Pressure cable | STEMMA QT/Qwiic JST-SH 4-pin, 100–200 mm | 2 | 2 | 0 | **NEEDED** | DigiKey / The Pi Hut / Pimoroni; PID 4397 candidate |
| QT breadboard adapter | **Adafruit PID 5961** | 2 | 1 | 0 | **NEEDED** | DigiKey UK `1528-5961-ND` |
| Magnetic heading sensor | **PNI RM3100-CB P/N 14754** | 2 | 1 | 0 | **NEEDED** | PNI Sensor direct SKU `14754` |
| GNSS receiver | Position/fix/freshness + explicit horizontal accuracy | 2 | 1 | 0 | **SELECTION REQUIRED** | Source after receiver selection |
| GNSS bench antenna | Compatible with selected receiver | 2 | 1 | 0 | **BLOCKED by receiver selection** | Select with receiver |

## Order / delivery evidence

### Received
RS and DigiKey delivery-note photographs confirm receipt of the NHD-FFC40, two ESP32-S3-WROOM-1-N16R2 modules, TPS61169 board, Bourns encoder, MCP23008 and BMI088 Shuttle Board. A photograph supplied on 18 September 2026 confirms physical receipt of The Pi Hut mounted full-size breadboard, product `103521`, quantity 1. Photographs supplied on 21 September 2026 confirm receipt of 1 × Newhaven `NHD-2.1-480480AF-ASXP` display from Mouser (Mouser P/N `763-2.1-480480AFASXP`, quantity 1).

### Ordered / in transit

No specifically tracked BOM item is currently recorded here as in transit.

## Stage 1 — immediate purchase/verification list

1. **Newhaven display and NHD-FFC40 received.** The display has an integral 40-way flex tail; no separate FFC cable is required. Verify connector orientation, pin numbering and continuity before applying power.
2. Buy 1 × **ESP-Module-Prog-1**, preferably Mouser UK `356-ESPMODULEPROG1`.
3. **Current-limited PSU, leads, headers, hookup wire and breadboard are available.**
4. Confirm a suitable USB-C data cable is available before MCU programming.

Stage 1 gate: safe/current-limited 5 V power, programmable/mounted single MCU, working single-display connection/backlight and encoder/GPIO-expander bring-up.

## Stage 2 — immediate purchase/selection list

1. Verify and obtain the 1.27 mm mating adapter/interposer for the BMI088 Shuttle Board 3.0.
2. Buy Adafruit BMP585 Ported I2C/SPI PID 6413.
3. Buy 2 × STEMMA QT/Qwiic JST-SH 4-pin cables, 100–200 mm.
4. Buy 1 × Adafruit PID 5961 QT breadboard adapter.
5. Buy 1 × PNI RM3100-CB P/N 14754.
6. Select the GNSS receiver, then its compatible bench antenna.

## Stage-specific items not yet ready to order

Stage 3+ aircraft static fittings, final RM3100 harness/mount, final GNSS installation hardware, optical window, final enclosure hardware, custom carrier PCB production, and aircraft 12 V input/protection hardware remain gated by bench validation and aircraft surveys.

## Bench consumables / useful spares

Useful bench stock: 0.1 uF, 1 uF and 10 uF ceramic capacitors; 4.7 kOhm and 10 kOhm resistors; heat-shrink; small cable ties/lacing; and suitable non-magnetic/stainless M2/M2.5/M3 hardware. Preferred general sources: DigiKey, Mouser, RS, CPC Farnell and Accu as appropriate.

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible data must invalidate the relevant indication rather than freezing a plausible value. GNSS loss must not invalidate otherwise-valid attitude or magnetic heading, and GNSS validity must not imply those sources are valid.

See `docs/PROCUREMENT_STATUS_2026-09-16.md`, `docs/GNSS_DISPLAY.md`, `docs/POWER_BUDGET.md`, `docs/PROJECT_STATUS.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.
