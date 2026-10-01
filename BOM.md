# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

**Procurement status updated:** 24 September 2026 from RS, DigiKey and Mouser delivery-note/packaging photographs, subsequent delivery-status updates, The Pi Hut invoice evidence, and photographic confirmation of delivered parts. `RECEIVED` is used when arrival is confirmed by a supplied delivery-note photograph or other explicit physical-arrival confirmation.

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
- **Stage 7 — PROVISIONAL Engine Sensor / EIU integration:** optional remote engine monitoring over AEF-CAN. Does not block Stages 1–6; see `docs/STAGE-7-EIU.md`.

## Purchasing status and sources

| Item | Exact/reference choice | Stage | Needed | Received | Status | Purchase source / reference |
|---|---|---:|---:|---:|---|---|
| MCU module | **ESP32-S3-WROOM-1-N16R2** | 1 | 2 | 2 | **RECEIVED — delivery-note photo confirmed** | DigiKey UK — `5407-ESP32-S3-WROOM-1-N16R2CT-ND` |
| Temporary MCU carrier/programmer | **Espressif ESP-Module-Prog-1**, specifically Prog-1 not Prog-1R | 1 | 1 | 1 | **RECEIVED — DigiKey packaging/photo confirmed 24 Sep 2026** | DigiKey UK `1965-ESP-MODULE-PROG-1-ND`; manufacturer `ESP-MODULE-PROG-1` |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 1 | 1 | **RECEIVED — Mouser packaging/delivery document photo confirmed 21 Sep 2026** | Mouser P/N `763-2.1-480480AFASXP`; manufacturer P/N `NHD-2.1-480480AF-ASXP` |
| Display bench adapter | **Newhaven NHD-FFC40** | 1 | 1 | 1 | **RECEIVED — RS invoice/photo confirmed; invoice dated 15 Sep 2026** | RS UK stock `723-891`; invoice line: “40 pin FFC to thru hole adapter”; £9.01 ex VAT |
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
| Pressure module | **Adafruit BMP585 Baro+Temp Sensor PID 6413** | 2 | 1 | 1 | **RECEIVED — packaging/photo confirmed 22 Sep 2026** | Adafruit PID `6413`; DigiKey UK `1528-6413-ND`; The Pi Hut/Pimoroni alternate |
| Pressure cable | **Adafruit STEMMA QT/Qwiic JST-SH 4-pin, 150 mm, PID 4397** | 2 | 2 | 2 | **RECEIVED — qty 2, DigiKey packaging/photo confirmed 24 Sep 2026** | DigiKey UK `1528-4397-ND` |
| QT breadboard adapter | **Adafruit PID 5961** | 2 | 1 | 1 | **RECEIVED — DigiKey packaging/photo confirmed 24 Sep 2026** | DigiKey UK `1528-5961-ND` |
| Magnetic heading sensor | **PNI RM3100-CB P/N 14754** | 2 | 1 | 0 | **NEEDED** | PNI Sensor direct SKU `14754` |
| GNSS receiver | Position/fix/freshness + explicit horizontal accuracy | 2 | 1 | 0 | **SELECTION REQUIRED** | Source after receiver selection |
| GNSS bench antenna | Compatible with selected receiver | 2 | 1 | 0 | **BLOCKED by receiver selection** | Select with receiver |

## Order / delivery evidence

### Received
RS and DigiKey delivery-note photographs confirm receipt of the NHD-FFC40, two ESP32-S3-WROOM-1-N16R2 modules, TPS61169 board, Bourns encoder, MCP23008 and BMI088 Shuttle Board. Additional RS invoice evidence supplied on 22 September 2026 confirms the NHD-FFC40 adapter as RS stock `723-891`, described as “40 pin FFC to thru hole adapter”, quantity 1, invoiced 15 September 2026 at £9.01 ex VAT. A photograph supplied on 18 September 2026 confirms physical receipt of The Pi Hut mounted full-size breadboard, product `103521`, quantity 1. Photographs supplied on 21 September 2026 confirm receipt of 1 × Newhaven `NHD-2.1-480480AF-ASXP` display from Mouser (Mouser P/N `763-2.1-480480AFASXP`, quantity 1). A photograph supplied on 22 September 2026 confirms physical receipt of 1 × Adafruit BMP585 Baro+Temp Sensor, product/PID `6413`, including loose header strip. Photographs supplied on 24 September 2026 confirm physical receipt of 1 × Espressif `ESP-MODULE-PROG-1`, 2 × Adafruit STEMMA QT/Qwiic 150 mm cables PID 4397, and 1 × Adafruit QT/STEMMA QT breadboard adapter PID 5961.

### Ordered / in transit

**DigiKey order dated 21 Sep 2026, invoice evidence supplied 22 Sep 2026:** 1 × Espressif `ESP-MODULE-PROG-1` (`1965-ESP-MODULE-PROG-1-ND`), 2 × Adafruit STEMMA QT/Qwiic 150 mm cables PID 4397 (`1528-4397-ND`), and 1 × Adafruit QT/STEMMA QT breadboard adapter PID 5961 (`1528-5961-ND`) are recorded as ordered/shipped. The same invoice also shows 1 × BMP585 PID 6413, which is already separately confirmed RECEIVED by physical photo. Hook-up wire and jumper kit on the invoice are bench consumables and are not separately tracked as outstanding BOM items.

## Stage 1 — immediate purchase/verification list

1. **ESP-Module-Prog-1, Newhaven display and NHD-FFC40 received.** The display has an integral 40-way flex tail; no separate FFC cable is required. Verify connector orientation, pin numbering and continuity before applying power.
2. **ESP-Module-Prog-1 is physically received** (`1965-ESP-MODULE-PROG-1-ND`); Stage 1 MCU programming/bring-up is no longer blocked by the programmer.
3. **Current-limited PSU, leads, headers, hookup wire and breadboard are available.**
4. Confirm a suitable USB-C data cable is available before MCU programming.

Stage 1 gate: safe/current-limited 5 V power, programmable/mounted single MCU, working single-display connection/backlight and encoder/GPIO-expander bring-up.

## Stage 2 — immediate purchase/selection list

1. Verify and obtain the 1.27 mm mating adapter/interposer for the BMI088 Shuttle Board 3.0.
2. **Adafruit BMP585 PID 6413 received.** Retain for Stage 2 pressure/temperature bench integration.
3. **2 × STEMMA QT/Qwiic 150 mm cables PID 4397 received.**
4. **Adafruit PID 5961 QT breadboard adapter received.**
5. Buy 1 × PNI RM3100-CB P/N 14754.
6. Select the GNSS receiver, then its compatible bench antenna.

## Stage-specific items not yet ready to order

Stage 3+ aircraft static bulkhead fitting and pneumatic tubing/tee, final RM3100 harness/mount, final GNSS installation hardware, optical window, final enclosure hardware, custom carrier PCB production, and aircraft 12 V input/protection hardware remain gated by bench validation and aircraft surveys.

## Bench consumables / useful spares

Useful bench stock: 0.1 uF, 1 uF and 10 uF ceramic capacitors; 4.7 kOhm and 10 kOhm resistors; heat-shrink; small cable ties/lacing; and suitable non-magnetic/stainless M2/M2.5/M3 hardware. Preferred general sources: DigiKey, Mouser, RS, CPC Farnell and Accu as appropriate.

## Budget bench-power option — optional / not required to start Stage 1

The existing current-limited bench PSU remains the preferred source for first power-up. The following low-cost parts form a useful separate 12 V bench-power rig and a stepping stone toward later aircraft-power development. **Do not mark these items ordered or received without purchase/arrival evidence.**

| Item | Practical choice | Qty | Status | Indicative budget | Notes / source |
|---|---|---:|---|---:|---|
| 12 V source | Regulated 12 V DC brick, **3 A minimum** | 1 | OPTIONAL / BUY IF NEEDED | £12–£20 | Reputable UK electronics/model supplier; 5.5×2.1 mm barrel is convenient |
| 5 V buck | Adjustable **LM2596-class** step-down module, preferably multi-turn adjustment / display | 1 | OPTIONAL | £3–£8 | Set to **5.00 V before connecting Horizon**; a displayed LM2596 3 A module is a convenient bench choice |
| Spare adjustable buck | LM2596-class adjustable module | 1 | OPTIONAL | £2–£5 | Useful for experiments; never assume factory output setting |
| Input fuse holder | Inline ATO/ATC blade-fuse holder | 1 | OPTIONAL | £2–£5 | Fit an appropriately small bench fuse; start conservatively |
| 5 V branch fuse | Inline holder + **1 A fuse** | 1 | OPTIONAL | £2–£5 | Prototype protection; revise if measured startup/current demands require it |
| Master switch | DC-rated SPST toggle/rocker, >=3 A at 12 V | 1 | OPTIONAL | £2–£4 | Switch 12 V input before the converters |
| 5 V enable/switch | DC-rated SPST | 1 | OPTIONAL | £1–£3 | Lets logic be isolated independently |
| Voltage/current indication | Small DC volt/ammeter or USB/DC inline meter | 1 | OPTIONAL | £4–£8 | Diagnostic convenience, not a calibrated instrument |
| Screw terminals / DC socket / wire | 5.5×2.1 mm socket, terminal blocks, 20–22 AWG wire, heat-shrink | 1 set | OPTIONAL | £3–£6 | Keep polarity and rails clearly labelled |

**Budget:** about **£20–£30** if a suitable 12 V source, switches, fuse parts or meter are already in the workshop; approximately **£30–£50** if buying the complete rig from scratch. Prices are indicative and should be rechecked before purchase.

### Bench topology

```text
12 V regulated source
        |
      fuse
        |
 master switch
        |
   +----+---------------------------+
   |                                |
LM2596 buck -> verified 5.00 V      | future/experimental branch
   |                                |
 1 A branch fuse                    +-> separate converter as required
   |
 Horizon 5 V bench rail
   |
 regulated 3.3 V rail -> ESP32/sensors as designed

Display backlight: use the dedicated TPS61169 backlight-driver path already in the BOM;
do not substitute an arbitrary 6 V rail for the designed LED current driver.
```

### Bring-up rules

1. First power-up should still use the owned **current-limited bench PSU**.
2. Adjust each buck **with no Horizon electronics attached**, verify with a multimeter, power-cycle it, and verify again.
3. Never rely on the module's printed/displayed voltage alone for first connection.
4. Start with a conservative current limit/fuse and monitor rail voltage/current for abnormal draw.
5. Keep a common 0 V reference only where required by the verified wiring design; do not improvise aircraft grounding from the bench rig.
6. Espressif recommends 3.3 V and at least 500 mA capability for an ESP32-S3 single-supply design, with local bulk/decoupling capacitance. The Horizon design should retain its documented decoupling rather than relying on the buck module alone.
7. This low-cost bench rig is **not** the production aircraft power-input design and does not replace reverse-polarity, surge/transient, filtering and other aircraft-side protection.

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible data must invalidate the relevant indication rather than freezing a plausible value. GNSS loss must not invalidate otherwise-valid attitude or magnetic heading, and GNSS validity must not imply those sources are valid.

See `docs/PROCUREMENT_STATUS_2026-09-16.md`, `docs/GNSS_DISPLAY.md`, `docs/POWER_BUDGET.md`, `docs/PROJECT_STATUS.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.



## Interface direction update — 30 September 2026

- **Engine sensors:** add a keyed, positively retained enclosure-accessible multiway connector/harness provision for CHT, EGT, oil temperature, oil pressure and coolant/water temperature. Connector family, sender-specific conditioning and exact parts are **SELECTION REQUIRED**; nothing is ordered by this decision.
- **GNSS:** supersede the earlier dedicated GNSS connector/bench-antenna direction with a **USB GPS mouse/receiver — SELECTION REQUIRED**. It must be validated for ESP32-S3 USB-host operation, protocol support, power demand and mechanical retention before procurement/freeze. A USB GPS mouse is an active USB-powered GNSS receiver, not a passive electrical device.

## Remote Engine Interface Unit — planning BOM

The direct engine-sensor connector at Horizon is superseded by a separate **Engine Interface Unit (EIU)**. For initial planning assume a conventional Rotax 912-series installation, while verifying the actual engine variant/serial/configuration before freezing sender curves, ranges or limits.

| EIU item/function | V1 direction | Status |
|---|---|---|
| EIU enclosure + sensor connectors | Compact black-plastic ULM/microlight-headset-style locking circular connectors; splash/water-resistant installation, not necessarily waterproof | SELECTION REQUIRED |
| EIU processor | Small MCU with watchdog, CAN and adequate diagnostics | SELECTION REQUIRED |
| Analogue conversion | External precision ADC / sender-specific front ends | SELECTION REQUIRED |
| EGT channels | 2 × K-type thermocouple front ends with cold-junction compensation and open-sensor detection | SELECTION REQUIRED |
| Head/coolant temperature | 2 channels, exact Rotax sender/transfer function selected by installation | SELECTION REQUIRED |
| Oil temperature | Rotax-compatible sender conditioning | SELECTION REQUIRED |
| Oil pressure | Sender-specific input; exact installed Rotax sender generation/range must be verified | SELECTION REQUIRED |
| EIU ↔ Horizon bus | **Isolated CAN**, protected at both ends | PREFERRED V1 |
| EIU power | Protected aircraft supply with local regulation/filtering | DESIGN REQUIRED |
| Diagnostics | Open/short/plausibility, sequence/freshness, raw + engineering values | DESIGN REQUIRED |

The EIU is monitoring-only. It must not become necessary for engine operation and must not disturb an existing engine-control or required indication circuit. No EIU parts are marked ordered by this planning update.


## Stage 7 — provisional EIU / AEF-CAN BOM addition

These items are **provisional** and are not instructions to purchase yet. Exact transceiver/isolation/protection and sensor-front-end parts will be frozen after electrical design and installed-engine survey.

| Item | Provisional requirement | Location | Qty | Status |
|---|---|---|---:|---|
| Horizon CAN transceiver | 3.3 V Classical CAN transceiver compatible with ESP32-S3 TWAI; protected interface | Horizon carrier | 1 | SELECTION REQUIRED |
| CAN termination | 120 ohm, switchable/jumper-selectable on Horizon | Horizon carrier | 1 | DESIGN REQUIRED |
| CAN protection | ESD/transient protection appropriate to final interface | Horizon carrier | 1 set | DESIGN REQUIRED |
| CAN connector | keyed locking CAN-H/CAN-L/reference/shield provision; coordinate with final Horizon enclosure interface | Horizon enclosure | 1 | SELECTION REQUIRED |
| CAN cable | twisted pair, installation length after aircraft survey | aircraft harness | as required | DEFERRED |
| EIU MCU | MCU with watchdog + Classical CAN; ESP32-class prototype acceptable | EIU | 1 | SELECTION REQUIRED |
| EIU CAN transceiver | preferably galvanically isolated architecture for V1 installation | EIU | 1 | SELECTION REQUIRED |
| EIU termination | 120 ohm if EIU is opposite physical bus end | EIU | 1 | DESIGN REQUIRED |
| EIU protected power | aircraft input protection, filtering and local rails | EIU | 1 set | DESIGN REQUIRED |
| Precision ADC/front ends | sender-specific analogue conversion | EIU | as required | DESIGN REQUIRED |
| K-type thermocouple front ends | cold-junction compensation + open-sensor detection | EIU | provision for 4 EGT | DESIGN REQUIRED |
| Temperature sender interfaces | installed Rotax sender-specific | EIU | as required | SURVEY REQUIRED |
| Oil-pressure interface | installed sender generation/range-specific | EIU | 1 | SURVEY REQUIRED |
| RPM conditioner | protected interface appropriate to selected RPM source | EIU | 1 | SURVEY REQUIRED |
| EIU J1 ENGINE TEMP panel socket | Black-plastic ULM/microlight-headset-style circular positive-locking multiway panel connector; provisional 12-way concept, final count TBD | EIU | 1 | SELECTION REQUIRED — DO NOT ORDER |
| J1 mating cable plug | Matching black-plastic locking cable plug, contacts/termination and strain relief/boot as required | engine harness | 1 | SELECTION REQUIRED — DO NOT ORDER |
| EIU J2 ENGINE AUX panel socket | Black-plastic ULM/microlight-headset-style circular positive-locking multiway panel connector; provisional 12-way concept, final count TBD | EIU | 1 | SELECTION REQUIRED — DO NOT ORDER |
| J2 mating cable plug | Matching black-plastic locking cable plug, contacts/termination and strain relief/boot as required | engine harness | 1 | SELECTION REQUIRED — DO NOT ORDER |
| EIU J3 EFIS CAN panel socket | Smaller and/or differently keyed black-plastic ULM-style locking circular connector for protected power/ground + CAN-H/CAN-L; provisional 7-way concept | EIU | 1 | SELECTION REQUIRED — DO NOT ORDER |
| J3 mating cable plug | Matching black-plastic locking cable plug, contacts/termination and strain relief/boot as required | EIU-to-Horizon harness | 1 | SELECTION REQUIRED — DO NOT ORDER |
| Connector environmental accessories | Boots, heat-shrink, strain relief, sealing/grommet hardware as needed for splash/water-resistant installation; IP67 not required by current concept | EIU/harness | 1 set | DESIGN REQUIRED |
| EIU enclosure | vibration/temperature/moisture appropriate; connector orientation should minimise direct splash ingress and permit drip loops | EIU | 1 | SELECTION REQUIRED |

The Horizon-side CAN provision is part of making the core EFIS **Stage-7-ready**. The EIU and engine-sensor hardware remain optional/provisional.


## USB-C dual-role production interface — 30 September 2026

| Item | Requirement | Status |
|---|---|---|
| External USB-C connector | Single robust rear connector, labelled SERVICE / GPS | DESIGN REQUIRED |
| USB-C CC/role circuitry | Correct host/device role handling for ESP32-S3 OTG architecture | DESIGN REQUIRED |
| USB host VBUS switch | Protected/current-limited 5 V supply for validated GPS receiver; off when Horizon is USB device | DESIGN REQUIRED |
| USB ESD protection | Appropriate low-capacitance protection and PCB layout | DESIGN REQUIRED |
| GPS cable retention | Vibration-resistant installed connection without adding a second GNSS connector | DESIGN REQUIRED |
| Internal programming/test pads | Factory/recovery access independent of external connector condition | DESIGN REQUIRED |
| USB GPS mouse/receiver | USB-host compatible receiver/protocol and acceptable power demand | SELECTION REQUIRED |

One external USB-C port serves both GPS host operation and computer service/programming. Routine field firmware updating is intended to use signed OTA, but USB programming/recovery remains a production requirement.


### Stage 7 connector procurement note — 1 October 2026

The EIU connector visual/mechanical target is the **small black-plastic locking circular style used on ULM/microlight headset installations**. Metal-bodied Binder/aerospace-style connectors and industrial M12 connectors shown in earlier concept work are not the current preferred production appearance.

Do **not** purchase the provisional 12-way/12-way/7-way connector set yet. Those pin counts are packaging concepts only. Freeze the connector family and contact counts after confirming the actual Rotax 912 sensor set, EGT thermocouple termination strategy, wire gauges, contact ratings, temperature/vibration requirements and the final CAN/power pin allocation. The installation needs sensible splash/water resistance, not full waterproof/IP67 performance.


### EIU sensor-power BOM rule — 1 October 2026

Do not add a generic +5 V engine-sensor supply as a frozen BOM requirement. EGT thermocouples are self-generating; resistive temperature senders use EIU measurement excitation; oil-pressure and RPM power/interface requirements depend on the actual installed sender/source. Any required regulated sender supply is generated, protected and fault-contained locally within the EIU. The EIU itself should preferably use an independently protected aircraft-supply branch rather than the EFIS regulated electronics. Sender-specific regulator/current-limit/protection components remain **DESIGN/SURVEY REQUIRED**.


### EIU USB-C SERVICE / factory-programming additions — 1 October 2026

| Item | Requirement | Status |
|---|---|---|
| EIU USB-C SERVICE receptacle | External USB-C connector for factory flashing, development, diagnostics and recovery | DESIGN REQUIRED |
| EIU USB CC/device circuitry | Correct ESP32-S3 USB-device/service role handling; native USB preferred | DESIGN REQUIRED |
| EIU USB ESD protection | Low-capacitance protection and appropriate PCB layout at external service connector | DESIGN REQUIRED |
| EIU USB bench-power path | Permit USB 5 V to power required service/digital circuitry for bench programming | DESIGN REQUIRED |
| EIU power-path isolation | Reverse-current blocking/ORing/current limiting so USB VBUS and aircraft supply cannot back-feed each other | DESIGN REQUIRED |
| EIU USB/service-present detection | Allow firmware/manufacturing harness to identify service/bench operation where useful | DESIGN REQUIRED |
| EIU internal recovery pads | Fallback GND/reset/boot plus serial/debug/programming access appropriate to selected MCU | DESIGN REQUIRED |
| EIU factory programming cable | USB-C data-capable cable for development/production station | ACQUIRE LATER |
| EIU factory provisioning script | Flash bootloader/partition/factory app, provision identity, reboot/interrogate and record test result | SOFTWARE REQUIRED |

The external USB-C SERVICE connector is now the preferred factory/development programming route. Pogo/test pads are retained as fallback/recovery rather than the primary operator interface. Routine production firmware upgrades remain signed Horizon -> AEF-CAN -> EIU updates.

Do not freeze a USB power mux/ideal-diode/current-limit part until the EIU aircraft-input regulator and total bench-service power requirement are known. Likewise, do not enable irreversible ESP32 security/eFuse settings in the ordinary development flash process; production security provisioning requires a separate reviewed procedure.
