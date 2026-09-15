# ESP32 EFIS iPhone/iPad Simulator

Native SwiftUI design/bench simulator for ESP32 EFIS. It is not a flight-navigation application; displayed flight data is synthetic.

## Features

- adaptive layout based on the **actual available window size**, not a particular iPhone/iPad model
- supports iPhone and iPad in portrait and landscape, including narrow/short windows and iPad multitasking sizes
- automatically switches between side-by-side and stacked layouts
- instrument diameter is calculated from available width and height while remaining square
- compact layouts become vertically scrollable instead of clipping controls
- panel selector falls back from segmented control to a menu when horizontal space is insufficient
- Horizon/PFD, classic three-pointer Altimeter and rotating-card Compass
- tap the round instrument or use the panel selector to change pages
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

In Xcode select **any available iPhone or iPad simulator** and press **Run**. Rotate the simulator and, on iPad, try different multitasking/window widths: the interface recomputes its layout from the space SwiftUI provides.

The generated `.xcodeproj` is a build product; `project.yml` and the Swift sources are the maintained project definition. The app targets both iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) and iOS 17 or later.

## Adaptive-layout design

`ContentView` uses `GeometryReader` to measure the live container dimensions. Wide windows use a large instrument beside the controls. Compact windows use a stacked, scrollable presentation. The instrument is always constrained to a 1:1 aspect ratio and scales rather than relying on a fixed device frame. `ViewThatFits` supplies a compact alternative for controls that cannot fit horizontally.

This means support is based on available screen/window geometry rather than a list of hard-coded Apple device resolutions, which also makes the simulator resilient to future iPhone/iPad screen sizes.

## Relationship to the physical instrument

The simulator's visual and behavioral specification evolves with the ESP32 renderer. It is a fast design/failure-injection tool, not an independent source of flight-instrument requirements. The current UI exposes values directly; a future revision can add a graphical knob with the same short/long-press semantics as the physical PEC09.

## Safety

Simulator values must never become fallback values in an aircraft build. ESP32 aircraft-use firmware retains independent fail-obvious validity handling and must have bench simulation disabled.
