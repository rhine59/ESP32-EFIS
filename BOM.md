# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

**Price check:** 16 September 2026. Prices are reference prices at the date checked and should be rechecked immediately before purchase.

## Purchasing status

Use this table as the project procurement record. Update **Ordered** items to **Received** as deliveries arrive; items not yet purchased remain **Needed**.

| Item | Exact/reference choice | Qty needed | Qty ordered | Status | Supplier / order note | Reference cost |
|---|---|---:|---:|---|---|---:|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | 2 | 2 | **Ordered** | Digi-Key, order dated 14-Sep-2026 | Actual order record |
| Attitude IMU | **Bosch SHUTTLE BOARD 3.0 BMI088** | 1 | 1 | **Ordered** | Digi-Key, P/N 828-SHUTTLEBOARD3.0BMI088-ND, order dated 14-Sep-2026 | Actual order record |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 1 | **Ordered / shipped** | Mouser; ordered 14-Sep-2026, shipped 15-Sep-2026 | £18.37 ex VAT merchandise |
| Display bench adapter | **Newhaven NHD-FFC40 breakout board** | 1 | 1 | **Ordered** | RS Components | Actual order record |
| Display FFC | **40-position, 0.5 mm pitch FFC/FPC cable**, compatible orientation | 2 | 0 | **Needed** | Verify contact orientation/length physically | TBD |
| Backlight driver | **Adafruit TPS61169 breakout, PID 6354** | 1 | 1 | **Ordered** | Digi-Key, P/N 1528-6354-ND, order dated 14-Sep-2026 | Actual order record |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | 1 | 1 | **Ordered** | Digi-Key, P/N PEC09-2320F-T0015-ND, order dated 14-Sep-2026 | Actual order record |
| Bench GPIO expander | **Microchip MCP23008-E/P** | 1 | 1 | **Ordered** | Digi-Key, P/N MCP23008-E/P-ND, order dated 14-Sep-2026 | Actual order record |
| Pressure module | **Adafruit BMP585 Ported I2C breakout, PID 6413** | 1 | 0 | **Needed** | First static-pressure/altimeter development sensor | Recheck before order |
| Pressure-sensor cable | **STEMMA QT / Qwiic JST-SH 4-pin cable**, 100–200 mm | 2 | 0 | **Needed** | BMP585 bench connection plus spare | TBD |
| QT breadboard adapter | **Adafruit Qwiic / STEMMA QT breakout PID 5961** or equivalent | 1 | 0 | **Needed** | JST-SH-to-0.1-inch breakout | TBD |
| Magnetic heading sensor | **PNI RM3100-CB, P/N 14754** | 1 | 0 | **Needed** | Remote three-axis magnetometer | Recheck before order |
| Bench PSU — preferred single-output option | **Korad KA3005P**, 0–30 V / 0–5 A programmable linear bench supply | 1 | 0 | **OPTION — Needed if selected** | **DigiKey UK**, manufacturer/series listed as SRA/Korad; 120 in stock when checked | **£88.35 ex VAT / £106.02 inc VAT** |
| Bench PSU — multi-output option | **Siglent SPD3303X-E**, 2× 0–32 V / 3.2 A plus selectable 2.5/3.3/5 V output, 220 W | 1 | 0 | **OPTION — Needed if selected** | **Siglent UK / Telonic Instruments**; 10+ UK stock when checked | **£312.00 ex VAT / £374.40 inc VAT** |
| Bench PSU lead kit | 4 mm banana leads plus banana-to-crocodile, bare-wire/header and USB-C power breakout/adapters | 1 set | 0 | **Needed with bench PSU** | Supplier can be chosen with PSU/order; quality insulated 4 mm leads preferred | Allow ~£20–£40 |
| USB-C bench cable | Good-quality power/data cable suitable for EFIS 5 V bench feed | 1 | 0 | **Needed** | Use from regulated 5 V source; prototype design allowance is 2 A or greater | Allow ~£5–£15 |
| Solderless breadboard | Good-quality full-size board | 1 | 0 | **Needed** | Initial integration | TBD |
| Prototyping wire | 22–26 AWG solid-core hookup wire assortment | 1 set | 0 | **Needed** | Bench only | TBD |
| Header pins | 2.54 mm breakaway male/female headers | 1 set | 0 | **Needed** | Bench breakouts and MCP23008 | TBD |

The procurement status above records only purchases explicitly confirmed for this project. Having an item already available in the workshop can be recorded separately when confirmed rather than assuming it has been purchased.

## Bench power supply options — suppliers and cost

Only **one** bench PSU is required. The two recorded choices represent different levels of bench capability rather than two required purchases.

### Option A — Korad KA3005P

**Reference supplier:** DigiKey UK  
**DigiKey listing:** `KA3005P` — SRA Soldering Products / Korad series  
**Price checked 16-Sep-2026:** **£88.35 ex VAT / £106.02 inc VAT** for one unit.  
**Availability when checked:** 120 units in stock.  
**Delivery note:** DigiKey UK states free UK delivery for qualifying orders of £65 or more, so this unit alone exceeds that threshold; current delivery terms must still be checked at checkout.

The KA3005P is the preferred economical choice for this project: single output, 0–30 V DC, 0–5 A, programmable/regulatable with adjustable current limiting and USB/RS-232 interface. It is sufficient for normal EFIS development because the complete prototype should ordinarily be powered from one controlled input while its own regulation creates internal rails.

Useful EFIS applications include 5.0 V prototype operation with an intentionally low current limit for first power-up, 3.3 V direct subassembly testing where appropriate, and 10–15 V sweeps when the later aircraft-input power stage is being tested.

### Option B — Siglent SPD3303X-E

**Reference supplier:** Siglent UK / Telonic Instruments  
**Model:** `SPD3303X-E`  
**Price checked 16-Sep-2026:** **£312.00 ex VAT / £374.40 inc VAT**.  
**Availability when checked:** 10+ units in UK stock.  
**Specification:** two independently adjustable 0–32 V / 3.2 A channels plus a third selectable 2.5 V / 3.3 V / 5.0 V channel; total rated power 220 W; USB and LAN.

This is the premium multi-output alternative. It costs about **£268 more including VAT** than the KA3005P at the checked prices, but allows several independent rails/subassemblies to be powered simultaneously. That can be useful during regulator and power-stage development, while the Korad remains sufficient for the normal end-to-end EFIS workflow.

### Bench lead system

Budget approximately **£20–£40** for a useful initial set of insulated 4 mm banana leads and adapters. Keep dedicated, clearly identified banana-to-crocodile, banana-to-bare-wire/header and USB-C power arrangements. This is a planning allowance rather than a quoted component price because lead length, shrouded/unshrouded connector preference and USB-C breakout arrangement have not yet been frozen.

Never assume a USB-C breakout performs USB Power Delivery negotiation unless that specific module is designed to do so.

## Order now — core prototype reference

| Item | Exact/reference choice | Qty | Purpose / notes |
|---|---|---:|---|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | 2 | 16 MB Quad flash, 2 MB Quad PSRAM; second unit is a development spare. Bare module is for carrier-PCB development; use a compatible development board for breadboard work if already available. |
| Attitude IMU | **Bosch SHUTTLE BOARD 3.0 BMI088** | 1 | SPI attitude sensor; rigid aircraft-axis mounting. |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 2.1-inch 480 × 480 high-brightness round IPS, ST7701S. Already ordered/shipped. |
| Display bench adapter | **Newhaven NHD-FFC40** | 1 | Breaks out the 40-way display FFC for bench work. |
| Display FFC | **40-position, 0.5 mm pitch FFC/FPC cable**, compatible orientation with display/adapter | 2 | One working cable plus spare. Verify contact orientation and length physically before ordering. |
| Backlight driver | **Adafruit TPS61169 breakout, PID 6354** | 1 | Constant-current boost driver; PWM brightness from ESP32. |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | 1 | Rotary encoder with push switch. |
| Bench GPIO expander | **Microchip MCP23008-E/P** | 1 | Through-hole bench prototype; final carrier will use an appropriate SMD version. |
| Pressure module | **Adafruit BMP585 Ported I2C breakout, PID 6413** | 1 | First static-pressure/altimeter development sensor. |
| Pressure-sensor cable | **STEMMA QT / Qwiic JST-SH 4-pin cable**, 100–200 mm | 2 | BMP585 bench connection plus spare. |
| QT breadboard adapter | **Adafruit Qwiic / STEMMA QT breakout PID 5961** or equivalent | 1 | Makes the BMP585 QT connection convenient on a breadboard/custom wiring loom. |
| Magnetic heading sensor | **PNI RM3100-CB, P/N 14754** | 1 | Remote three-axis magnetometer. |
| Bench power supply | **Choose one: Korad KA3005P (~£106 inc VAT) or Siglent SPD3303X-E (~£374 inc VAT)** | 1 | Adjustable voltage plus current limiting. Korad is sufficient for most EFIS work; Siglent adds simultaneous independent rails. |
| Bench PSU lead/adaptor set | 4 mm banana-based interchangeable leads | 1 set | Planning allowance £20–£40. |
| Solderless breadboard | Good-quality full-size board | 1 | Initial sensor/control integration. |
| Prototyping wire | 22–26 AWG solid-core hookup wire assortment | 1 set | Bench only. |
| Header pins | 2.54 mm breakaway male/female headers | 1 set | Bench breakouts and MCP23008. |

## BMI088 bench connection — verify before purchase

The Bosch BMI088 Shuttle Board 3.0 exposes its connections on **1.27 mm pitch**. Do not buy a guessed generic 2.54 mm adapter. Obtain either the mating Bosch/Application-Board-compatible socket arrangement or a verified 1.27 mm breakout/interposer after checking the actual supplied shuttle board. The final aircraft installation should use a rigid, positively retained connection rather than loose jumper wires.

## Sensors frozen for the EFIS

| Function | Selected source | Status |
|---|---|---|
| Attitude | **Bosch BMI088** | Frozen |
| Static pressure / altitude | **Bosch BMP585**, initially Adafruit ported PID 6413 | Frozen sensor; final physical implementation pending testing |
| Magnetic heading | **PNI RM3100-CB 14754**, remote mounted | Frozen |

The BMP585 ported breakout is intended to run over **I2C**. Default breakout I2C address is 0x47 (0x46 with SDO/address selection).

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

**Stage 1 — buy now:** display + FFC adapter/cables, BMI088, BMP585 ported module + QT cables/breakout, RM3100-CB, TPS61169, PEC09, MCP23008, **one suitable current-limited bench PSU**, banana/adaptor leads and normal bench materials. Track actual orders and deliveries in the purchasing-status table at the top of this file.

**Stage 2 — bench integration:** prove display, controls, BMI088, pressure and magnetic sensor interfaces; develop AHRS/altimeter/compass firmware; test invalid/stale-data behavior; record measured power consumption in `docs/POWER_BUDGET.md`.

**Stage 3 — aircraft measurements:** measure static plumbing and survey remote magnetometer location/cable routing.

**Stage 4 — freeze physical interfaces:** choose static fitting, magnetometer connector/harness, optical window hardware and final mounting details; update enclosure accordingly.

**Stage 5 — custom carrier PCB:** resume PCB design only after the physical interfaces above are frozen.

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible sensor data must invalidate the relevant indication rather than freezing a plausible value.

See `docs/POWER_BUDGET.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.
