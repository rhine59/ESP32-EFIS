# ESP32 EFIS — Bill of Materials and Purchasing Checklist

Evolving purchasing BOM for the **ESP32 EFIS** supplementary/non-primary multifunction flight instrument. Stock and prices change; recheck before ordering. Quantities below are prototype quantities, not production quantities.

## Purchasing status

Use this table as the project procurement record. Update **Ordered** items to **Received** as deliveries arrive; items not yet purchased remain **Needed**.

| Item | Exact/reference choice | Qty needed | Qty ordered | Status | Supplier / order note |
|---|---|---:|---:|---|---|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | 2 | 2 | **Ordered** | Digi-Key, order dated 14-Sep-2026 |
| Attitude IMU | **Bosch SHUTTLE BOARD 3.0 BMI088** | 1 | 1 | **Ordered** | Digi-Key, P/N 828-SHUTTLEBOARD3.0BMI088-ND, order dated 14-Sep-2026 |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 1 | **Ordered / shipped** | Mouser; ordered 14-Sep-2026, shipped 15-Sep-2026 |
| Display bench adapter | **Newhaven NHD-FFC40 breakout board** | 1 | 1 | **Ordered** | RS Components |
| Display FFC | **40-position, 0.5 mm pitch FFC/FPC cable**, compatible orientation | 2 | 0 | **Needed** | Verify contact orientation/length physically |
| Backlight driver | **Adafruit TPS61169 breakout, PID 6354** | 1 | 1 | **Ordered** | Digi-Key, P/N 1528-6354-ND, order dated 14-Sep-2026 |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | 1 | 1 | **Ordered** | Digi-Key, P/N PEC09-2320F-T0015-ND, order dated 14-Sep-2026 |
| Bench GPIO expander | **Microchip MCP23008-E/P** | 1 | 1 | **Ordered** | Digi-Key, P/N MCP23008-E/P-ND, order dated 14-Sep-2026 |
| Pressure module | **Adafruit BMP585 Ported I2C breakout, PID 6413** | 1 | 0 | **Needed** | First static-pressure/altimeter development sensor |
| Pressure-sensor cable | **STEMMA QT / Qwiic JST-SH 4-pin cable**, 100–200 mm | 2 | 0 | **Needed** | BMP585 bench connection plus spare |
| QT breadboard adapter | **Adafruit Qwiic / STEMMA QT breakout PID 5961** or equivalent | 1 | 0 | **Needed** | JST-SH-to-0.1-inch breakout |
| Magnetic heading sensor | **PNI RM3100-CB, P/N 14754** | 1 | 0 | **Needed** | Remote three-axis magnetometer |
| Bench PSU — preferred single-output option | **Korad KA3005P**, 0–30 V / 0–5 A programmable linear bench supply | 1 | 0 | **OPTION — Needed if selected** | Preferred economical EFIS bench supply; adjustable voltage/current limit; suitable for 3.3 V, 5 V and simulated 12–15 V aircraft-bus testing one rail at a time |
| Bench PSU — multi-output option | **Siglent SPD3303X-E**, triple-output programmable bench supply | 1 | 0 | **OPTION — Needed if selected** | Premium alternative where independent rails are useful simultaneously; do not buy both unless a second supply is wanted |
| Bench PSU lead kit | 4 mm banana leads plus banana-to-crocodile, bare-wire/header and USB-C power breakout/adapters | 1 set | 0 | **Needed with bench PSU** | Interchangeable leads for different prototype connections; verify polarity before energising |
| USB-C bench cable | Good-quality power/data cable suitable for EFIS 5 V bench feed | 1 | 0 | **Needed** | Use from regulated 5 V source; prototype design allowance is 2 A or greater |
| Solderless breadboard | Good-quality full-size board | 1 | 0 | **Needed** | Initial integration |
| Prototyping wire | 22–26 AWG solid-core hookup wire assortment | 1 set | 0 | **Needed** | Bench only |
| Header pins | 2.54 mm breakaway male/female headers | 1 set | 0 | **Needed** | Bench breakouts and MCP23008 |

The procurement status above records only purchases explicitly confirmed for this project. Having an item already available in the workshop can be recorded separately when confirmed rather than assuming it has been purchased.

## Bench power supply options

Only **one** bench PSU is required. The two recorded choices represent different levels of bench capability rather than two required purchases.

### Option A — Korad KA3005P

The preferred economical choice for this project is the **Korad KA3005P**, a single-output adjustable 0–30 V / 0–5 A linear bench supply. It is sufficient for the normal EFIS development workflow because the complete prototype should ordinarily be powered from one controlled input while its own regulation creates internal rails.

Useful EFIS applications include:

- 5.0 V prototype operation with an intentionally low current limit for first power-up;
- 3.3 V direct subassembly testing where appropriate;
- 5–6 V display/backlight development where the specific circuit permits it;
- 10–15 V input sweeps when the later aircraft 12 V power stage is being tested;
- current-limited fault finding and staged bring-up.

### Option B — Siglent SPD3303X-E

The **Siglent SPD3303X-E** is the premium multi-output alternative. It is appropriate if independent rails need to be powered and observed simultaneously. For the EFIS this is useful during power-stage development and isolated subassembly testing, but it is not required for ordinary single-input prototype operation.

The multi-output option must not encourage bypassing the intended system power architecture during normal integration. Once the EFIS power tree is established, end-to-end tests should feed the intended instrument input and verify its own regulators under realistic loading.

### Bench lead system

Use the PSU's standard 4 mm terminals as the common bench interface and keep dedicated, clearly identified leads/adapters for crocodile clips, bare wire, header pins and USB-C power. Leads used for direct low-voltage PCB work should be short, correctly rated and polarity-marked. Never assume a USB-C breakout performs USB Power Delivery negotiation unless that specific module is designed to do so.

## Order now — core prototype reference

| Item | Exact/reference choice | Qty | Purpose / notes |
|---|---|---:|---|
| MCU module | **Espressif ESP32-S3-WROOM-1-N16R2** | 2 | 16 MB Quad flash, 2 MB Quad PSRAM; second unit is a development spare. Bare module is for carrier-PCB development; use a compatible development board for breadboard work if already available. |
| Attitude IMU | **Bosch SHUTTLE BOARD 3.0 BMI088** | 1 | SPI attitude sensor; rigid aircraft-axis mounting. Bosch shuttle board is 22 x 14 mm and uses 1.27 mm-pitch connection. |
| Round display | **Newhaven NHD-2.1-480480AF-ASXP** | 1 | 2.1-inch 480 x 480 high-brightness round IPS, ST7701S. Already ordered/shipped. |
| Display bench adapter | **Newhaven NHD-FFC40** | 1 | Breaks out the 40-way display FFC for bench work. |
| Display FFC | **40-position, 0.5 mm pitch FFC/FPC cable**, compatible orientation with display/adapter | 2 | One working cable plus spare. Verify contact orientation and length against the NHD-FFC40 before ordering. Do not assume same-side/opposite-side until connector orientation is checked physically. |
| Backlight driver | **Adafruit TPS61169 breakout, PID 6354** | 1 | Constant-current boost driver; PWM brightness from ESP32. |
| Rotary/push control | **Bourns PEC09-2320F-T0015** | 1 | 30-detent/15-PPR-class rotary encoder with push switch; M7 x 0.75 mounting. |
| Bench GPIO expander | **Microchip MCP23008-E/P** | 1 | Through-hole bench prototype; final carrier will use an appropriate SMD version. |
| Pressure module | **Adafruit BMP585 Ported I2C breakout, PID 6413** | 1 | First static-pressure/altimeter development sensor. Use I2C. Port allows static tubing to be attached without engineering a sensor plenum. |
| Pressure-sensor cable | **STEMMA QT / Qwiic JST-SH 4-pin cable**, 100–200 mm | 2 | BMP585 bench connection plus spare. JST-SH is 1.0 mm pitch. |
| QT breadboard adapter | **Adafruit Qwiic / STEMMA QT breakout PID 5961** or equivalent JST-SH-to-0.1-inch breakout | 1 | Makes the BMP585 QT connection convenient on a breadboard/custom wiring loom. |
| Magnetic heading sensor | **PNI RM3100-CB, P/N 14754** | 1 | Remote three-axis magnetometer. Final aircraft harness/connector is intentionally not frozen yet. |
| Bench power supply | **Choose one: Korad KA3005P or Siglent SPD3303X-E** | 1 | Adjustable voltage plus current limiting. Korad is sufficient for most EFIS work; Siglent adds simultaneous independent rails. |
| Bench PSU lead/adaptor set | 4 mm banana-based interchangeable leads | 1 set | Include crocodile, bare-wire/header and suitable USB-C power breakout/adaptor arrangements. |
| Solderless breadboard | Good-quality full-size board | 1 | Initial sensor/control integration. |
| Prototyping wire | 22–26 AWG solid-core hookup wire assortment | 1 set | Bench only. Loose Dupont wiring is not acceptable in the assembled aircraft article. |
| Header pins | 2.54 mm breakaway male/female headers | 1 set | Bench breakouts and MCP23008. |

## BMI088 bench connection — verify before purchase

The Bosch BMI088 Shuttle Board 3.0 exposes its connections on **1.27 mm pitch**. Do not buy a guessed generic 2.54 mm adapter. Obtain either the mating Bosch/Application-Board-compatible socket arrangement or a verified 1.27 mm breakout/interposer after checking the actual supplied shuttle board. The final aircraft installation should use a rigid, positively retained connection rather than loose jumper wires.

## Sensors frozen for the EFIS

| Function | Selected source | Status |
|---|---|---|
| Attitude | **Bosch BMI088** | Frozen |
| Static pressure / altitude | **Bosch BMP585**, initially Adafruit ported PID 6413 | Frozen sensor; final physical implementation pending testing |
| Magnetic heading | **PNI RM3100-CB 14754**, remote mounted | Frozen |

The BMP585 ported breakout is intended to run over **I2C**. This avoids relying on SPI capability for this particular breakout/sensor combination and gives a simple four-wire bench interface. Default breakout I2C address is 0x47 (0x46 with SDO/address selection).

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

## Measure before ordering — static system

Do **not** order the final static plumbing yet. First measure/identify:

- existing Skyranger static tube outside diameter
- inside diameter if accessible
- tube material
- where the EFIS will tee into the static system
- approximate tubing run from tee to instrument
- available clearance behind the instrument panel.

After those measurements, freeze the tee, tube, bulkhead/barbed fitting and leak-test arrangement. The enclosure currently provides a reinforced 12 mm `STATIC` service boss with a deliberately undersize 3 mm pilot hole.

## Survey before ordering — remote magnetometer installation

The RM3100-CB should be remote from the ESP32, LCD/backlight currents, power converters, loudspeakers, steel structure/fasteners and other magnetic disturbances. Before ordering the final harness, choose a candidate location and determine approximate cable length and routing. The bracket must be rigid and non-magnetic with unambiguous **FWD / UP / lateral** orientation marks. The enclosure provides a 12 mm `MAG` service boss with a 3 mm pilot hole so the final cable gland/connector can be machined later.

## Mechanical items — later prototype stage

| Item | Target / status |
|---|---|
| Enclosure | Current OpenSCAD design; engineering filament such as ASA/ABS, not PLA |
| Front optical window | 62 mm x 2 mm hard-coated anti-reflective polycarbonate; final supplier/order specification still to freeze |
| M5 brass inserts | Four rear mounting provisions; exact insert dimensions to be verified against CAD before purchase |
| Panel fasteners | Fit to aircraft panel after physical trial; use secure locking method |
| Static fitting | Pending aircraft tube measurement |
| Magnetometer cable gland/connector | Pending installation survey |

## Functional dependency map

| EFIS page | Required real source |
|---|---|
| Horizon/PFD | BMI088 + live quaternion AHRS |
| Altimeter | BMP585 static pressure + QNH |
| Compass | RM3100-CB + BMI088 attitude for tilt-compensated magnetic heading |
| Future TRK/GS fields | GNSS; always explicitly labelled **TRK** and **GS**, never magnetic HDG or IAS |

## Purchase sequence

**Stage 1 — buy now:** display + FFC adapter/cables, BMI088, BMP585 ported module + QT cables/breakout, RM3100-CB, TPS61169, PEC09, MCP23008, **one suitable current-limited bench PSU**, banana/adaptor leads and normal bench materials. Track actual orders and deliveries in the purchasing-status table at the top of this file.

**Stage 2 — bench integration:** prove display, controls, BMI088, pressure and magnetic sensor interfaces; develop AHRS/altimeter/compass firmware; test invalid/stale-data behavior; record measured power consumption in `docs/POWER_BUDGET.md`.

**Stage 3 — aircraft measurements:** measure static plumbing and survey remote magnetometer location/cable routing.

**Stage 4 — freeze physical interfaces:** choose static fitting, magnetometer connector/harness, optical window hardware and final mounting details; update enclosure accordingly.

**Stage 5 — custom carrier PCB:** resume PCB design only after the physical interfaces above are frozen.

## Safety / configuration rule

This remains an experimental **supplementary/non-primary** flight instrument. Bench simulation must be unmistakably identified and disabled for aircraft-use firmware. Missing, stale or implausible sensor data must invalidate the relevant indication rather than freezing a plausible value.

See `docs/POWER_BUDGET.md`, `docs/SENSORS.md`, `docs/ENCLOSURE.md`, `docs/SIMULATION.md`, `hardware/` and `docs/user-guides/`.
