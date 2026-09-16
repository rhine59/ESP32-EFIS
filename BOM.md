# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

**Price/link check:** 16 September 2026. Supplier links are retained to make repeat purchasing easier; exact part number remains authoritative and price/stock must be rechecked before purchase.

## Project stages

The **Required by stage** column identifies the latest point at which an item is needed. This prevents later-stage aircraft/mechanical parts being bought before measurements and validation have fixed their requirements.

- **Stage 1 — Bench hardware / bring-up:** power, MCU, single display, controls and basic wiring required to begin physical development.
- **Stage 2 — Sensor + GNSS integration / instrument validation:** attitude, pressure, magnetic and GNSS sources; validate GPS latitude/longitude, fix/freshness and reported horizontal-accuracy handling as well as attitude/altitude/heading.
- **Stage 3 — Aircraft survey / measurements:** measure static system, installation clearances, remote magnetometer location/routing and GNSS antenna/receiver installation requirements; generally no final installation hardware should be bought before this stage is complete.
- **Stage 4 — Physical interfaces / enclosure freeze:** optical window, static fittings, magnetometer harness, GNSS antenna/receiver interface, mounting and final enclosure details.
- **Stage 5 — Custom carrier PCB:** fabricate/populate the integrated carrier only after the bench interfaces and physical interfaces are mature.
- **Stage 6 — Aircraft installation / validation:** final aircraft power protection, retained wiring/connectors, GNSS installation hardware, mounting hardware and installation-specific items after bench and installation requirements are validated.

## Purchasing status

| Item | Exact/reference choice | Required by stage | Qty needed | Qty ordered | Status | Supplier / web link | Reference cost |
|---|---|---|---:|---:|---|---|---:|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | **Stage 1** | 2 | 2 | **Ordered** | [DigiKey UK](https://www.digikey.co.uk/en/products/detail/espressif-systems/ESP32-S3-WROOM-1-N16R2/16162644) — ordered 14-Sep-2026 | Actual order record |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** — **one physical display** | **Stage 1** | 1 | 1 | **Ordered / shipped** | [Mouser UK search](https://www.mouser.co.uk/c/?q=NHD-2.1-480480AF-ASXP) — ordered 14-Sep-2026, shipped 15-Sep-2026 | £18.37 ex VAT merchandise |
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
| GNSS receiver | **GNSS module/receiver capable of latitude, longitude, fix type, freshness and explicit horizontal-accuracy estimate** | **Stage 2** | 1 | 0 | **SELECTION REQUIRED before order** | Supplier/link intentionally not frozen until electrical interface, protocol, update rate and antenna arrangement are selected | TBD |
| GNSS bench antenna | Antenna compatible with selected GNSS receiver; active/passive choice depends on receiver | **Stage 2** | 1 | 0 | **BLOCKED by GNSS receiver selection** | Do not order until receiver RF interface is known | TBD |

The procurement status records only purchases explicitly confirmed for this project. Do not substitute a superficially similar part from a supplier link: match the exact/reference choice in the second column.

## Stage-specific items not yet ready to order

| Item | Required by stage | Current state / prerequisite |
|---|---|---|
| Static-system survey materials / temporary measurement aids | **Stage 3** | Identify existing Skyranger tube OD/ID, material, tee point, run length and panel clearance. |
| RM3100 installation survey / temporary non-magnetic mounting aids | **Stage 3** | Establish magnetically quiet location, cable length and routing before freezing connector/harness. |
| GNSS installation survey / temporary antenna positioning aids | **Stage 3** | Establish antenna sky view, receiver/antenna location, RF cable or module wiring route, interference environment and required connector before final hardware is frozen. |
| Front optical window | **Stage 4** | Target 62 mm × 2 mm hard-coated anti-reflective polycarbonate; supplier/order specification still to freeze. |
| Static tee, tubing, barbed/bulkhead fitting and sealing hardware | **Stage 4** | **Do not order yet** — dependent on Stage 3 aircraft static-system measurements and leak-test design. |
| Final RM3100 cable, connector/gland and non-magnetic mounting bracket | **Stage 4** | **Do not order yet** — dependent on Stage 3 magnetic-location/routing survey. |
| Final GNSS antenna, cable/connector/gland or remote-receiver harness | **Stage 4** | **Do not order yet** — dependent on receiver selection and Stage 3 installation/RF survey. |
| Enclosure inserts / final mechanical fasteners | **Stage 4** | Exact insert/fastener dimensions to be verified against physical enclosure/display/panel trial. |
| **4-layer custom ESP32-S3 EFIS carrier PCB** | **Stage 5** | PCB remains parked until display/sensor/control/power/GNSS interfaces and physical installation interfaces are validated. |
| Final PCB production components/connectors | **Stage 5** | Generate from frozen KiCad BOM after schematic/layout review; include the adopted GNSS electrical interface but do not guess it now. |
| Aircraft 12 V input DC/DC converter, transient/reverse-polarity protection and filtering | **Stage 6** | **Do not freeze/order yet** — use measured `docs/POWER_BUDGET.md` data and defined aircraft supply environment first. |
| Final aircraft power/data wiring, retained connectors, fuse/circuit protection | **Stage 6** | Size/specify after current, converter, routing and installation requirements are validated. |
| Final panel mounting hardware | **Stage 6** | Confirm after physical fit trial; use appropriate secure locking/retention method. |

## Bench power supply options — suppliers and cost

Only **one** bench PSU is required.

### Option A — Korad KA3005P

**Purchase link:** [DigiKey UK — KA3005P](https://www.digikey.co.uk/en/products/detail/sra-soldering-products/KA3005P/10709868)  
**Reference price checked 16-Sep-2026:** **£88.35 ex VAT / £106.02 inc VAT**.

Preferred economical choice: single output, 0–30 V DC, 0–5 A with adjustable voltage/current limiting.

### Option B — Siglent SPD3303X-E

**Purchase link:** [Siglent UK — SPD3303X-E](https://siglent.co.uk/product/siglent-spd3303x-e-2x-0-32v-3-2a-2-5v-3-3v-5-0v-3-2a-220w-programmable-dc-power-supply/)  
**Reference price checked 16-Sep-2026:** **£312.00 ex VAT / £374.40 inc VAT**.

Premium multi-output alternative permitting independent rails/subassemblies to be powered simultaneously.

## Core prototype reference

Before any new order: confirm manufacturer part number and variant; confirm it is due for the current/next stage; recheck stock/VAT-inclusive price; update quantity/status; retain supplier/order detail for traceability.

## BMI088 bench connection — verify before purchase

The Bosch BMI088 Shuttle Board 3.0 exposes its connections on **1.27 mm pitch**. Do not buy a guessed generic 2.54 mm adapter. Obtain either the mating Bosch/Application-Board-compatible socket arrangement or a verified 1.27 mm breakout/interposer after checking the actual supplied shuttle board.

## Sources frozen or pending selection

| Function | Selected source | Status |
|---|---|---|
| Attitude | **Bosch BMI088** | Frozen |
| Static pressure / altitude | **Bosch BMP585**, initially Adafruit ported PID 6413 | Frozen sensor; final physical implementation pending testing |
| Magnetic heading | **PNI RM3100-CB 14754**, remote mounted | Frozen |
| GNSS position / track / groundspeed | Receiver TBD; must report position, fix/freshness and explicit horizontal-accuracy estimate | **Functional requirement frozen; hardware selection open** |

GNSS is an independent data source. It does not replace BMI088 attitude, BMP585 barometric altitude or RM3100 magnetic heading. `TRK` and `GS` are GNSS-derived terms; `HDG` remains the heading solution and `IAS` is not derived from GNSS.

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

**Stage 1 — bench hardware / bring-up:** obtain processor, the single display/adapter/FFC, backlight driver, encoder/GPIO-expander, one current-limited bench PSU and basic interconnects. Gate: stable controlled power and display/control bring-up.

**Stage 2 — sensor + GNSS integration / instrument validation:** integrate BMI088, BMP585, RM3100 and the selected GNSS receiver. Validate AHRS, altimeter and compass plus GNSS position/fix/freshness/accuracy classification. The Horizon/PFD and Compass must show latitude/longitude with the coordinate numbers colour-coded by reported horizontal accuracy: ≤1 m green, >1–3 m light green, >3–10 m yellow, >10–30 m orange, >30 m red; stale/no-fix must not leave plausible frozen coordinates. Validate `TRK`/`GS` semantics separately from `HDG`/IAS. Measure power and exercise independent source failures. Gate: interfaces and instrument software sufficiently stable for installation surveys.

**Stage 3 — aircraft survey / measurements:** measure static plumbing, panel/enclosure space, remote magnetometer location/routing, and GNSS receiver/antenna location, sky view, interference and routing. Avoid guessed final installation hardware.

**Stage 4 — physical interfaces / enclosure freeze:** select static fittings, magnetometer harness/connector, GNSS antenna/harness/interface, optical window and final mechanical details from Stage 3 results. Gate: physical interfaces frozen enough for PCB/enclosure commitment.

**Stage 5 — custom carrier PCB:** complete/review KiCad schematic and 4-layer layout including the validated GNSS interface; generate fabrication/assembly BOM and order a small prototype batch only after preceding interfaces are validated. Gate: populated PCB passes bench functional, electrical, thermal, GNSS-interference, fault and power tests.

**Stage 6 — aircraft installation / validation:** specify aircraft input protection/conversion, wiring, circuit protection and final mounting from measured prototype data. Ground-test GNSS position/accuracy/freshness and interference together with attitude, altitude and magnetic heading before any airborne comparison. Installation does not change the project's supplementary/non-primary status.

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible data must invalidate the relevant indication rather than freezing a plausible value. GNSS loss must not invalidate otherwise-valid attitude or magnetic heading, and GNSS validity must not imply those sources are valid.

See `docs/GNSS_DISPLAY.md`, `docs/POWER_BUDGET.md`, `docs/PROJECT_STATUS.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.
