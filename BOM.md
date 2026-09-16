# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

**Price/link check:** 16 September 2026. Supplier links are retained to make repeat purchasing easier; exact part number remains authoritative and price/stock must be rechecked before purchase.

## Purchasing status

| Item | Exact/reference choice | Qty needed | Qty ordered | Status | Supplier / web link | Reference cost |
|---|---|---:|---:|---|---|---:|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | 2 | 2 | **Ordered** | [DigiKey UK](https://www.digikey.co.uk/en/products/detail/espressif-systems/ESP32-S3-WROOM-1-N16R2/16162644) — ordered 14-Sep-2026 | Actual order record |
| Attitude IMU | **Bosch SHUTTLE BOARD 3.0 BMI088** | 1 | 1 | **Ordered** | [DigiKey UK search/product family](https://www.digikey.co.uk/en/products/filter/evaluation-boards/expansion-boards-daughter-cards/797) — P/N 828-SHUTTLEBOARD3.0BMI088-ND; ordered 14-Sep-2026 | Actual order record |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 1 | **Ordered / shipped** | [Mouser UK search](https://www.mouser.co.uk/c/?q=NHD-2.1-480480AF-ASXP) — ordered 14-Sep-2026, shipped 15-Sep-2026 | £18.37 ex VAT merchandise |
| Display bench adapter | **Newhaven NHD-FFC40 breakout board** | 1 | 1 | **Ordered** | [RS UK search](https://uk.rs-online.com/web/c/?searchTerm=NHD-FFC40) | Actual order record |
| Display FFC | **40-position, 0.5 mm pitch FFC/FPC cable**, compatible orientation | 2 | 0 | **Needed** | [DigiKey UK FFC/FPC cable search](https://www.digikey.co.uk/en/products/filter/flat-flex-ribbon-jumper-cables/457) — verify orientation/length before ordering | TBD |
| Backlight driver | **Adafruit TPS61169 breakout, PID 6354** | 1 | 1 | **Ordered** | [Adafruit PID 6354](https://www.adafruit.com/product/6354) / DigiKey P/N 1528-6354-ND; ordered 14-Sep-2026 | Actual order record |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | 1 | 1 | **Ordered** | [DigiKey UK search](https://www.digikey.co.uk/en/products?keywords=PEC09-2320F-T0015) — ordered 14-Sep-2026 | Actual order record |
| Bench GPIO expander | **Microchip MCP23008-E/P** | 1 | 1 | **Ordered** | [DigiKey UK search](https://www.digikey.co.uk/en/products?keywords=MCP23008-E%2FP) — ordered 14-Sep-2026 | Actual order record |
| Pressure module | **Adafruit BMP585 Ported I2C breakout, PID 6413** | 1 | 0 | **Needed** | [Adafruit PID 6413](https://www.adafruit.com/product/6413) | Recheck before order |
| Pressure-sensor cable | **STEMMA QT / Qwiic JST-SH 4-pin cable**, 100–200 mm | 2 | 0 | **Needed** | [Adafruit STEMMA QT cables](https://www.adafruit.com/search?q=STEMMA+QT+cable) | TBD |
| QT breadboard adapter | **Adafruit Qwiic / STEMMA QT breakout PID 5961** or equivalent | 1 | 0 | **Needed** | [Adafruit PID 5961](https://www.adafruit.com/product/5961) | TBD |
| Magnetic heading sensor | **PNI RM3100-CB, P/N 14754** | 1 | 0 | **Needed** | [Solsta UK RM3100-CB](https://solsta.co.uk/product/pni-corporation-rm3100-cb-magnetometer-board/) | Recheck before order |
| Bench PSU — preferred single-output option | **Korad KA3005P**, 0–30 V / 0–5 A programmable linear bench supply | 1 | 0 | **OPTION — Needed if selected** | [DigiKey UK KA3005P](https://www.digikey.co.uk/en/products/detail/sra-soldering-products/KA3005P/10709868) | **£88.35 ex VAT / £106.02 inc VAT** when checked |
| Bench PSU — multi-output option | **Siglent SPD3303X-E**, 2× 0–32 V / 3.2 A plus auxiliary output, 220 W | 1 | 0 | **OPTION — Needed if selected** | [Siglent UK SPD3303X-E](https://siglent.co.uk/product/siglent-spd3303x-e-2x-0-32v-3-2a-2-5v-3-3v-5-0v-3-2a-220w-programmable-dc-power-supply/) | **£312.00 ex VAT / £374.40 inc VAT** when checked |
| Bench PSU lead kit | 4 mm banana leads plus banana-to-crocodile, bare-wire/header and USB-C power breakout/adapters | 1 set | 0 | **Needed with bench PSU** | Buy from chosen PSU/test-equipment supplier; exact lead set not frozen | Allow ~£20–£40 |
| USB-C bench cable | Good-quality power/data cable suitable for EFIS 5 V bench feed | 1 | 0 | **Needed** | General test accessory; exact cable not frozen | Allow ~£5–£15 |
| Solderless breadboard | Good-quality full-size board | 1 | 0 | **Needed** | General prototype supplier; exact board not frozen | TBD |
| Prototyping wire | 22–26 AWG solid-core hookup wire assortment | 1 set | 0 | **Needed** | General prototype supplier; exact kit not frozen | TBD |
| Header pins | 2.54 mm breakaway male/female headers | 1 set | 0 | **Needed** | General prototype supplier; exact kit not frozen | TBD |

The procurement status records only purchases explicitly confirmed for this project. Do not substitute a superficially similar part from a supplier link: match the exact/reference choice in the second column.

## Bench power supply options — suppliers and cost

Only **one** bench PSU is required.

### Option A — Korad KA3005P

**Purchase link:** [DigiKey UK — KA3005P](https://www.digikey.co.uk/en/products/detail/sra-soldering-products/KA3005P/10709868)  
**Reference price checked 16-Sep-2026:** **£88.35 ex VAT / £106.02 inc VAT**.

This is the preferred economical choice: single output, 0–30 V DC, 0–5 A with adjustable voltage/current limiting. It is sufficient for normal EFIS development because the complete prototype should ordinarily be powered from one controlled input while its own regulation creates internal rails.

### Option B — Siglent SPD3303X-E

**Purchase link:** [Siglent UK — SPD3303X-E](https://siglent.co.uk/product/siglent-spd3303x-e-2x-0-32v-3-2a-2-5v-3-3v-5-0v-3-2a-220w-programmable-dc-power-supply/)  
**Reference price checked 16-Sep-2026:** **£312.00 ex VAT / £374.40 inc VAT**.

This is the premium multi-output alternative and permits several independent rails/subassemblies to be powered simultaneously.

## Core prototype reference

The exact/reference part numbers in the purchasing table above are authoritative. Supplier links are conveniences and may change. Before any new order:

1. confirm the manufacturer part number;
2. confirm electrical/mechanical variant;
3. recheck stock and VAT-inclusive price;
4. update Qty ordered and Status in this BOM;
5. retain the supplier/order detail for traceability.

## BMI088 bench connection — verify before purchase

The Bosch BMI088 Shuttle Board 3.0 exposes its connections on **1.27 mm pitch**. Do not buy a guessed generic 2.54 mm adapter. Obtain either the mating Bosch/Application-Board-compatible socket arrangement or a verified 1.27 mm breakout/interposer after checking the actual supplied shuttle board.

## Sensors frozen for the EFIS

| Function | Selected source | Status |
|---|---|---|
| Attitude | **Bosch BMI088** | Frozen |
| Static pressure / altitude | **Bosch BMP585**, initially Adafruit ported PID 6413 | Frozen sensor; final physical implementation pending testing |
| Magnetic heading | **PNI RM3100-CB 14754**, remote mounted | Frozen |

## Bench consumables / useful spares

| Item | Qty | Notes |
|---|---:|---|
| 0.1 uF ceramic capacitors | 10 | General local decoupling/prototyping |
| 1 uF / 10 uF ceramic capacitors | 5 each | Bench power decoupling |
| 4.7 kOhm resistors | 10 | I2C/pull-up experiments; only fit where required |
| 10 kOhm resistors | 10 | Pull-up/down prototyping |
| Heat-shrink assortment | 1 | Bench loom protection/strain relief |
| Small cable ties / lacing | 1 pack | Bench cable management |
| M2/M2.5/M3 non-magnetic or suitable stainless hardware assortment | 1 set | Prototype mounting; keep ferrous material away from RM3100 during magnetic tests |

## Already designed but do not order/fabricate yet

| Item | Reason to wait |
|---|---|
| **68 mm custom ESP32-S3 carrier PCB** | PCB design is deliberately parked until sensor connectors and physical installation interfaces are mature. |
| Bare **BMP585** for final PCB | The ported development board is the correct first article. Decide bare sensor + sealed plenum versus retained remote/ported module after static tests. |
| Final RM3100 cable/connector | Cable length, routing and connector type depend on the actual Skyranger installation and EMC tests. |
| Aircraft 12 V input converter/protection | USB/bench 5 V is the development baseline. Aircraft supply protection/filtering is a separate design task before installation. |

## Purchase sequence

**Stage 1 — buy/procure core bench hardware:** display + FFC adapter/cables, BMI088, BMP585 ported module + QT cables/breakout, RM3100-CB, TPS61169, PEC09, MCP23008, one suitable current-limited bench PSU, banana/adaptor leads and normal bench materials.

**Stage 2 — bench integration:** prove display, controls, BMI088, pressure and magnetic sensor interfaces; develop AHRS/altimeter/compass firmware; test invalid/stale-data behavior; record measured power consumption in `docs/POWER_BUDGET.md`.

**Stage 3 — aircraft measurements:** measure static plumbing and survey remote magnetometer location/cable routing.

**Stage 4 — freeze physical interfaces:** choose static fitting, magnetometer connector/harness, optical window hardware and final mounting details; update enclosure accordingly.

**Stage 5 — custom carrier PCB:** resume PCB design only after the physical interfaces above are frozen.

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible sensor data must invalidate the relevant indication rather than freezing a plausible value.

See `docs/POWER_BUDGET.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.
