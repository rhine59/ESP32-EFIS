# ESP32 EFIS iPhone/iPad Simulator

Native SwiftUI design/bench simulator for ESP32 EFIS. It is not a flight-navigation application; displayed flight data is synthetic.

## Features

- adaptive iPhone portrait and iPad/landscape layouts
- Horizon/PFD, classic three-pointer Altimeter and rotating-card Compass
- tap the round instrument or use the segmented selector to change pages
- manual pitch, roll, altitude, heading, QNH and heading-bug controls
- AUTO FLIGHT continuously exercises all displays
- independent attitude/altitude/heading validity switches for failure testing
- prominent `SIMULATOR — SYNTHETIC DATA ONLY` indication

## Generate and run the Xcode project

The repository includes an XcodeGen `project.yml`, so no manual Xcode target creation is required.

```bash
cd ~/Documents/Xcode/ESP32-EFIS/simulator
brew install xcodegen       # only if xcodegen is not already installed
xcodegen generate
open ESP32EFISSimulator.xcodeproj
```

In Xcode select an iPhone or iPad simulator and press **Run**. The generated `.xcodeproj` is a build product; `project.yml` and the Swift sources are the maintained project definition.

The app targets both iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) and iOS 17 or later.

## Relationship to the physical instrument

The simulator's visual and behavioral specification evolves with the ESP32 renderer. It is a fast design/failure-injection tool, not an independent source of flight-instrument requirements. The current UI exposes values directly; a future revision can add a graphical knob with the same short/long-press semantics as the physical PEC09.

## Safety

Simulator values must never become fallback values in an aircraft build. ESP32 aircraft-use firmware retains independent fail-obvious validity handling and must have bench simulation disabled.
