# ESP32 EFIS iPhone/iPad Simulator

Native SwiftUI design/bench simulator for the ESP32 EFIS instrument. It is not a flight-navigation application and all displayed data is synthetic unless a future explicitly identified source is added.

## Features

- adaptive iPhone portrait and iPad/landscape layouts
- Horizon/PFD, classic three-pointer Altimeter and rotating-card Compass
- tap the round instrument to cycle pages
- manual pitch, roll, altitude, heading, QNH and heading-bug controls
- AUTO FLIGHT continuously exercises all displays
- independent attitude/altitude/heading validity switches for failure testing
- prominent `SIMULATOR — SYNTHETIC DATA ONLY` indication

## Xcode setup

Create an iOS App project named `ESP32EFISSimulator` using SwiftUI and Swift, with iPhone and iPad device families enabled. Place the three Swift source files in the app target. Deployment target can be set to the current iOS version used for development; the code intentionally uses standard SwiftUI APIs.

The simulator's visual/behavioral specification should evolve with the ESP32 renderer. It is a fast design tool, not an independent source of flight-instrument requirements.

## Controls versus physical PEC09

The segmented panel selector and tapping the instrument emulate short-press page changes. Sliders expose the values that the hardware/sensors will ultimately supply. QNH and heading-bug controls emulate rotary-setting behavior. A later revision can add a graphical rotary knob with short/long press semantics identical to the PEC09.

## Safety

Simulator values must never be copied into an aircraft build as fallback sensor values. ESP32 aircraft-use firmware must retain fail-obvious validity handling and have bench simulation disabled.
