# Prototype procurement status — 16 September 2026

This checkpoint records delivery evidence supplied for Stage 1 and Stage 2 prototype parts. `BOM.md` remains the authoritative purchasing checklist; this note records the evidence and the immediate remaining purchase list.

## Confirmed received

The supplied RS delivery note confirms **Newhaven NHD-FFC40 40-pin FFC-to-through-hole adapter**, RS stock 723891, quantity 1.

The supplied DigiKey paperwork confirms receipt of:

- **ESP32-S3-WROOM-1-N16R2**, DigiKey P/N 5402-ESP32-S3-WROOM-1-N16R2CT-ND, quantity 2.
- **Adafruit TPS61169 LED driver**, DigiKey P/N 1528-6354-ND, quantity 1.
- **Bourns PEC09-2320F-T0015 rotary encoder**, quantity 1.
- **Microchip MCP23008-E/P I/O expander**, quantity 1.
- **Bosch Shuttle Board 3.0 BMI088**, DigiKey P/N 828-SHUTTLEBOARD3.0BMI088-ND, quantity 1.

The photographs supplied at this checkpoint do **not** show delivery paperwork for the separately ordered Newhaven NHD-2.1-480480AF-ASXP display, so it remains `ORDERED / SHIPPED` until physical receipt is confirmed.

## Stage 1 — still required

1. Confirm receipt of the **Newhaven NHD-2.1-480480AF-ASXP** single display.
2. **40-position 0.5 mm FFC/FPC cable(s)** compatible with the display and NHD-FFC40; verify contact orientation and length before ordering.
3. A **temporary carrier/breakout for the bare ESP32-S3-WROOM-1-N16R2** providing usable GPIO and programming/power access. Do not assume a generic ESP32-S3 development board accepts the bare module.
4. One current-limited bench PSU: **Korad KA3005P** is the economical preferred option; **Siglent SPD3303X-E** remains the premium alternative. Only one is required.
5. Bench PSU leads, a suitable USB-C power/data cable, solderless breadboard, 22–26 AWG prototype wire and 2.54 mm headers, unless already available in the workshop.

Stage 1 is not ready for physical bring-up until the processor can be safely mounted/programmed, the display can be connected through the correct FFC, and a current-limited 5 V bench supply/interconnect arrangement is available.

## Stage 2 — still required

1. A verified **1.27 mm-pitch mating adapter/interposer for the Bosch BMI088 Shuttle Board 3.0**. Do not buy a guessed 2.54 mm adapter.
2. **Adafruit BMP585 Ported I2C breakout, PID 6413**, quantity 1.
3. **STEMMA QT/Qwiic JST-SH 4-pin cables**, 100–200 mm, quantity 2.
4. **Adafruit Qwiic/STEMMA QT breakout PID 5961** or verified equivalent, quantity 1.
5. **PNI RM3100-CB, P/N 14754**, quantity 1.
6. **GNSS receiver**, exact part still to be selected. It must provide latitude, longitude, fix validity/type, freshness and an explicit horizontal-accuracy estimate suitable for the adopted colour-coded position-quality display.
7. A **GNSS bench antenna** compatible with the selected receiver; do not order it before the receiver RF interface and active/passive antenna requirement are known.

The GNSS receiver and antenna remain a selection task rather than an immediate blind purchase. `TRK`/`GS` remain GNSS-derived and separate from magnetic `HDG` and air-data indications.

## Do not buy yet

Stage 3+ aircraft static fittings, final RM3100 harness/mount, final GNSS installation hardware, optical window, final enclosure hardware, custom carrier PCB production, and aircraft 12 V input/protection hardware remain gated by bench validation and aircraft surveys.
