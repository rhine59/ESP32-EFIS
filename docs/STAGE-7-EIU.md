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


## Sensor auto-discovery and commissioning

Stage 7 shall use the three-level AEF-CAN discovery model documented in `docs/CAN-PROTOCOL.md`: EIU device discovery, electrical channel discovery, then user-confirmed semantic assignment.

Conventional Rotax analogue senders and K-type thermocouples are **not self-identifying devices**. The EIU may determine electrical class/presence and diagnose open/short/plausibility states, but it must not guess that a channel is “oil temperature”, “EGT 1”, etc. solely from a plausible electrical reading. First-run commissioning presents compatible assignments to the user and persists the confirmed mapping.

Subsequent starts should be automatic when hardware matches the stored configuration. New sensors on previously empty channels, missing commissioned sensors, incompatible electrical behaviour or changed EIU/configuration identity must generate an explicit discovery/change/fault state. They must not silently alter a channel mapping or leave a frozen plausible value on Horizon.

Stage 7A therefore includes simulated discovery, capability enumeration, persistent mapping and stale/change/fault behaviour in addition to ordinary engine-value frames. Stage 7C validates the electrical detection limits of the real EIU front ends; simulation must not claim a sensor type can be distinguished unless the hardware can actually distinguish it.


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
