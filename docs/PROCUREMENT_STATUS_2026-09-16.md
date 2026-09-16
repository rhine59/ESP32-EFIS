# Prototype procurement status — 16 September 2026

This checkpoint records delivery evidence supplied for Stage 1 and Stage 2 prototype parts. `BOM.md` remains the authoritative purchasing checklist and now includes explicit purchase locations/references for all items that are ready to buy.

## Receipt-evidence rule

A supplied photograph of a delivery note that clearly identifies a BOM part and delivered quantity is accepted as evidence that the stated quantity has **arrived**. `BOM.md` should then be updated to `RECEIVED` without requiring a second confirmation. Order/dispatch evidence or a statement that an item is on the way is recorded as `ORDERED / IN TRANSIT`, not RECEIVED.

## Confirmed received from delivery-note photographs

The supplied **RS delivery-note photograph** confirms:

- **Newhaven NHD-FFC40 40-pin FFC-to-through-hole adapter**, RS stock `723891`, quantity **1 RECEIVED**.

The supplied **DigiKey delivery-note photograph/paperwork** confirms:

- **ESP32-S3-WROOM-1-N16R2**, quantity **2 RECEIVED**.
- **Adafruit TPS61169 LED driver PID 6354**, DigiKey `1528-6354-ND`, quantity **1 RECEIVED**.
- **Bourns PEC09-2320F-T0015 rotary encoder**, quantity **1 RECEIVED**.
- **Microchip MCP23008-E/P I/O expander**, quantity **1 RECEIVED**.
- **Bosch Shuttle Board 3.0 BMI088**, DigiKey `828-SHUTTLEBOARD3.0BMI088-ND`, quantity **1 RECEIVED**.

## In transit

The project owner confirms the **Newhaven NHD-2.1-480480AF-ASXP display is on the way**. It is therefore **ORDERED / IN TRANSIT**. It will move to RECEIVED after physical-arrival evidence/confirmation.

## Stage 1 — still required

1. Await the **Newhaven NHD-2.1-480480AF-ASXP** display. Source/reference retained in BOM: RS UK stock `286-351`; DigiKey is the alternate.
2. After the display arrives, verify contact orientation and length and buy **2 × 40-position 0.5 mm FFC/FPC cables**. Do not freeze a supplier part until that physical check is complete.
3. Buy **1 × Espressif ESP-Module-Prog-1** temporary solderless module carrier/programmer. Preferred source: **Mouser UK `356-ESPMODULEPROG1`**. Do not substitute Prog-1R without checking the spring-pin layout.
4. Buy one current-limited bench PSU: **Korad KA3005P** preferred economical option or **Siglent SPD3303X-E** premium alternative.
5. Obtain bench PSU leads, USB-C data/power cable, solderless breadboard, 22–26 AWG prototype wire and 2.54 mm headers unless already available.

Stage 1 is ready for physical bring-up once the processor can be safely mounted/programmed, the display is present and connected through the verified FFC arrangement, and a current-limited 5 V bench supply/interconnect arrangement is available.

## Stage 2 — still required

1. A verified **1.27 mm-pitch mating adapter/interposer for the Bosch BMI088 Shuttle Board 3.0**. Do not buy a guessed 2.54 mm adapter.
2. **Adafruit BMP585 Ported I2C/SPI PID 6413**, quantity 1. Preferred source: DigiKey UK; UK alternates The Pi Hut/Pimoroni when stocked.
3. **STEMMA QT/Qwiic JST-SH 4-pin cables**, 100–200 mm, quantity 2. Adafruit PID 4397 (150 mm) is a suitable length candidate subject to connector verification.
4. **Adafruit Qwiic/STEMMA QT breakout PID 5961**, quantity 1; DigiKey UK `1528-5961-ND`.
5. **PNI RM3100-CB P/N/SKU 14754**, quantity 1; source: PNI Sensor direct, subject to UK shipping/import-cost check.
6. **GNSS receiver**, exact part still to be selected. It must provide latitude, longitude, fix validity/type, freshness and an explicit horizontal-accuracy estimate.
7. **GNSS bench antenna** compatible with the selected receiver; do not order before the receiver RF interface and active/passive antenna requirement are known.

## Source-retention rule

Purchase locations are part of the BOM, not temporary research notes. When a part is selected, `BOM.md` should retain the preferred supplier, supplier stock/order number where known, and an alternate source where useful. Receiving a part does **not** remove its purchase source; the source remains for traceability and replacement/spare ordering.

## Do not buy yet

Stage 3+ aircraft static fittings, final RM3100 harness/mount, final GNSS installation hardware, optical window, final enclosure hardware, custom carrier PCB production, and aircraft 12 V input/protection hardware remain gated by bench validation and aircraft surveys.
