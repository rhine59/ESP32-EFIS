# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

**Procurement status updated:** 16 September 2026 from RS and DigiKey delivery-note photographs supplied by the project owner, subsequent delivery-status updates, and refreshed supplier checks. `RECEIVED` is used when arrival is confirmed by a supplied delivery-note photograph or other explicit physical-arrival confirmation.

## Procurement rules

1. Keep an explicit purchase source against every BOM line that is ready to buy.
2. Manufacturer/supplier part number is authoritative; do not substitute a similar-looking part without checking electrical and mechanical compatibility.
3. A delivery-note photograph that clearly identifies the part and quantity is sufficient evidence to change that quantity to **RECEIVED**.
4. An order confirmation, dispatch notice or statement that an item is on the way changes status to **ORDERED / IN TRANSIT**, not RECEIVED.
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
| MCU module | **ESP32-S3-WROOM-1-N16R2** | 1 | 2 | 2 | **RECEIVED — delivery-note photo confirmed** | DigiKey UK — Mfr `ESP32-S3-WROOM-1-N16R2`; current cut-tape ref `5407-ESP32-S3-WROOM-1-N16R2CT-ND`; https://www.digikey.co.uk/en/products/detail/espressif-systems/ESP32-S3-WROOM-1-N16R2/16162644 |
| Temporary MCU carrier/programmer | **Espressif ESP-Module-Prog-1**, specifically Prog-1 not Prog-1R | 1 | 1 | 0 | **NEEDED — source identified** | **Preferred: Mouser UK** `356-ESPMODULEPROG1`; https://www.mouser.co.uk/en/ProductDetail/Espressif-Systems/ESP-Module-Prog-1 — alternate DigiKey UK, search manufacturer P/N `ESP-MODULE-PROG-1` |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 1 | 0 | **ORDERED / IN TRANSIT** — owner confirms on the way | RS UK stock `286-351`; https://uk.rs-online.com/web/p/lcd-colour-displays/0286351 — alternate DigiKey `757-NHD-2.1-480480AF-ASXP-ND`; https://www.digikey.co.uk/en/products/detail/newhaven-display-intl/NHD-2-1-480480AF-ASXP/25724289 |
| Display bench adapter | **Newhaven NHD-FFC40** | 1 | 1 | 1 | **RECEIVED — RS delivery-note photo confirmed** | RS UK stock `723-891`; https://uk.rs-online.com/web/p/display-interface-kits/0723891 |
| Display FFC | **40-position, 0.5 mm FFC/FPC**, orientation and length to be verified against display + NHD-FFC40 | 1 | 2 | 0 | **NEEDED — do not order until orientation/length verified** | RS UK or DigiKey UK; search exact spec after physical display inspection. Purchase source to be frozen when contact orientation and length are known. |
| Backlight driver | **Adafruit TPS61169 PID 6354** | 1 | 1 | 1 | **RECEIVED — DigiKey delivery-note photo confirmed** | DigiKey UK `1528-6354-ND`; https://www.digikey.co.uk/en/products/detail/adafruit-industries-llc/6354/26832923 |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | 1 | 1 | 1 | **RECEIVED — DigiKey delivery-note photo confirmed** | DigiKey UK `PEC09-2320F-T0015-ND`; https://www.digikey.co.uk/en/products/detail/bourns-inc/PEC09-2320F-T0015/3780079 |
| GPIO expander | **Microchip MCP23008-E/P** | 1 | 1 | 1 | **RECEIVED — DigiKey delivery-note photo confirmed** | DigiKey UK `MCP23008-E/P-ND`; https://www.digikey.co.uk/en/products/detail/microchip-technology/MCP23008-E-P/735951 |
| Bench PSU | **Korad KA3005P** preferred economical option; **Siglent SPD3303X-E** premium alternative | 1 | 1 | 0 | **NEEDED — choose one only** | Korad: UK test-equipment supplier/Amazon UK, exact model `KA3005P`; Siglent: authorised UK Siglent distributor, exact model `SPD3303X-E`. Recheck UK delivered price before order. |
| Bench PSU lead kit | Banana leads plus croc/bare-wire/header/USB-C breakout as required | 1 | 1 set | 0 | **NEEDED unless already owned** | RS UK / CPC Farnell — 4 mm banana test leads, crocodile clips and suitable breakout leads |
| USB-C bench cable | Good-quality **data + power** USB-C cable | 1 | 1 | 0 | **NEEDED unless already owned** | RS UK / CPC Farnell / reputable USB supplier; ensure data-capable, not charge-only |
| Solderless breadboard | Full-size, good-quality board | 1 | 1 | 0 | **NEEDED unless already owned** | The Pi Hut / Pimoroni / RS UK; full-size solderless breadboard |
| Prototyping wire | 22–26 AWG solid-core assortment | 1 | 1 set | 0 | **NEEDED unless already owned** | RS UK / CPC Farnell; 22–26 AWG solid-core hook-up/prototyping wire |
| Header pins | 2.54 mm breakaway male/female | 1 | 1 set | 0 | **NEEDED unless already owned** | RS UK / The Pi Hut / Pimoroni; 2.54 mm breakaway headers |
| Attitude IMU | **Bosch Shuttle Board 3.0 BMI088** | 2 | 1 | 1 | **RECEIVED — DigiKey delivery-note photo confirmed** | DigiKey UK `828-SHUTTLEBOARD3.0BMI088-ND`; https://www.digikey.co.uk/en/products/detail/bosch-sensortec/SHUTTLE-BOARD-3-0-BMI088/14617528 |
| BMI088 bench interposer | Verified **1.27 mm-pitch** mating solution for Shuttle Board 3.0 | 2 | 1 | 0 | **NEEDED — exact connector/interposer still to verify** | Do not purchase a guessed adapter. Freeze supplier and part number only after the Shuttle Board connector is physically verified. |
| Pressure module | **Adafruit BMP585 Ported I2C/SPI PID 6413** | 2 | 1 | 0 | **NEEDED** | **Preferred: DigiKey UK** `1528-6413-ND`; https://www.digikey.co.uk/en/products/detail/bosch-sensortec/BMP585/19522589 (associated Adafruit 6413 listing). UK alternates: The Pi Hut `ADA6413` or Pimoroni `ADA6413` when in stock. Manufacturer: https://www.adafruit.com/product/6413 |
| Pressure cable | STEMMA QT/Qwiic JST-SH 4-pin, **100–200 mm** | 2 | 2 | 0 | **NEEDED** | DigiKey UK — Adafruit cable family; e.g. PID `4397` is 150 mm. Also The Pi Hut/Pimoroni. Verify JST-SH 4-pin female-to-female orientation. |
| QT breadboard adapter | **Adafruit PID 5961** | 2 | 1 | 0 | **NEEDED** | DigiKey UK `1528-5961-ND`; https://www.digikey.co.uk/en/products/detail/adafruit-industries-llc/5961/24614900 |
| Magnetic heading sensor | **PNI RM3100-CB, P/N 14754** | 2 | 1 | 0 | **NEEDED** | **PNI Sensor direct**, SKU `14754`; https://www.pnisensor.com/rm3100-cb/ — confirm UK shipping, VAT/import charges before order |
| GNSS receiver | Must report lat/lon, fix type/validity, freshness and explicit horizontal-accuracy estimate | 2 | 1 | 0 | **SELECTION REQUIRED before order** | No purchase source yet: hardware selection must be frozen first. Supplier/source will be added when exact receiver is selected. |
| GNSS bench antenna | Compatible with selected receiver | 2 | 1 | 0 | **BLOCKED by receiver selection** | Source to be selected with receiver after connector, active/passive requirement and supply voltage are known. |

## Source notes for the key electronic parts

### ESP32-S3 module

The exact MCU remains **ESP32-S3-WROOM-1-N16R2**, not N16 and not another PSRAM variant. DigiKey currently lists the exact N16R2. The two prototype modules are already received, so this source is retained for traceability and replacement/spare purchasing.

### Temporary ESP32-S3 carrier/programmer

Use **Espressif ESP-Module-Prog-1**, manufacturer P/N `ESP-MODULE-PROG-1`. Mouser UK part `356-ESPMODULEPROG1` is the preferred source. The module mounts without soldering to the fixture's power/signal lines and the board can act as a small development/programming platform. **Do not substitute ESP-Module-Prog-1R** without rechecking the spring-pin arrangement.

### Newhaven display and adapter

The display is **NHD-2.1-480480AF-ASXP**, RS stock `286-351`; it is currently **in transit**. The already-received adapter is **NHD-FFC40**, RS stock `723-891`. Do not buy the FFC merely from pin count: verify the display/adapter contact orientation and required length once the display arrives.

### Pressure sensor

The selected pressure module is **Adafruit PID 6413**, which carries the ported Bosch BMP585 and provides STEMMA QT plus I2C/SPI access. DigiKey UK is the preferred distributor where available; The Pi Hut and Pimoroni are practical UK alternates. The ported version is intentional because the eventual installation needs a static-pressure connection.

### Magnetometer

The selected magnetic source remains the ruggedised **PNI RM3100-CB, P/N/SKU 14754**, not merely a generic RM3100 breakout. PNI sells the RM3100-CB directly. This exact choice is retained because the CB version is intended for direct integration and PNI specifies vibration robustness.

## Delivery evidence — 16 September 2026

The supplied **RS delivery-note photograph** confirms:

- **Newhaven NHD-FFC40**, RS stock `723891`, quantity **1 RECEIVED**.

The supplied **DigiKey delivery-note photograph/paperwork** confirms:

- **ESP32-S3-WROOM-1-N16R2**, quantity **2 RECEIVED**.
- **Adafruit TPS61169 PID 6354**, quantity **1 RECEIVED**.
- **Bourns PEC09-2320F-T0015**, quantity **1 RECEIVED**.
- **Microchip MCP23008-E/P**, quantity **1 RECEIVED**.
- **Bosch Shuttle Board 3.0 BMI088**, quantity **1 RECEIVED**.

The **Newhaven NHD-2.1-480480AF-ASXP** is confirmed by the project owner as **on the way**, so it remains **ORDERED / IN TRANSIT** until physical arrival is confirmed. A future clear delivery-note photo identifying an outstanding BOM part and quantity should be treated as receipt evidence and the BOM updated accordingly.

## Stage 1 — immediate purchase/verification list

1. Await physical arrival of the **Newhaven NHD-2.1-480480AF-ASXP**; then mark it RECEIVED after arrival confirmation.
2. Once the display is physically available, verify FFC **contact orientation and length**, then buy **2 × 40-position 0.5 mm FFC/FPC** cables from RS/DigiKey or another named supplier and record the exact part number here.
3. Buy **1 × Espressif ESP-Module-Prog-1**, preferably Mouser UK `356-ESPMODULEPROG1`. The second N16R2 remains a spare.
4. Buy **one** current-limited bench PSU: Korad KA3005P for the economical route or Siglent SPD3303X-E for the premium route.
5. Obtain PSU leads, USB-C data cable, breadboard, prototype wire and headers where not already in the workshop.

Stage 1 gate: safe/current-limited 5 V power, programmable/mounted single MCU, working single-display connection/backlight and encoder/GPIO-expander bring-up.

## Stage 2 — immediate purchase/selection list

1. Verify and obtain the **1.27 mm mating adapter/interposer for the BMI088 Shuttle Board 3.0**; do not buy a guessed 2.54 mm adapter.
2. Buy **Adafruit BMP585 Ported I2C/SPI PID 6413** — preferred DigiKey UK; UK alternates The Pi Hut/Pimoroni when stocked.
3. Buy **2 × STEMMA QT/Qwiic JST-SH 4-pin cables**, 100–200 mm; 150 mm Adafruit PID 4397 is a suitable length candidate subject to connector verification.
4. Buy **1 × Adafruit Qwiic/STEMMA QT breakout PID 5961**, DigiKey `1528-5961-ND`.
5. Buy **1 × PNI RM3100-CB P/N 14754** from PNI direct, subject to UK shipping/import-cost check.
6. Select the **GNSS receiver** before purchasing it. It must expose an explicit horizontal-accuracy estimate in addition to position/fix/freshness.
7. Buy the **GNSS bench antenna only after receiver selection** establishes connector and active/passive requirements.

Stage 2 gate: validated BMI088 attitude, BMP585 pressure/altitude, RM3100 magnetic source and GNSS position/fix/freshness/accuracy handling, including independent fail-obvious source failures.

## Stage-specific items not yet ready to order

| Item | Stage | Prerequisite | Purchase source status |
|---|---:|---|---|
| Static-system survey materials / measurement aids | 3 | Identify existing static tube OD/ID, material, tee point, run length and panel clearance | Select after survey |
| RM3100 installation survey aids | 3 | Establish magnetically quiet location, cable length and routing | Select after survey |
| GNSS installation survey aids | 3 | Establish sky view, receiver/antenna location, RF/wiring route and interference environment | Select after receiver choice |
| Front optical window | 4 | Freeze dimensions/specification after physical trial | Supplier/spec already discussed separately; freeze after physical trial |
| Static tee/tubing/fittings/sealing hardware | 4 | Stage 3 static-system measurements and leak-test design | Select after dimensions known |
| Final RM3100 cable/connector/gland/bracket | 4 | Stage 3 magnetic survey | Select after routing survey |
| Final GNSS antenna/cable/connector/gland/harness | 4 | Receiver selection and Stage 3 GNSS installation survey | Select after receiver/routing freeze |
| Enclosure inserts/final mechanical fasteners | 4 | Physical enclosure/display/panel trial | Select after enclosure freeze |
| **4-layer custom EFIS carrier PCB** | 5 | Display/sensor/control/power/GNSS interfaces validated | PCB fabricator to be selected at release |
| Final PCB production components/connectors | 5 | Frozen KiCad schematic/layout/BOM | DigiKey/Mouser/RS as exact BOM dictates |
| Aircraft 12 V DC/DC, transient/reverse protection/filtering | 6 | Measured prototype power data and defined aircraft supply environment | Select after power design freeze |
| Final aircraft wiring/connectors/circuit protection | 6 | Current, converter, routing and installation requirements validated | Select after installation design |
| Final panel mounting hardware | 6 | Physical fit trial complete | Select after fit trial |

## Bench consumables / useful spares

| Item | Qty | Notes | Suggested source |
|---|---:|---|---|
| 0.1 uF ceramic capacitors | 10 | General local decoupling/prototyping | DigiKey / Mouser / RS |
| 1 uF / 10 uF ceramic capacitors | 5 each | Bench power decoupling | DigiKey / Mouser / RS |
| 4.7 kOhm resistors | 10 | I2C/pull-up experiments; fit only where required | DigiKey / Mouser / RS |
| 10 kOhm resistors | 10 | Pull-up/down prototyping | DigiKey / Mouser / RS |
| Heat-shrink assortment | 1 | Bench loom protection/strain relief | RS / CPC Farnell |
| Small cable ties/lacing | 1 pack | Bench cable management | RS / CPC Farnell |
| M2/M2.5/M3 suitable non-magnetic/stainless hardware | 1 set | Keep ferrous material away from RM3100 during magnetic tests | Accu / RS; verify material |

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible data must invalidate the relevant indication rather than freezing a plausible value. GNSS loss must not invalidate otherwise-valid attitude or magnetic heading, and GNSS validity must not imply those sources are valid.

See `docs/PROCUREMENT_STATUS_2026-09-16.md`, `docs/GNSS_DISPLAY.md`, `docs/POWER_BUDGET.md`, `docs/PROJECT_STATUS.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.
