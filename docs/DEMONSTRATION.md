# ESP32 EFIS — QEMU video demonstration

This repository can produce a video demonstration of the **actual ESP32 firmware renderer running in Espressif QEMU**. The demonstration is synthetic and is not evidence of physical sensor, display or aircraft validation.

## What the demonstration shows

The demonstration is intended to show the implemented/accepted display functions in one continuous sequence:

- Artificial Horizon: level, pitch up/down, bank left/right, combined pitch/bank, `ATT FAIL`, recovery
- Altimeter: representative low/mid/high altitudes, three pointers, digital altitude, progressive 9-o'clock >10,000-ft hatching, compact 3-o'clock Kollsman scale, `ALT FAIL`, recovery
- Compass: cardinal/intercardinal headings, 350→010 north crossing, continuous rotation, selected 060° heading bug, `HEADING FAIL`, recovery
- permanent red `SIM` indication and deterministic on-screen test captions

The QEMU framebuffer is 480×480 RGB565, matching the native pixel dimensions of the selected Newhaven display. The recording therefore demonstrates firmware graphics rather than a separately drawn promotional mock-up.

## Build the demonstration

From the repository root:

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
source scripts/efis-env.sh
zsh scripts/build-qemu.sh --clean
```

## Record it on macOS

Run:

```bash
zsh scripts/record-qemu-demo.sh
```

The script starts QEMU and then invokes the built-in macOS screen recorder in window-selection mode. Click the **QEMU instrument window** when prompted. Recording stops automatically after the configured demonstration duration and is written under `docs/media/` as a `.mov` file.

macOS may request **Screen Recording** permission for Terminal on the first run. If so, grant permission in System Settings and rerun the script.

To choose a different output file:

```bash
zsh scripts/record-qemu-demo.sh ~/Desktop/ESP32-EFIS-Demo.mov
```

To override the automatic recording duration:

```bash
EFIS_DEMO_SECONDS=120 zsh scripts/record-qemu-demo.sh
```

The QEMU console is saved separately as `firmware/qemu-demo.log` so the recorded sequence can be correlated with firmware scenario transitions.

## Optional post-production

The `.mov` is deliberately a clean source recording. It can subsequently be trimmed and captioned in iMovie, Final Cut Pro, DaVinci Resolve or another editor without changing the underlying instrument imagery. A useful final title is:

> **ESP32 EFIS — Firmware/QEMU Demonstration**  
> Synthetic development data · supplementary/non-primary instrument

Do not remove the on-screen red `SIM` marker or edit the video in a way that suggests real sensor/aircraft validation.

## Validation meaning

The video demonstrates functions already accepted in QEMU. It does **not** demonstrate the physical Newhaven LCD, BMI088, BMP585, RM3100, MCP23008/encoder, PSRAM, power electronics, enclosure or aircraft installation. Those activities remain pending physical hardware and are tracked in `PROJECT_STATUS.md`.
