# EFIS Parts Cost Model

**Status:** planning estimate; update as the BOM and production design are frozen.

This document records the current approximate parts-cost target for one completed ESP32-EFIS. It separates repeatable production parts from development equipment such as programmers, breadboards, adapters and spares.

## Current one-off estimate

| Production item | Approximate cost |
|---|---:|
| Newhaven 2.1-inch 480×480 display | £25–35 |
| ESP32-S3-WROOM-1-N16R2 | £5–6 |
| BMI088 IMU | £20–30 |
| BMP585 static/barometric pressure sensor | £15–20 |
| RM3100 magnetometer | £35–50 |
| GNSS receiver + antenna | £20–35 |
| Backlight driver + control electronics | £10–15 |
| Aircraft power conversion/protection/filtering | £15–25 |
| Custom 4-layer PCB, one-off allocation | £15–30 |
| Connectors, PITOT/STATIC fittings, USB/data etc. | £15–25 |
| PEC09 encoder, passives and internal wiring | £10–15 |
| Enclosure, optical window and hardware | £20–35 |
| **Estimated total** | **approximately £205–£285** |

Use **approximately £250 per finished EFIS** as the present planning figure and **£300 as a useful contingency target** until the remaining major items are frozen.

## Cost target

**Design target:** aim for a repeatable production BOM of **£250 or less at modest quantities (approximately 10–25 units)** where this can be achieved without compromising the adopted supplementary-instrument safety, reliability, environmental or serviceability requirements.

The cost target is subordinate to correct engineering. A cheaper component must not replace a validated component merely to meet the target.

## Why prototype cost is higher

Development expenditure is not equivalent to the per-unit production BOM. Prototype work also includes items such as:
- ESP-Module-Prog-1 programmer;
- NHD-FFC40 bench adapter;
- breadboards, jumper leads and test wiring;
- sensor development/breakout boards;
- spare ESP32 modules;
- development fixtures and test equipment;
- prototype PCB/enclosure iterations.

These are reusable development assets and should not automatically be allocated in full to each finished instrument.

## Expected quantity effects

At 10–25 units, component quantity pricing, consolidated PCB manufacture/assembly and removal of development-only breakout/adaptor boards should reduce unit cost. The eventual carrier PCB should integrate appropriate production components directly where technically sensible.

Do not assume a volume saving until supplier quotations and the production BOM are available.

## Major remaining cost uncertainties

The current estimate should be revisited when these are frozen:
1. GNSS receiver and antenna;
2. RM3100 production implementation;
3. custom carrier PCB and assembly method;
4. protected aircraft 12 V power input;
5. STATIC bulkhead fitting and tubing;
6. final enclosure/window manufacturing process;
7. connectors and external data interfaces;
8. production test/calibration hardware allocation.

## Exclusions

The figure is a **parts/BOM estimate**, not a retail price. It excludes engineering/development labour, software development, assembly labour, calibration, production testing, scrap/yield, tooling, certification/approval work, packaging, documentation, warranty/support, payment/platform fees, VAT, shipping, distributor minimum-order effects and commercial margin.

The EFIS remains an experimental supplementary/non-primary instrument unless and until a separate applicable approval/certification path is completed.

## Maintenance

Use `BOM.md` as the authoritative component/procurement list. Update this cost model whenever a major BOM component, enclosure manufacturing method or production quantity assumption changes.
