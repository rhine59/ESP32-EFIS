# ESP32 EFIS project images

This directory contains project documentation images that can be regenerated or revised as the design changes.

## Authoritative regenerated diagrams

- `efis-system-architecture.svg` — functional bench-prototype architecture showing the selected ESP32-S3-WROOM-1-N16R2, Newhaven NHD-2.1-480480AF-ASXP, BMI088, BMP585, RM3100-CB, MCP23008/PEC09 controls, TPS61169 backlight driver, native USB and current-limited bench power. It is deliberately **not** a connector-level wiring diagram; use `docs/WIRING.md` and `docs/HARDWARE.md` for authoritative signal assignments.
- `project-stage-roadmap.svg` — visual form of the BOM procurement stages: bench bring-up, sensor integration, aircraft survey, physical-interface freeze, custom PCB and aircraft installation/validation.
- `../../enclosure/images/flight-development-case-preview.svg` — existing generated enclosure preview maintained with the enclosure sources.

## Accuracy rule

Generated/illustrative images must never override the text engineering records. Exact GPIO assignments, connector pins, electrical limits and component variants come from the current project documentation and source files. If an image conflicts with `BOM.md`, `docs/HARDWARE.md`, `docs/WIRING.md`, `docs/POWER_BUDGET.md` or the applicable component datasheet, the image is wrong and must be corrected.

Earlier conversational concept artwork is not treated as authoritative because some versions contained guessed wiring, obsolete display details or illustrative components. Those images should not be restored unchanged. Replacement images should be generated from the current repository state.

## Current design notes reflected in these images

- MCU baseline: ESP32-S3-WROOM-1-N16R2, 16 MB Quad flash / 2 MB Quad PSRAM.
- Display baseline: Newhaven NHD-2.1-480480AF-ASXP, 480 × 480, RGB565 plus 9-bit startup/configuration.
- Sensor baseline: BMI088 attitude, BMP585 pressure/altitude, remote RM3100-CB magnetic heading.
- Development power: regulated current-limited bench supply; Korad KA3005P and Siglent SPD3303X-E remain BOM alternatives.
- Final aircraft power stage and custom carrier PCB remain later-stage work and must not be inferred from bench illustrations.
- Instrument remains supplementary/non-primary.
