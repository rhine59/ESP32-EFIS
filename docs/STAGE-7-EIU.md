# Provisional Stage 7 — Engine Sensor / EIU Integration

**Status:** PROVISIONAL — does not block Stages 1–6  
**Role:** Optional supplementary engine-monitoring expansion for MicroSky Horizon

## Purpose

Stage 7 adds a remote Engine Interface Unit (EIU) and AEF-CAN engine-data input to Horizon. The current EFIS is to be designed so this stage can be added later without redesigning its processor architecture or application data model.

The EIU is monitoring-only. It is not required for engine operation and must not interfere with an existing engine-control or required indication circuit.

## Stage boundary

Stages 1–6 continue to deliver the core Horizon attitude/altitude/navigation instrument. Stage 7 is deliberately provisional until the actual Rotax 912 variant, installed sender types, connector requirements and aircraft installation have been surveyed.

The Horizon side of Stage 7 is brought forward: firmware architecture and the future carrier PCB reserve a Classical CAN receive/transmit interface. The analogue engine-sensor electronics remain in the remote EIU.

## Horizon readiness requirement

Horizon shall provide:
- ESP32-S3 TWAI controller support at 500 kbit/s Classical CAN;
- external 3.3 V CAN transceiver on the final carrier;
- protected CAN-H/CAN-L interface;
- CAN reference/ground as required by the final isolation design;
- keyed external connector with CAN-H, CAN-L and reference/shield provisions;
- switchable/optional 120-ohm termination so Horizon may be a physical end of the bus;
- AEF-CAN V1 codec/dispatcher;
- freshness tracking and explicit stale/missing EIU state;
- ability to operate normally with no EIU present.

No engine-data absence may invalidate the core EFIS attitude/altitude/navigation functions.

## Provisional EIU channels

Initial target:
- RPM;
- oil pressure;
- oil temperature;
- CHT/head/coolant temperature channels appropriate to installed Rotax 912;
- EGT 1–4 provision;
- EIU supply voltage/current;
- sensor/open/short/out-of-range diagnostics;
- EIU health/heartbeat.

Exact analogue front ends remain conditional on the installed sender types.

## Gates

Stage 7A — Horizon CAN readiness: codec, receiver abstraction, stale handling, simulated EIU.
Stage 7B — CAN bench: two transceivers, correct termination, fault/loss tests.
Stage 7C — EIU bench prototype: sensor front ends and simulated/bench senders.
Stage 7D — engine/aircraft survey: freeze actual sender interfaces and harness.
Stage 7E — installed supplementary evaluation.

No Stage 7 item is treated as flight-validated merely because it passes simulation or bench CAN tests.


## Sensor commissioning and automatic fault detection

V1 uses explicit commissioning rather than attempting semantic auto-identification of conventional analogue engine sensors. The user/installer assigns each physical channel a semantic role and verified sender/profile (for example EGT1, CHT1 or oil temperature), and that mapping is persisted.

The EIU automatically discovers its own identity/capabilities and monitors each configured channel for presence, electrical compatibility, open/short/out-of-range/plausibility and stale/fault conditions. It must not infer or silently change semantic roles merely because an electrical reading resembles a sensor class.

Subsequent starts are automatic when the stored EIU/channel configuration remains valid. New, missing or electrically incompatible sensors generate an explicit commissioning/change/fault state rather than a silent remap.


## Sensor power / excitation

The EIU owns sender excitation and analogue conditioning. Horizon/EFIS shall not directly power individual engine sensors.

Passive/self-generating channels (notably K-type thermocouples) receive no supply from the EIU. Resistive temperature channels use controlled low-level measurement excitation internal to the EIU rather than a generic sensor-power rail. Powered electronic senders receive only the supply required by their verified datasheet/installed configuration, generated and protected locally in the EIU.

Oil-pressure and RPM interfaces are explicitly **sender/source dependent**. Earlier concept illustrations showing generic +5 V for these channels are illustrative only and must not be treated as a frozen pinout or electrical requirement.

The preferred installation gives the EIU a protected aircraft-supply feed independent of the EFIS regulated rails. EIU power conversion, sensor excitation and faults are locally contained so an engine-monitoring failure cannot disable core Horizon functions. Final aircraft-power branching, grounding/reference, isolation and whether supply conductors share the AEF-CAN harness are deferred to the installation/electrical design gate.


## EIU firmware update architecture — 1 October 2026

The preferred production update path is **firmware service -> Horizon/EFIS -> AEF-CAN -> EIU**. The EIU does not require Wi-Fi, Internet access, cloud credentials or a separate user-facing updater.

Horizon discovers the EIU hardware identity, board revision, bootloader version, running firmware version and AEF-CAN compatibility. It downloads only a compatible signed EIU image, validates package metadata/signature according to the project OTA trust model, then transfers the image over an AEF-CAN firmware-update service.

The EIU must independently authenticate the candidate before execution. Trust in Horizon or a successful CAN transfer alone is not sufficient authorization to boot firmware.

### EIU flash model

The EIU shall reserve:
- protected/recoverable bootloader;
- application slot A;
- application slot B;
- separately versioned persistent configuration/calibration storage.

An update is written only to the inactive application slot. Sensor assignments, calibration, EIU identity and commissioning data are not application-image payload and must survive firmware replacement. Configuration-format migration must be transactional/recoverable.

After transfer the EIU verifies the complete candidate, marks it pending, reboots into it and performs startup self-test. The candidate becomes confirmed only after successful initialization and AEF-CAN communication/health confirmation. Failed boot, watchdog reset, failed self-test or missing confirmation causes automatic rollback to the previous known-good application.

### Operational gate

EIU update activation is a deliberate maintenance action. It shall not begin while the engine is running. Horizon must clearly warn that engine indications are unavailable during transfer/reboot and require explicit user activation. The final gate may include RPM=0 plus other stationary/maintenance-state evidence; exact policy remains to be frozen and tested.

### Physical recovery

The EIU PCB retains internal service/recovery pads or an equivalent programming/debug interface for bootloader recovery and manufacturing. Normal field updating does not require opening the EIU.

### Test requirement

The OTA harness shall gain a simulated AEF-CAN EIU node so the complete workflow can be exercised without aircraft hardware: discovery/version report, compatibility decision, image transfer with acknowledgements/retry, interruption/resume or clean restart policy, complete-image verification, pending activation, reboot, health confirmation, rollback and configuration preservation. Simulation is not physical CAN/flash validation.


## USB-C factory/service programming

The EIU external **USB-C SERVICE** port is the primary local programming/service interface. On an ESP32-S3 design it should use native USB where practical.

Factory/development flow is:

`service computer -> USB-C SERVICE -> ROM/bootloader programming -> factory image -> reboot -> identity/self-test`.

The factory image establishes the bootloader, partition table, initial application slot and persistent-storage layout required by the A/B update architecture. Manufacturing identity (serial number, hardware revision and PCB revision) is provisioned separately from aircraft sensor commissioning/calibration data.

USB VBUS may power the service-side EIU electronics on the bench, but the hardware must prevent back-feed between USB 5 V and the aircraft-power input. USB-powered service mode must not imply that engine sensor excitation or all aircraft-side interfaces are safe/available unless the final power design explicitly supports them.

USB-C does **not** replace normal field OTA. Production user updates remain Horizon -> AEF-CAN -> EIU. USB is for factory provisioning, development, workshop diagnostics and recovery.

Internal fallback programming/test pads remain mandatory for recovery from a USB/bootloader/configuration failure. Development units should remain recoverable; irreversible security/eFuse changes belong to a separately controlled production-provisioning operation.


### Interrupted transfer / checkpoint requirement

EIU firmware transfer must survive removal of aircraft power or loss of CAN without threatening the running firmware. The inactive slot is written in durable blocks; the transfer-block interval is **4 KiB**; durable resume state is nominally **64 KiB**. A checkpoint binds transfer ID and image digest to an absolute committed byte offset plus block integrity information.

After restart Horizon queries update state. If transfer ID/image identity match, transfer resumes from the last committed offset. If they do not match, the partial candidate is not silently reused. Percentage complete is UI-only and is derived from committed offset/image size.

The active known-good slot remains bootable throughout download. Only a complete image that passes whole-image digest/signature verification can become pending for activation.


### Adopted production CAN firmware transport — 1 October 2026

The Stage-7 production direction supersedes the prototype six-byte/per-frame-ACK transport. FW_DATA uses one local sequence byte and seven firmware bytes. Horizon sends a 4 KiB transfer block, the EIU validates that block with CRC32, then returns a block ACK/NACK. A bad or incomplete block is retransmitted.

A 4 KiB block is **not** a durable restart checkpoint. Durable resume state is recorded nominally every 64 KiB to reduce unnecessary metadata writes and flash wear. Following power loss, the EIU resumes from the last durable 64 KiB absolute offset; retransmission of data after that point is acceptable because the active known-good A/B slot is untouched.

Firmware-maintenance CAN traffic is deliberately lower priority than operational measurement/health traffic and must be rate-limited/yield when necessary. Complete-image SHA-256 and signature verification, explicit activation, trial boot and rollback remain unchanged.


## Flash-endurance architecture — 1 October 2026

Flash endurance is now an explicit EIU design constraint. Firmware-image programming is not expected to be the dominant wear mechanism because production OTA uses alternating A/B application slots. The implementation shall instead prevent small, frequently updated metadata or operational state from concentrating erase cycles on one flash sector.

### Durable OTA checkpoint journal

The nominal 64 KiB durable-resume interval is retained, but checkpoint metadata shall **not** repeatedly erase/rewrite one fixed sector. Durable checkpoints shall use an append-only rotating journal spanning multiple erase sectors, or an equivalent platform wear-levelled implementation with demonstrably comparable behaviour.

Each durable checkpoint record shall contain enough information to reject stale or mismatched state, including at minimum:
- monotonically increasing generation/record sequence;
- transfer/image identity and whole-image digest identity;
- absolute committed byte offset;
- transfer/block integrity state needed for safe resume;
- record integrity check (CRC or equivalent).

A record becomes valid atomically: an interrupted metadata write must leave either the previous checkpoint usable or the new checkpoint independently recognizable as complete. Journal reclamation/erase occurs only when required after rotating through the allocated checkpoint area. On boot, the newest valid compatible record is selected; corrupt, incomplete or wrong-image records are ignored.

The 4 KiB CAN transfer-block ACK/CRC state remains primarily volatile. A successful 4 KiB block does not require a persistent metadata write. Durable flash state is committed nominally every 64 KiB and at carefully selected lifecycle boundaries where required for correctness.

### RAM-first operational state

High-frequency EIU state shall remain in RAM. Normal sensor samples, CAN frames, counters, transient diagnostics, heartbeat state and continuously changing engine values shall **not** cause flash writes.

Persistent writes are limited to deliberately durable information such as:
- commissioned sensor/channel configuration;
- calibration and manufacturing identity;
- infrequent user configuration changes;
- OTA checkpoint/activation/rollback metadata;
- selected significant fault/event records where persistence is explicitly justified.

Where frequently changing persistent state is genuinely required, it must use ESP-IDF NVS/wear levelling or a purpose-designed append-only journal rather than a fixed-sector rewrite loop.

### Prohibited implementation pattern

No implementation may perform a flash/NVS commit per CAN frame, per sensor sample, per heartbeat, or on every increment of an operational counter. Rate limiting alone is not sufficient justification for such a design; persistence must be event-driven and wear-aware.

### Validation requirement

The EIU test plan shall include flash-wear accounting. Tests/review must demonstrate checkpoint rotation, recovery after power loss during checkpoint creation, rejection of corrupt/stale records, journal wrap/reclamation, preservation of A/B rollback, and absence of high-frequency operational flash commits.

Adding FRAM, EEPROM or removable storage solely to address expected OTA flash wear is **not required** for V1. Such hardware should be introduced only if later requirements create a justified high-write persistent-data workload.

## Architecture review decisions — 1 October 2026

The following decisions are now adopted constraints for Stage 7 rather than optional review notes.

### Power and fault containment

Horizon/EFIS and the EIU shall use **independent protected branches from the aircraft electrical system**. The EIU shall not be powered from the EFIS regulated rails. Whether aircraft power conductors and AEF-CAN share a physical harness remains an installation decision; electrically, the branches remain separately protected and a fault in one unit must not remove power from the other.

The baseline CAN implementation is **protected non-isolated Classical CAN with an explicit reference/ground strategy**. Galvanic isolation is not a default requirement because it adds isolated power, components, PCB area and failure modes. Isolation shall be added only if aircraft grounding/common-mode/noise testing or a later installation requirement demonstrates a need.

A formal fault-containment requirement applies: EIU failure must not disable core Horizon; a sensor short must be locally contained; CAN faults must not reboot either node; USB/service faults must not propagate into aircraft power/CAN; bad firmware/configuration must remain recoverable; update failures must leave a known-good application bootable.

### EIU processor design gate

ESP32-S3 is **not frozen as the EIU MCU**. It remains a strong candidate because shared ESP-IDF, native USB, OTA/security tooling and project knowledge reduce development cost. Before EIU PCB freeze, compare it against suitable deterministic/industrial MCU alternatives (for example an STM32-class device) for CAN/timers/ADC support, boot/rollback facilities, development complexity, component count and long-term maintainability. Select on system merit, not processor-family inertia.

### Sensor commissioning simplification

V1 shall not attempt semantic auto-identification of conventional analogue engine sensors. Physical channels are commissioned/configured with explicit roles and sender profiles (for example EGT1, oil temperature). Firmware then performs automatic **electrical compatibility, presence and fault detection** against that configuration. Device discovery and EIU capability discovery remain automatic. No channel is silently remapped from electrical inference.

### Connector design gate

The previous 12-way / 12-way / 7-way connector arrangement is a packaging illustration only. Pin counts and connector family shall not be frozen until the actual engine/sender installation has been surveyed. Sensor electrical interface, thermocouple termination/material requirements, wire count/gauge, grounding/reference, current rating and environmental/mechanical requirements determine connector selection.

### Network role

Horizon/EFIS is an **AEF-CAN maintenance gateway, not an operational bus master**. The EIU publishes measurements independently and continues doing so if Horizon disappears. A logger, second display or future compatible consumer may receive EIU data directly. Firmware/configuration gateway functions do not create an operational dependency on Horizon.

### USB-C service scope

EIU USB-C remains the preferred local service/programming interface, but is not an everyday operational interface. It should be mechanically recessed/protected as appropriate. USB bench power need only support the service/digital domain required for programming and diagnostics; it is not required to reproduce the complete aircraft-powered sensor environment. Internal recovery access remains required.

### Platform OTA facilities

The required firmware behaviour is known-good -> candidate -> trial -> confirmed/rollback. Implement this using mature MCU/platform OTA/boot facilities where suitable rather than creating a bespoke boot manager without need. The EIU still independently verifies firmware authenticity before execution.


### Phone-carried offline release sets

The customer mobile app may pre-cache a compatible signed release set containing both Horizon and EIU firmware before travelling to an aircraft with no network coverage. The phone transfers the Horizon package to Horizon over the local maintenance connection; Horizon then remains the AEF-CAN maintenance gateway for EIU delivery.

The phone does not directly program the EIU in V1. This preserves one CAN maintenance authority/path, keeps EIU transport/recovery policy inside Horizon, and avoids requiring a second phone-to-EIU radio/service protocol. The EIU independently authenticates its candidate exactly as it does for an Internet-originated update.


### EFIS/EIU firmware dependency contract

EIU firmware is independently versioned from Horizon firmware. Normal compatibility is negotiated from AEF-CAN protocol version and advertised capabilities, with the signed release-set manifest defining tested combinations and deployment order.

The EIU must preserve capabilities required by the previous supported Horizon state during any normal coordinated-update transition in which Horizon could roll back to that state. Likewise, a Horizon release must not begin using a new mandatory EIU capability until discovery confirms that capability after the EIU update/reboot.

There is no universal "EIU first" rule. The release manifest specifies an order proven to keep each intermediate and rollback state compatible. A dependency transition that cannot meet this property requires a special migration/recovery procedure and is excluded from normal OTA/offline one-click updates.


## EIU channel assignment, thresholds and display units

**ADOPTED — 1 October 2026.** Sensor operating thresholds are commissioned at the same time that a physical EIU input channel is assigned its semantic function and sender profile. Channel commissioning is therefore one atomic configuration operation:

`physical channel -> sensor function -> sender profile -> operating thresholds`

Horizon is the commissioning authority and user interface. The EIU retains the commissioned channel configuration locally so that channel identity, sender conversion and durable configuration remain associated with the measurement source.

### Threshold model

For each commissioned channel, the configuration shall support the following ordered operating regions:

- low alarm;
- low caution;
- normal;
- high caution;
- high alarm.

A V1 display or sender profile may use only a subset of these regions, but the persistent configuration/data model shall not be limited to a simple low/normal/high representation. This avoids a later incompatible schema change when amber/red caution and alarm presentation is introduced.

Known engine/sender profiles may provide recommended default thresholds. Defaults are advisory commissioning values only: Horizon shall display them to the installer and require explicit acceptance or adjustment. Sensor detection, engine type or sender-profile selection must never silently assert that a threshold is correct for a particular aircraft installation. Applicable engine and installation documentation remains authoritative.

### Canonical engineering units

Thresholds and measured values shall be stored and exchanged in canonical engineering units independent of the pilot's selected display units. Changing Horizon from, for example, °C to °F or bar to psi changes presentation only and must not alter the underlying threshold configuration.

Horizon owns unit selection, conversion, formatting, colour/state presentation and commissioning UI. The EIU performs sender excitation/conditioning/conversion and reports the canonical engineering value plus validity/fault metadata. Where threshold evaluation is required in both nodes, both shall evaluate the same canonical configured values rather than separately converted display values.

### Commissioning interaction

A channel assignment screen shall present, together, the physical channel, detected electrical class/presence, selected sensor function, selected sender profile, threshold regions and values expressed in the Horizon-selected display units. Saving the channel converts those displayed values to the canonical representation and commits the complete channel configuration transactionally.

Changing a sender profile or semantic channel function shall force the applicable thresholds to be reviewed before the revised configuration is accepted. A fundamental sensor reassignment invalidates the relevant engine-sensor commissioning check and requires revalidation.
