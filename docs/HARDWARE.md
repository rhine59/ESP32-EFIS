# Hardware Design

## Processor — optimised reference choice

The reference processor is now the **Espressif ESP32-S3-WROOM-1-N16R2** module mounted on a project-specific carrier PCB.

Key reasons for this choice:

- 16 MB Quad flash
- 2 MB Quad PSRAM
- enough PSRAM for double-buffered 480×480 RGB565 graphics
- Quad rather than Octal PSRAM, preserving GPIO35–37 for the pin-heavy display/IMU design
- active module with good current distributor availability
- smaller and mechanically cleaner than designing the instrument around a development board
- native USB available directly from the ESP32-S3

The processor handles:

- BMI088 acquisition over SPI
- calibration and alignment correction
- quaternion AHRS/filter execution
- validity monitoring
- 480×480 horizon graphics
- rotary encoder input through MCP23008
- display brightness PWM

The earlier **ESP32-S3-DevKitC-1-N8R2** remains useful for bench firmware development if already available, but is no longer the reference final hardware because that exact DevKit variant is obsolete at major distributors.

### Why not an 8 MB Octal-PSRAM ESP32-S3

The display requires 16 RGB data signals plus timing and sensor/control interfaces. Espressif documents GPIO35–37 as part of the Octal memory interface on Octal-PSRAM configurations. Losing those three pins makes the current design significantly harder.

For this project, **2 MB Quad PSRAM is a better system-level choice than 8 MB Octal PSRAM** because GPIO availability is more valuable than the extra memory.

Two RGB565 frame buffers require:

`480 × 480 × 2 bytes × 2 buffers = 921,600 bytes`

That fits comfortably inside 2 MB PSRAM.

## Custom processor carrier

The final PCB should carry the N16R2 module directly and provide:

- regulated 5 V instrument input via USB-C
- 3.3 V regulator sized for ESP32-S3 transient current plus peripherals
- local bulk and high-frequency decoupling
- native USB D-/D+ routing to GPIO19/GPIO20
- EN/reset network
- BOOT access on GPIO0
- test/programming pads
- RGB display connector
- shared LCD-configuration/BMI088 SPI connector
- I²C/MCP23008 connector
- TPS61169 PWM/output wiring
- deliberate grounding and short high-speed return paths

Normal flight firmware should not require Wi-Fi or Bluetooth. They should remain disabled during ordinary attitude-display operation unless deliberately enabled for a maintenance function.

## IMU — reference part frozen

The reference IMU board is the **Bosch Sensortec SHUTTLE BOARD 3.0 BMI088** using SPI.

Approximate board dimensions are 22 × 14 mm with a 1.27 mm-pitch connector. The accelerometer and gyroscope are separate logical SPI devices with separate chip selects. Firmware must explicitly perform the accelerometer's documented SPI-mode transition after reset.

The sensor is rigidly mounted and its axes are explicitly mapped to aircraft longitudinal, lateral and vertical axes. Soft foam suspension is not used as the primary structural mounting method.

## Display — reference part frozen

The reference display is the **Newhaven NHD-2.1-480480AF-ASXP**:

- 2.1-inch round IPS TFT
- 480 × 480 pixels
- 1000 nit typical luminance
- ST7701S controller/driver
- no touch layer
- project pixel interface: **16-bit RGB565 parallel RGB**
- ST7701S configuration: 9-bit serial/SPI-style initialization
- 40-pin 0.5 mm FFC
- active area 53.28 × 53.28 mm
- outline 58.18 × 60.71 × 2.26 mm
- TFT supply approximately 3.0–3.3 V
- backlight approximately 6.0 V / 100 mA
- operating temperature -20 °C to +70 °C

RGB565 is chosen instead of the panel's full 18-bit mode to save two direct ESP32 GPIOs.

## Backlight

The prototype uses the **Adafruit TPS61169 constant-current boost converter, PID 6354**, configured for approximately 100 mA maximum LED current. Brightness is controlled by ESP32 PWM.

The backlight is not powered from an ESP32 GPIO or from the ESP32's 3.3 V regulator output.

## Low-speed GPIO

The **Microchip MCP23008** handles low-speed functions including:

- LCD configuration chip select
- LCD hardware reset
- rotary encoder A
- rotary encoder B
- rotary encoder push switch

Its interrupt output is connected directly to the ESP32.

## User input

The reference control family is **Bourns PEC09**, using an incremental rotary encoder with push switch. Exact shaft length/knob suffix remains to be physically frozen.

Likely functions:

- rotate: brightness/menu selection
- short press: acknowledge/select
- deliberate long press: cage/calibration action subject to final safety logic

## Power

Development power is a regulated **5 V input via USB-C**. Aircraft 12 V conversion, surge suppression and reverse-polarity protection remain outside the enclosure during this phase.

The custom carrier will regulate 5 V down to 3.3 V for the ESP32-S3 and logic. The 5 V rail also supplies the dedicated backlight boost/current driver.

## Enclosure integration

The 3 1/8-inch enclosure now provides:

1. optical-window/front-bezel assembly
2. Newhaven display carrier
3. rigid BMI088 carrier
4. rear-service electronics carrier
5. rotary encoder control pod
6. USB-C cable strain relief
7. removable rear cover

The existing electronics carrier was deliberately designed with edge-location rails so it can be revised for the final custom N16R2 PCB without redesigning the main enclosure.

## Thermal and mechanical considerations

The 1000-nit LCD backlight is likely to dominate heat generation. The complete assembly must be tested at elevated ambient temperature and under representative solar loading.

Electronics that affect attitude measurement must not move relative to the airframe. IMU reference alignment is more important than cosmetic display alignment.

## Boot control, diagnostic testability and production networking

The PEC09 rotary/push control is the normal physical controller for the boot menu and maintenance dialogs: rotate to move selection and short-press to enter/confirm. The boot menu offers **START EFIS**, **FULL TEST** and **FIRMWARE UPDATE**, with START EFIS selected by default.

Production hardware should be designed for the bootable electrical test harness: preserve labelled rail/test points and, where practical, permit safe identity, rail and protected-interface diagnostics. Display/backlight testing still requires visual confirmation. External aircraft-connected interfaces must never be driven into an unsafe state by test mode.

Wi-Fi credentials are persistent in ESP-IDF NVS. Production configuration requires NVS encryption for stored credentials. Wi-Fi remains maintenance-only and is explicitly entered from the firmware-update path; it is not silently enabled during normal flight presentation.



## Airspeed scope decision — 26 September 2026

**ASI/IAS is not part of the EFIS.** Do not fit a pitot/differential-pressure sensor. BMP585 remains the sole pressure sensor and connects to aircraft STATIC for altitude/barometric pressure. No PITOT pneumatic input is required.


## Engine-sensor and USB GPS interface direction — 30 September 2026

**ADOPTED / DETAILED ELECTRICAL DESIGN PENDING.** Reserve an enclosure-accessible multiway engine-sensor connector for CHT, EGT, oil temperature, oil pressure and coolant/water temperature. Inputs require sender-specific protection, filtering and conversion; EGT/thermocouple inputs require a proper thermocouple front end and cold-junction compensation. Prefer a dedicated precision conversion/interface stage rather than routing aircraft sender wiring directly to ESP32 ADC/GPIO pins. Exact sender types and ranges must be identified before the analogue design is frozen.

Remove the dedicated GNSS connector from the carrier/enclosure concept. GNSS will use a validated external USB GPS mouse/receiver. The ESP32-S3 design must therefore support the selected USB-host architecture and receiver protocol while retaining a practical service/programming path. USB power budget, ESD/transient protection, connector retention and coexistence with service USB must be resolved before PCB freeze. Do not describe a USB GPS mouse as electrically passive: it is an active USB-powered GNSS receiver even though it needs no separate aircraft data interface.


## Remote Engine Interface Unit (EIU) direction — 30 September 2026

**PREFERRED ARCHITECTURE / DETAILED DESIGN PENDING.** For the initial engine-monitoring design assume a conventional carburetted Rotax 912-series installation and terminate the engine senders at a separate remote Engine Interface Unit rather than carrying multiple low-level analogue/thermocouple circuits to the Horizon enclosure. The EIU performs sender excitation where required, protection, filtering, thermocouple cold-junction compensation, precision analogue-to-digital conversion, calibration/linearisation, open/short plausibility diagnostics and local acquisition. A single robust digital link carries measurements plus validity/diagnostic metadata to Horizon.

Initial EIU channels should cover the applicable Rotax 912 head/coolant temperature channels, oil temperature, oil pressure and provision for two EGT thermocouples. Exact sensor transfer functions and limits must be selected by engine variant/serial/configuration from current Rotax documentation; Horizon must not assume all 912 installations use identical head/coolant or oil-pressure senders.

**Preferred EIU-to-Horizon physical bus for V1: isolated CAN.** Use a short application protocol with node identity, channel identity, engineering value, raw value/diagnostic state, sequence counter and freshness/CRC handling. Horizon must mark stale, missing or implausible engine data invalid rather than retain a plausible old value. The EIU is not an engine-control device and must not be placed in series with any sensor required by another engine-control system. Where an existing sender must also feed another instrument, loading/isolation must be engineered and validated rather than simply paralleling it.

Locate the EIU near enough to the engine/sensor harness to keep thermocouple and analogue runs controlled, but in an installation environment compatible with its temperature, vibration and moisture ratings. Keep the Horizon enclosure interface to protected power/ground plus the digital bus rather than a large bundle of analogue sensor wires.


## Stage 7 readiness — provisional engine monitoring

The core Horizon design shall be **AEF-CAN ready** without making engine monitoring a dependency. Reserve ESP32-S3 TWAI pins and carrier-board space for a 3.3 V Classical CAN transceiver, interface protection, connector and selectable 120-ohm end termination. The exact transceiver/isolation implementation remains to be frozen before carrier-PCB release.

Firmware shall accept AEF-CAN through a transport boundary and maintain an optional engine-data state. Missing or stale EIU traffic invalidates engine data only; it must not impair attitude, altitude, GNSS or other core Horizon functions. The initial implementation is in `aef_can_codec.[ch]` and `aef_engine_input.[ch]`.

The remote EIU and its analogue sensor electronics are **Provisional Stage 7**; see `docs/STAGE-7-EIU.md`.


## Single external USB-C OTG interface — 30 September 2026

**ADOPTED PRODUCTION DIRECTION.** Horizon shall use one externally accessible USB-C port for both service/programming and the external USB GNSS receiver. The ESP32-S3 USB interface is used in dual-role/OTG fashion: Horizon is a USB **device** when attached to a service computer and a USB **host** when operating the selected GPS mouse/receiver.

Routine production firmware updates should use the signed OTA path, but USB programming/recovery remains a required service capability for initial factory programming, development, diagnostics and recovery when OTA is unavailable. Retain internal factory/recovery programming/test pads on the carrier PCB as a second service path if the external connector or USB firmware path is damaged.

The final circuit must correctly implement USB-C role detection and protected VBUS switching. Horizon must not source VBUS while attached as a USB device to a computer; in host mode it must provide a protected/current-limited 5 V supply adequate for the validated GPS receiver. ESD protection, USB signal integrity, receiver power budget, connector retention and host/device firmware behaviour are PCB-release gates.

No second external programming connector and no dedicated GNSS connector are required. The rear-panel designation is **USB-C — SERVICE / GPS**. Exact USB GPS receiver/protocol remains selection/validation required.


### EIU connector concept — 1 October 2026

**PROVISIONAL MECHANICAL/INTERCONNECT DIRECTION.** The preferred external EIU connectors are compact **black-plastic circular locking connectors in the style used on ULM/microlight headset systems**. The intent is a lightweight keyed connector with positive push/twist or equivalent locking, rather than a large metal aerospace connector or an industrial M12 connector.

The installation does **not** require a fully waterproof/IP67 connector. It should instead be designed for reasonable water/splash resistance appropriate to the selected EIU mounting position, using sensible connector orientation, enclosure lips/seals, cable strain relief, heat-shrink/boots and drip loops as appropriate. Do not treat IP40 alone as water resistance; final connector selection must be checked against the actual installation environment.

Provisional enclosure interface:
- **J1 — ENGINE TEMP:** multiway ULM-style black-plastic locking circular connector for EGT/CHT and related temperature channels.
- **J2 — ENGINE AUX:** multiway ULM-style black-plastic locking circular connector for oil pressure, oil temperature, coolant/water temperature and spare/provisional sensor channels.
- **J3 — EFIS CAN:** smaller/differently keyed ULM-style black-plastic locking circular connector carrying protected power/ground and the EIU-to-Horizon CAN bus, with spare conductors only if justified.

Use different pin counts and/or mechanical keying where practical so sensor and CAN/power harnesses cannot be cross-connected. Exact contact count, connector manufacturer/family and part numbers remain **TBD** until the Rotax 912 sender set, thermocouple wiring requirements, conductor sizes, current ratings, temperature/vibration limits and required degree of splash resistance are frozen.

The visual target is the small black plastic connector style familiar from ULM headset installations. Earlier metal-bodied Binder-style illustrations are **not** the intended EIU production appearance.


### EIU sensor power and excitation architecture — 1 October 2026

Sensor power is **sender-dependent**. Do not assume that every engine sensor requires, or may safely receive, a +5 V feed.

- **K-type EGT thermocouples:** self-generating millivolt sources; no sensor power is supplied. The EIU provides the thermocouple analogue front end, cold-junction compensation, open-sensor diagnostics and appropriate protection.
- **Resistive temperature senders (CHT/head/coolant/oil temperature where applicable):** no separate power wire. The EIU supplies only the controlled low-level measurement excitation through a precision resistance-measurement network and measures the resulting voltage/resistance.
- **Oil pressure:** power/interface requirements depend on the actual installed sender. A three-wire electronic sender may require a regulated excitation supply (for example 5 V), while other sender types require different conditioning. No supply voltage is frozen until the installed sender is identified.
- **RPM:** excitation/interface depends on the selected Rotax/tacho pickup or any added Hall/frequency sensor. Do not assume +5 V.
- Any powered sensor supply shall be generated and protected **locally inside the EIU**, with current limiting/fault containment appropriate to the final sender.

Preferred system power architecture: the EIU receives its **own protected aircraft-supply feed** rather than being powered from the EFIS regulated electronics. The EIU locally provides its MCU/ADC/front-end rails and any required sensor excitation. This limits the ability of an EIU or engine-sensor wiring fault to pull down the core EFIS.

The AEF-CAN connection carries digital communications; whether aircraft power is physically bundled with that cable or supplied independently at installation remains a harness/topology decision. In either case, the EFIS core electronics must not be the unprotected source of EIU/sensor power.

J1 ENGINE TEMP is therefore primarily passive thermocouple/resistive measurement wiring. J2 ENGINE AUX may contain sender-specific excitation only where the selected sensor requires it. Exact J1/J2 power/excitation pins remain **TBD / DO NOT FREEZE** until the installed Rotax 912 sender set and RPM source have been surveyed.


### EIU USB-C SERVICE interface — 1 October 2026

The EIU shall have an externally accessible **USB-C SERVICE** port as its primary factory programming, development, diagnostics and recovery interface. For an ESP32-S3 implementation, use the MCU native USB capability where practical rather than adding a USB-to-UART bridge solely for programming.

The USB-C SERVICE port is distinct from the normal production firmware-delivery path:
- **normal field update:** signed firmware service -> Horizon/EFIS -> AEF-CAN -> EIU inactive application slot;
- **factory/development/recovery:** service computer -> USB-C SERVICE -> EIU.

USB service shall support initial blank-board/factory flashing, development flashing, bootloader recovery, diagnostic console/manufacturing test functions and device interrogation as implemented. It is not a substitute for the AEF-CAN field-update architecture.

USB-C 5 V may power the EIU digital/service electronics for bench programming without an aircraft 12 V supply. The PCB must implement a deliberate protected power-path arrangement so USB VBUS cannot back-feed the aircraft supply and the aircraft supply cannot drive USB VBUS. Final implementation shall consider current limiting, reverse-current blocking/ORing, ESD and USB-C CC/device-role requirements. Firmware should be able to detect USB/service presence where useful.

The production enclosure interface set therefore includes **J1 ENGINE TEMP, J2 ENGINE AUX, J3 AEF-CAN and USB-C SERVICE**.

Retain small internal programming/recovery/test pads even with USB-C. At minimum provide access appropriate to the selected MCU for ground, reset/enable, boot/download control and a fallback serial/debug/programming route. These pads are a last-resort manufacturing/recovery path if USB is unavailable or misconfigured.

Factory provisioning should be scriptable over USB and may flash the bootloader, partition table and factory application; provision non-secret manufacturing identity such as serial number/hardware/PCB revision; reboot/interrogate the EIU; and run production self-tests. Security/eFuse provisioning must be a separate deliberate production step and must not be performed accidentally by ordinary development flashing.


## Stage-7 architecture constraints — 1 October 2026

- **Independent power:** Horizon and EIU use separately protected aircraft-supply branches. Do not power the EIU from Horizon regulated rails.
- **CAN baseline:** protected non-isolated Classical CAN plus deliberate reference/ground design. Galvanic isolation is optional and must be justified by installation/common-mode/noise testing.
- **Fault containment:** sensor, EIU, CAN and USB/service faults must be locally contained and must not disable the core Horizon instrument or destroy the known-good recovery path.
- **EIU MCU:** ESP32-S3 is a candidate, not a frozen selection. Perform an ESP32-S3 versus suitable industrial/deterministic MCU review before EIU PCB freeze.
- **Connectors:** previous 12/12/7 pin counts are conceptual only. Freeze only after the installed engine/sender/harness survey, including thermocouple termination requirements.
- **USB-C SERVICE:** retain as local factory/workshop interface, preferably recessed/protected. USB bench power is scoped to service/digital operation; it need not power the full sensor environment.
- **Boot architecture:** use mature platform A/B OTA/rollback facilities where they meet the required known-good/candidate/trial/confirm behaviour rather than inventing a bespoke bootloader.


## Thingies product naming

The flight-display hardware described in this repository belongs to **Thingies RedOne**. The engine-interface hardware described as the EIU/ECI belongs to **Thingies BlueOne**. EFIS/EIU/ECI remain engineering role names where useful; enclosure legends, product labels and customer-facing diagrams should use RedOne/BlueOne.
