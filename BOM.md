# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

**Price/link check:** 16 September 2026. Supplier links are retained to make repeat purchasing easier; exact part number remains authoritative and price/stock must be rechecked before purchase.

## Project stages

The **Required by stage** column identifies the latest point at which an item is needed. This prevents later-stage aircraft/mechanical parts being bought before measurements and validation have fixed their requirements.

- **Stage 1 — Bench hardware / bring-up:** power, MCU, display, controls and basic wiring required to begin physical development.
- **Stage 2 — Sensor integration / instrument validation:** attitude, pressure and magnetic sensors and their bench interconnects; power measurement and fault/stale-data tests.
- **Stage 3 — Aircraft survey / measurements:** measure static system, installation clearances and remote magnetometer location/routing; generally no final installation hardware should be bought before this stage is complete.
- **Stage 4 — Physical interfaces / enclosure freeze:** optical window, static fittings, magnetometer harness/connector, mounting and final enclosure details.
- **Stage 5 — Custom carrier PCB:** fabricate/populate the integrated carrier only after the bench interfaces and physical interfaces are mature.
- **Stage 6 — Aircraft installation / validation:** final aircraft power protection, retained wiring/connectors, mounting hardware and installation-specific items after bench and installation requirements are validated.

## Purchasing status

| Item | Exact/reference choice | Required by stage | Qty needed | Qty ordered | Status | Supplier / web link | Reference cost |
|---|---|---|---:|---:|---|---|---:|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | **Stage 1** | 2 | 2 | **Ordered** | [DigiKey UK](https://www.digikey.co.uk/en/products/detail/espressif-systems/ESP32-S3-WROOM-1-N16R2/16162644) — ordered 14-Sep-2026 | Actual order record |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | **Stage 1** | 1 | 1 | **Ordered / shipped** | [Mouser UK search](https://www.mouser.co.uk/c/?q=NHD-2.1-480480AF-ASXP) — ordered 14-Sep-2026, shipped 15-Sep-2026 | £18.37 ex VAT merchandise |
| Display bench adapter | **Newhaven NHD-FFC40 breakout board** | **Stage 1** | 1 | 1 | **Ordered** | [RS UK search](https://uk.rs-online.com/web/c/?searchTerm=NHD-FFC40) | Actual order record |
| Display FFC | **40-position, 0.5 mm pitch FFC/FPC cable**, compatible orientation | **Stage 1** | 2 | 0 | **Needed** | [DigiKey UK FFC/FPC cable search](https://www.digikey.co.uk/en/products/filter/flat-flex-ribbon-jumper-cables/457) — verify orientation/length before ordering | TBD |
| Backlight driver | **Adafruit TPS61169 breakout, PID 6354** | **Stage 1** | 1 | 1 | **Ordered** | [Adafruit PID 6354](https://www.adafruit.com/product/6354) / DigiKey P/N 1528-6354-ND; ordered 14-Sep-2026 | Actual order record |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | **Stage 1** | 1 | 1 | **Ordered** | [DigiKey UK search](https://www.digikey.co.uk/en/products?keywords=PEC09-2320F-T0015) — ordered 14-Sep-2026 | Actual order record |
| Bench GPIO expander | **Microchip MCP23008-E/P** | **Stage 1** | 1 | 1 | **Ordered** | [DigiKey UK search](https://www.digikey.co.uk/en/products?keywords=MCP23008-E%2FP) — ordered 14-Sep-2026 | Actual order record |
| Bench PSU — preferred single-output option | **Korad KA3005P**, 0–30 V / 0–5 A programmable linear bench supply | **Stage 1** | 1 | 0 | **OPTION — Needed if selected** | [DigiKey UK KA3005P](https://www.digikey.co.uk/en/products/detail/sra-soldering-products/KA3005P/10709868) | **£88.35 ex VAT / £106.02 inc VAT** when checked |
| Bench PSU — multi-output option | **Siglent SPD3303X-E**, 2× 0–32 V / 3.2 A plus auxiliary output, 220 W | **Stage 1** | 1 | 0 | **OPTION — Needed if selected** | [Siglent UK SPD3303X-E](https://siglent.co.uk/product/siglent-spd3303x-e-2x-0-32v-3-2a-2-5v-3-3v-5-0v-3-2a-220w-programmable-dc-power-supply/) | **£312.00 ex VAT / £374.40 inc VAT** when checked |
| Bench PSU lead kit | 4 mm banana leads plus banana-to-crocodile, bare-wire/header and USB-C power breakout/adapters | **Stage 1** | 1 set | 0 | **Needed with bench PSU** | Buy from chosen PSU/test-equipment supplier; exact lead set not frozen | Allow ~£20–£40 |
| USB-C bench cable | Good-quality power/data cable suitable for EFIS 5 V bench feed | **Stage 1** | 1 | 0 | **Needed** | General test accessory; exact cable not frozen | Allow ~£5–£15 |
| Solderless breadboard | Good-quality full-size board | **Stage 1** | 1 | 0 | **Needed** | General prototype supplier; exact board not frozen | TBD |
| Prototyping wire | 22–26 AWG solid-core hookup wire assortment | **Stage 1** | 1 set | 0 | **Needed** | General prototype supplier; exact kit not frozen | TBD |
| Header pins | 2.54 mm breakaway male/female headers | **Stage 1** | 1 set | 0 | **Needed** | General prototype supplier; exact kit not frozen | TBD |
| Attitude IMU | **Bosch SHUTTLE BOARD 3.0 BMI088** | **Stage 2** | 1 | 1 | **Ordered** | [DigiKey UK product family](https://www.digikey.co.uk/en/products/filter/evaluation-boards/expansion-boards-daughter-cards/797) — P/N 828-SHUTTLEBOARD3.0BMI088-ND; ordered 14-Sep-2026 | Actual order record |
| Pressure module | **Adafruit BMP585 Ported I2C breakout, PID 6413** | **Stage 2** | 1 | 0 | **Needed** | [Adafruit PID 6413](https://www.adafruit.com/product/6413) | Recheck before order |
| Pressure-sensor cable | **STEMMA QT / Qwiic JST-SH 4-pin cable**, 100–200 mm | **Stage 2** | 2 | 0 | **Needed** | [Adafruit STEMMA QT cables](https://www.adafruit.com/search?q=STEMMA+QT+cable) | TBD |
| QT breadboard adapter | **Adafruit Qwiic / STEMMA QT breakout PID 5961** or equivalent | **Stage 2** | 1 | 0 | **Needed** | [Adafruit PID 5961](https://www.adafruit.com/product/5961) | TBD |
| Magnetic heading sensor | **PNI RM3100-CB, P/N 14754** | **Stage 2** | 1 | 0 | **Needed** | [Solsta UK RM3100-CB](https://solsta.co.uk/product/pni-corporation-rm3100-cb-magnetometer-board/) | Recheck before order |

The procurement status records only purchases explicitly confirmed for this project. Do not substitute a superficially similar part from a supplier link: match the exact/reference choice in the second column.

## Stage-specific items not yet ready to order

These later-stage items are deliberately recorded now so they are not forgotten, but their exact specification or quantity must not be guessed before the prerequisite measurements/tests.

| Item | Required by stage | Current state / prerequisite |
|---|---|---|
| Static-system survey materials / temporary measurement aids | **Stage 3** | Only as needed to identify existing Skyranger tube OD/ID, material, tee point, run length and panel clearance. |
| RM3100 installation survey / temporary non-magnetic mounting aids | **Stage 3** | Establish magnetically quiet location, cable length and routing before freezing connector/harness. |
| Front optical window | **Stage 4** | Target 62 mm × 2 mm hard-coated anti-reflective polycarbonate; supplier/order specification still to freeze. |
| Static tee, tubing, barbed/bulkhead fitting and sealing hardware | **Stage 4** | **Do not order yet** — dependent on Stage 3 aircraft static-system measurements and leak-test design. |
| Final RM3100 cable, connector/gland and non-magnetic mounting bracket | **Stage 4** | **Do not order yet** — dependent on Stage 3 magnetic-location/routing survey. |
| Enclosure inserts / final mechanical fasteners | **Stage 4** | Exact insert/fastener dimensions to be verified against physical enclosure/display/panel trial. |
| **4-layer custom ESP32-S3 EFIS carrier PCB** | **Stage 5** | PCB remains parked until display/sensor/control/power interfaces and physical installation interfaces are validated. Obtain prototype fabrication/assembly quotes when released. |
| Final PCB production components/connectors | **Stage 5** | Generate from frozen KiCad BOM after schematic/layout review; do not substitute bench modules blindly into production BOM. |
| Aircraft 12 V input DC/DC converter, transient/reverse-polarity protection and filtering | **Stage 6** | **Do not freeze/order yet** — use measured `docs/POWER_BUDGET.md` data and defined aircraft supply environment first. |
| Final aircraft power/data wiring, retained connectors, fuse/circuit protection | **Stage 6** | Size/specify after current, converter, routing and installation requirements are validated. |
| Final panel mounting hardware | **Stage 6** | Confirm after physical fit trial; use appropriate secure locking/retention method. |

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
3. confirm the item is actually due for the current/next project stage;
4. recheck stock and VAT-inclusive price;
5. update Qty ordered and Status in this BOM;
6. retain supplier/order detail for traceability.

## BMI088 bench connection — verify before purchase

The Bosch BMI088 Shuttle Board 3.0 exposes its connections on **1.27 mm pitch**. Do not buy a guessed generic 2.54 mm adapter. Obtain either the mating Bosch/Application-Board-compatible socket arrangement or a verified 1.27 mm breakout/interposer after checking the actual supplied shuttle board.

## Sensors frozen for the EFIS

| Function | Selected source | Status |
|---|---|---|
| Attitude | **Bosch BMI088** | Frozen |
| Static pressure / altitude | **Bosch BMP585**, initially Adafruit ported PID 6413 | Frozen sensor; final physical implementation pending testing |
| Magnetic heading | **PNI RM3100-CB 14754**, remote mounted | Frozen |

## Bench consumables / useful spares

These are **Stage 1–2** consumables; buy as required rather than treating every line as mandatory before first power-up.

| Item | Qty | Notes |
|---|---:|---|
| 0.1 uF ceramic capacitors | 10 | General local decoupling/prototyping |
| 1 uF / 10 uF ceramic capacitors | 5 each | Bench power decoupling |
| 4.7 kOhm resistors | 10 | I2C/pull-up experiments; only fit where required |
| 10 kOhm resistors | 10 | Pull-up/down prototyping |
| Heat-shrink assortment | 1 | Bench loom protection/strain relief |
| Small cable ties / lacing | 1 pack | Bench cable management |
| M2/M2.5/M3 non-magnetic or suitable stainless hardware assortment | 1 set | Prototype mounting; keep ferrous material away from RM3100 during magnetic tests |

## Purchase sequence / gates

**Stage 1 — bench hardware / bring-up:** obtain the processor, display/adapter/FFC, backlight driver, encoder/GPIO-expander, one current-limited bench PSU and basic bench interconnect materials. Gate to Stage 2: stable controlled power and display/control bring-up.

**Stage 2 — sensor integration / instrument validation:** integrate BMI088, BMP585 and RM3100; develop/validate AHRS, altimeter and compass behavior; measure power; exercise missing/stale/implausible-data behavior. Gate to Stage 3: interfaces and instrument software sufficiently stable for installation surveys to be meaningful.

**Stage 3 — aircraft survey / measurements:** measure static plumbing, available panel/enclosure space and remote magnetometer location/cable routing. This stage exists specifically to avoid buying guessed installation hardware.

**Stage 4 — physical interfaces / enclosure freeze:** use Stage 3 results to select static fittings, magnetometer harness/connector, optical window and final mechanical details. Gate to Stage 5: physical interfaces frozen enough to commit connector positions and mechanical constraints to PCB/enclosure design.

**Stage 5 — custom carrier PCB:** complete/review KiCad schematic and 4-layer layout, generate fabrication/assembly BOM and order a small prototype batch only after the preceding interfaces are validated. Gate to Stage 6: populated PCB passes bench functional, electrical, thermal, fault and power tests.

**Stage 6 — aircraft installation / validation:** specify aircraft input protection/conversion, wiring, circuit protection and final mounting from measured prototype data and the actual aircraft installation. Installation does not change the project's supplementary/non-primary status.

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible sensor data must invalidate the relevant indication rather than freezing a plausible value.

See `docs/POWER_BUDGET.md`, `docs/PROJECT_STATUS.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.
