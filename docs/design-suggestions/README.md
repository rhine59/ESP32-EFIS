# ESP32 EFIS — Design Suggestion Image Register

This directory is for **design inspiration and reference material only**. Images here are not authoritative engineering drawings, wiring diagrams, BOM definitions, PCB layouts, mechanical dimensions or accepted flight-display specifications unless a specific idea is separately adopted in the project requirements/status documentation.

The authoritative project remains a **single physical Newhaven NHD-2.1-480480AF-ASXP 2.1-inch 480×480 round display** with selectable instrument pages. Current hardware, wiring, enclosure and sensor decisions are governed by the corresponding project documents, especially `docs/WIRING.md`, `docs/SENSORS.md`, `docs/GNSS_DISPLAY.md`, `docs/ENCLOSURE.md`, `BOM.md` and `docs/PROJECT_STATUS.md`.

## Reference set — 16 September 2026

The following eight images were supplied as design suggestions. Store the original image files under `docs/design-suggestions/images/` using the filenames below.

| # | Filename | Classification | Useful ideas | Important conflicts / limitations |
|---|---|---|---|---|
| 01 | `01-electronics-associated-circuitry.jpeg` | Electronics / PCB presentation | PCB documentation style, functional blocks, labelled aircraft connector, power-protection presentation, enclosure overview | Shows two displays, BMP388, different display/interface/memory assumptions and unfrozen aircraft-power details. Reference only. |
| 02 | `02-wiring-diagram-dual-display.jpeg` | Wiring/interconnection presentation | Colour-coded signal groups, connector pinout box, optional-interface styling, installation overview | Dual displays; SPI displays; BMP388; development board; RTC/microSD; particular GNSS implementation. Does not supersede `docs/WIRING.md`. |
| 03 | `03-bench-prototype-wiring.jpeg` | Bench prototype wiring/layout | Single-display bench arrangement, short display wiring, labelled harnesses, common power distribution, remote RM3100, encoder/MCP23008 relationship | GPIO table is illustrative rather than the frozen map; temporary development-board representation; GNSS choice not frozen. |
| 04 | `04-bench-system-architecture.jpeg` | Bench prototype system architecture | Strong separation of functional architecture from exact wiring; single-display architecture; clear supplementary/non-primary labelling | Simplified power; RM3100 interface not frozen; statement that GNSS is not required conflicts with the newer Stage-2 GNSS requirement. |
| 05 | `05-combined-system-enclosure-pcb-bench.jpeg` | Combined presentation concept | Four-panel documentation layout, front/side enclosure views, architecture-to-bench progression, PSU comparison, eventual actual bench photograph | Uses a 4.3-inch rectangular display and corresponding enclosure; PCB/wiring are conceptual and are not current hardware. |
| 06 | `06-single-display-exploded-enclosure.jpeg` | Single-display enclosure concept | Bezel → display → mounting plate → electronics → body → rear-cover assembly concept; useful exploded-view presentation | Ø66 mm body, 57 mm cut-out, 62 mm PCD, M3 hardware, ~38 mm depth, M12 gland and PCB geometry are not all physically validated. `docs/ENCLOSURE.md`/CAD remain authoritative. |
| 07 | `07-single-display-prototype-wiring.jpeg` | Single-display wiring concept | Clear signal grouping, bench-power block, USB presentation, prototype-vs-aircraft warning | Example 3.3 V regulator conflicts with adopted TPS62162-Q1; TPS61169 supply depiction conflicts with adopted 5 V feed; display/GPIO wiring is not authoritative; RM3100 interface remains to be frozen. |
| 08 | `08-display-concepts-gnss-accuracy.jpeg` | Horizon/PFD + Compass/HSI display concepts | GNSS position and reported-horizontal-accuracy presentation on both pages; useful information hierarchy and accuracy legend | Two round images represent **two pages of one physical display**, not two displays. IAS/TAS, navigation bearing/distance/ETA and some symbology require valid data sources before adoption. TRK remains distinct from HDG and GS must not be presented as IAS. |

## Ideas already adopted independently

The following ideas visible in the reference set correspond to decisions already adopted elsewhere in the project and therefore do not depend on these pictures for authority:

- one physical 2.1-inch 480×480 round Newhaven display;
- selectable Horizon/PFD, Altimeter and Compass pages;
- supplementary/non-primary instrument status and fail-obvious invalid/stale data;
- BMI088 attitude source, BMP585 static-pressure source and remote RM3100 magnetic source;
- MCP23008 with PEC09 rotary/push control;
- TPS61169 display-backlight driver;
- GNSS latitude/longitude on Horizon/PFD and Compass with coordinate values colour-coded by **receiver-reported horizontal accuracy**;
- GNSS stale/no-fix state must not retain plausible frozen coordinates;
- GNSS `TRK`/`GS` semantics remain distinct from heading (`HDG`) and airspeed (`IAS`).

## Ideas worth carrying forward as proposals

The reference set suggests several presentation practices worth considering without changing the frozen engineering design: colour-coded harness/signal documentation; a clearly labelled aircraft-interface connector once its pinout is validated; separate architecture and exact-wiring drawings; front/side/exploded enclosure documentation after physical measurements; an actual photograph of the validated bench prototype; and a compact combined project-overview sheet for builders.

These remain **reference/proposed presentation ideas** until explicitly adopted in `docs/PROJECT_STATUS.md` or the relevant authoritative document.

## Rules for using these images

1. Never derive GPIO numbers, connector pins, supply voltages, mechanical dimensions or component substitutions from a reference image when authoritative project documentation differs.
2. Never infer that an image represents completed hardware or validation.
3. Preserve the one-physical-display architecture. Side-by-side Horizon/Compass pictures are page comparisons only.
4. Treat generated or illustrative PCB/enclosure renderings as concepts until checked against the real components, CAD, schematic and aircraft measurements.
5. When a useful idea is adopted, record the decision in the authoritative project documentation rather than relying on the image itself.

## Image installation

The GitHub text connector cannot upload the binary JPEGs from the chat directly. After exporting/copying the eight supplied originals to the repository, place them in:

```text
docs/design-suggestions/images/
```

using the filenames in the register above, then commit them normally. The register is intentionally committed first so the purpose and limitations of the images are already documented before the binaries enter the repository.
