# ESP32 EFIS iPhone/iPad Simulator

Native SwiftUI design/bench simulator for ESP32 EFIS. It is not a flight-navigation application; displayed flight data is synthetic.

## Synchronisation with the ESP32/QEMU emulator

The Swift simulator is maintained in step with the current ESP32/QEMU instrument behaviour. It is not an independent instrument design. Accepted renderer behaviour is mirrored here so the simulator is useful for interactive/manual testing while QEMU remains the authoritative execution of the ESP32 firmware renderer.

Current synchronised behaviour includes:

- accepted Artificial Horizon pitch/bank direction and fail-obvious `ATT FAIL`
- accepted three-pointer Altimeter behaviour, digital altitude, progressive >10,000-ft hatching, rectangular hPa Kollsman/QNH window and `ALT FAIL`
- current Compass rotating card with N/E/S/W references and three-digit heading
- heading bug screen angle calculated as selected heading minus current aircraft heading
- fail-obvious `HDG FAIL`
- permanent red `SIM` marking on synthetic displays
- QNH range 950–1050 hPa
- heading-bug range 000–359°

The Swift drawing is a native SwiftUI representation, not a pixel-for-pixel copy of the RGB565 framebuffer. The ESP32/QEMU renderer remains authoritative for exact 480×480 pixel geometry.

## QEMU Compass acceptance sequence

The simulator includes a **QEMU COMPASS TEST** switch. When enabled it locks the simulator to the Compass, fixes the selected heading bug at 060°, disables conflicting manual controls and repeats the same twelve six-second states used by the current QEMU firmware harness:

1. 000° / north
2. 045° / north-east
3. 090° / east
4. 135° / south-east
5. 180° / south
6. 225° / south-west
7. 270° / west
8. 315° / north-west
9. 350° through 010° north-wrap movement
10. continuous heading rotation
11. heading failure
12. recovery to 000° north

This makes it possible to compare the Swift simulator directly with the current QEMU acceptance run. At 000° the 060° heading bug is 60° clockwise from the lubber line; at 060° it is at the top; at 090° it is 30° counter-clockwise from the top.

## Features

- adaptive layout based on the actual available window size
- iPhone and iPad portrait/landscape support, including compact and multitasking widths
- automatic side-by-side or stacked layouts
- scrollable compact layout rather than clipped controls
- Horizon/PFD, three-pointer Altimeter and rotating-card Compass
- tap the round instrument or use the panel selector to change pages when the QEMU sequence is off
- manual pitch, roll, altitude, heading, QNH and heading-bug controls
- AUTO FLIGHT for general continuous exercising
- QEMU COMPASS TEST for exact current Compass acceptance sequencing
- independent attitude/altitude/heading validity switches for manual failure testing
- prominent synthetic-data indications

## Generate and run the Xcode project

The repository includes an XcodeGen `project.yml`, so no manual Xcode target creation is required.

```bash
cd ~/Documents/Xcode/ESP32-EFIS/simulator
brew install xcodegen       # only if xcodegen is not already installed
xcodegen generate
open ESP32EFISSimulator.xcodeproj
```

In Xcode select any available iPhone or iPad simulator and press **Run**. The generated `.xcodeproj` is a build product; `project.yml` and the Swift sources are the maintained project definition. The app targets iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) and iOS 17 or later.

## Relationship to QEMU and physical hardware

There are three distinct test layers:

**Swift simulator** — interactive design and manual failure-injection environment. It should mirror the current accepted presentation and QEMU scenarios.

**ESP32/QEMU emulator** — executes the ESP32 firmware and actual RGB565 renderer at the display's native 480×480 geometry. This is authoritative for firmware presentation acceptance before hardware exists.

**Physical prototype** — authoritative for the Newhaven panel, sensor acquisition, MCP23008/PEC09 controls, brightness, timing, electrical integration and real-world sensor validity/staleness behaviour.

When a presentation or test sequence changes in QEMU, the corresponding Swift simulator behaviour and this README should be updated in the same development stage.

## Safety

Simulator values must never become fallback values in an aircraft build. ESP32 aircraft-use firmware retains independent fail-obvious validity handling and must have bench simulation disabled.
