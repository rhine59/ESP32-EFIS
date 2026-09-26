# ESP32 EFIS iPhone/iPad Simulator

Native SwiftUI design/bench simulator for ESP32 EFIS. It is not a flight-navigation application; displayed flight data and OTA operations are synthetic/simulated.

## Scope

QEMU remains authoritative for the actual 480×480 RGB565 instrument renderer. Swift provides interactive instrument controls plus software-only rehearsal of maintenance networking and OTA user behaviour.

The simulator currently provides three areas:

- **Instruments** — accepted Horizon/PFD, Altimeter and Compass representations, manual controls, AUTO FLIGHT, GNSS position/accuracy presentation, validity/failure injection, deterministic acceptance sequences and an automated full demonstration suitable for screen recording.
- **Network** — phone-hotspot SSID/password and HTTPS manifest configuration plus a simulated Phone → Internet → TLS/OTA-server connection test.
- **Software Update** — definitive staged-release consumption flow, persistent auto-download preference, manual download, `ACTIVATE & REBOOT`, first-boot verification and rollback simulation.

Every synthetic instrument display retains conspicuous simulation marking. The OTA page is explicitly labelled **OTA USER-FLOW SIMULATION**.

## Full demonstration / video recording mode

The Instruments screen includes **RUN FULL DEMONSTRATION**. It automatically drives the single-display simulator through the principal instrument and validation functions so a clean demonstration can be recorded without manually operating every control.

The approximately 6 minute 25 second sequence demonstrates:

1. Horizon/PFD level presentation, pitch/roll movement, attitude failure and recovery.
2. Altimeter at representative altitudes, QNH change, >10,000-ft hatching, altitude failure and recovery.
3. Compass presentation, heading bug, rotating heading and heading failure/recovery.
4. GNSS latitude/longitude on Horizon and Compass through Excellent, Good, Fair, Weak, Poor, Stale and No Fix states. Coordinate colour follows the adopted reported-horizontal-accuracy bands; stale/no-fix does not leave plausible frozen coordinates.
5. A short automatic-flight segment.
6. The complete Horizon 12-state, Altimeter 14-state, Compass 12-state and GNSS 7-state acceptance suites.

While the demonstration is running, manual flight-data, settings, GNSS and failure controls are disabled to keep the recording deterministic. A status line shows elapsed/total demonstration time and the current section. **STOP FULL DEMONSTRATION** aborts the sequence. At completion the simulator returns to a valid Horizon/PFD state.

For a recording, start the simulator, open Instruments, begin the operating-system/Xcode Simulator screen recording, press **RUN FULL DEMONSTRATION**, and allow the sequence to complete. The red `SIM` marking remains visible throughout. The recording demonstrates the Swift simulator; it is not evidence of physical ESP32, sensor, GNSS or aircraft validation.

## OTA behaviour represented

The Docker administrator, not the EFIS user, controls what release is **PUBLISHED**. The simulator assumes it discovers only that published manifest.

`Automatically download next update` defaults ON. In the production design this permits download/verification to the inactive OTA slot only while the EFIS is in the appropriate maintenance/network-update context. It never permits automatic activation.

With auto-download ON:

```text
Check published release -> Download/verify -> UPDATE READY -> ACTIVATE & REBOOT -> self-test -> accept/rollback
```

With auto-download OFF:

```text
Check -> UPDATE AVAILABLE -> Download -> verify -> UPDATE READY -> ACTIVATE & REBOOT -> self-test -> accept/rollback
```

The simulator includes `Later` and a deliberate first-boot-failure switch. No real network request, ESP32 flash write, boot partition change or reboot occurs.

## Instrument synchronisation

The accepted instrument behaviour includes Horizon pitch/bank direction and fail-obvious `ATT FAIL`; classic three-pointer Altimeter with digital altitude, progressive >10,000-ft hatching, curved 3-o'clock Kollsman scale and `ALT FAIL`; rotating-card Compass with N/E/S/W, north wrap, heading bug and `HDG FAIL`; QNH 950–1050 hPa; heading bug 000–359°; GNSS latitude/longitude and reported horizontal-accuracy quality on Horizon and Compass; and permanent red `SIM` marking for synthetic data.

The Swift drawing is a native SwiftUI representation, not a pixel-for-pixel copy of the RGB565 framebuffer. Firmware/QEMU acceptance details remain in `../docs/SIMULATION.md` and `../docs/PROJECT_STATUS.md`.

## Generate and run

```bash
cd ~/Documents/Xcode/ESP32-EFIS
git pull
cd simulator
brew install xcodegen       # only if needed
xcodegen generate
open ESP32EFISSimulator.xcodeproj
```

Select an iPhone/iPad simulator and Run. The generated `.xcodeproj` is a build product; `project.yml` and Swift sources are maintained artefacts. Target is iOS 17+.

## OTA scenario checks

Exercise auto-download ON, auto-download OFF/manual Download, `Later`, successful `ACTIVATE & REBOOT`, and first-boot failure/rollback. Also exercise Network configuration independently. A successful Swift scenario validates wording/state logic only; it does not validate ESP32 Wi-Fi, TLS, flash, power-loss recovery or bootloader rollback.

## Safety and validation boundary

Simulator values must never become fallback values in an aircraft build. Aircraft firmware retains independent fail-obvious validity handling and must have bench simulation disabled. Swift/QEMU results are never physical sensor or aircraft validation. See `../docs/GNSS_DISPLAY.md`, `../docs/OTA_USER_SCENARIO.md`, `../docs/OTA_IMAGE_ADMIN.md` and `../docs/REMOTE_UPDATES.md`.

## Required boot-menu parity — 26 September 2026

The Swift simulator is to mirror the adopted physical boot interaction: **START EFIS** (default), **FULL TEST**, and **FIRMWARE UPDATE**, navigated conceptually by rotary selection + push confirmation. Firmware Update must lead through the Wi-Fi connection dialog before the existing OTA flow. FULL TEST must model the documented component PASS/FAIL/NOT TESTED results and failure codes. Simulator implementation demonstrates workflow only and does not validate physical encoder, Wi-Fi or electrical tests.
