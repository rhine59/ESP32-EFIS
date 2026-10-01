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
