# ESP32 EFIS iPhone/iPad Simulator

Native SwiftUI design/bench simulator for ESP32 EFIS. It is not a flight-navigation application; displayed flight data is synthetic.

## Synchronisation with the ESP32/QEMU emulator

The Swift simulator is maintained in step with the accepted ESP32/QEMU instrument behaviour. It is not an independent instrument design. QEMU remains authoritative for the actual 480×480 RGB565 firmware renderer; Swift provides interactive/manual testing on iPhone/iPad.

Current synchronised behaviour includes:

- accepted Artificial Horizon pitch/bank direction, 5°/10° pitch ladder hierarchy, fixed aircraft symbol, bank-angle scale/pointer and fail-obvious `ATT FAIL`
- accepted three-pointer Altimeter, digital altitude and `ALT FAIL`
- accepted 9-o'clock progressive >10,000-ft annular hatching sector
- accepted compact curved **3-o'clock Kollsman pressure scale**, approximately 8 hPa total visible span, fixed selected-QNH index and heavy 1013.25 hPa datum; the obsolete rectangular QNH/Kollsman box is not part of the accepted design
- accepted Compass rotating card with N/E/S/W references, three-digit heading, continuous north wrap and fail-obvious `HDG FAIL`
- heading bug screen angle calculated as selected heading minus current aircraft heading
- permanent red `SIM` marking on synthetic displays
- QNH range 950–1050 hPa
- heading-bug range 000–359°

The Swift drawing is a native SwiftUI representation, not a pixel-for-pixel copy of the RGB565 framebuffer.

## Acceptance sequences

The firmware/QEMU scenario engine contains deterministic acceptance states for all three instruments. The Swift simulator supports the same manual data ranges and failure injection, and includes the exact current twelve-state Compass acceptance sequence as an automated switch. The accepted firmware sequences are documented in `../docs/SIMULATION.md` and the project validation matrix in `../docs/PROJECT_STATUS.md`.

### QEMU Compass acceptance sequence

The **QEMU COMPASS TEST** switch locks the simulator to the Compass, fixes the selected heading bug at 060°, disables conflicting manual controls and repeats the same twelve six-second states used by the accepted QEMU firmware harness:

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

At 000° the 060° heading bug is 60° clockwise from the lubber line; at 060° it is at the top; at 090° it is 30° counter-clockwise from the top.

## Features

- adaptive layout based on the actual available window size
- iPhone and iPad portrait/landscape support, including compact and multitasking widths
- automatic side-by-side or stacked layouts
- scrollable compact layout rather than clipped controls
- accepted Horizon/PFD, three-pointer Altimeter and rotating-card Compass presentations
- tap the round instrument or use the panel selector to change pages when an automated sequence is off
- manual pitch, roll, altitude, heading, QNH and heading-bug controls
- AUTO FLIGHT for general continuous exercising
- QEMU COMPASS TEST for exact accepted Compass sequencing
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

**Swift simulator** — interactive design and manual failure-injection environment. It mirrors accepted presentation and test behaviour but is not a real sensor source.

**ESP32/QEMU emulator** — executes the ESP32 firmware and actual RGB565 renderer at the display's native 480×480 geometry. This is authoritative for firmware presentation acceptance while physical hardware is unavailable.

**Physical prototype** — eventually authoritative for the Newhaven panel, sensor acquisition, MCP23008/PEC09 controls, brightness, timing, electrical integration and real-world sensor validity/staleness behaviour. Physical validation is currently paused because hardware is unavailable.

When presentation or scenario behaviour changes in QEMU, the corresponding Swift simulator behaviour and documentation must be updated in the same development stage.

## Safety

Simulator values must never become fallback values in an aircraft build. ESP32 aircraft-use firmware retains independent fail-obvious validity handling and must have bench simulation disabled. A Swift or QEMU acceptance result is never recorded as physical sensor or aircraft validation.
