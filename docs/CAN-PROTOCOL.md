# AEF-CAN — Aircraft Experimental Flight CAN

**Status:** ADOPTED architecture; V1 core wire contract frozen for implementation  
**Scope:** MicroSky Horizon / ESP32-EFIS and future experimental aircraft nodes  
**Role:** Secondary, supplementary, non-certified instrumentation

## 1. Purpose

AEF-CAN is the project CAN application protocol. It transports aircraft measurements and node health between independent modules such as an Engine Interface Unit (EIU), Horizon display, data logger, future air-data module, fuel module or second display.

The protocol describes **aircraft data, not screen layout**. Producers publish measurements and validity; consumers decide how to display, log or alert on them.

AEF-CAN is intentionally not named after ESP32. A future node may use another MCU without changing the aircraft-level protocol.

## 2. Safety and operating assumptions

This project is experimental supplementary/non-primary instrumentation. AEF-CAN is not a certified avionics data bus and this specification does not claim certification, integrity assurance or suitability as a sole source of flight or engine information.

Rules:
- stale or invalid data must not remain presented as trustworthy live data;
- no consumer may silently replace failed real data with simulated data;
- simulation traffic must be explicitly identifiable in development builds;
- a producer reports measurements and sensor state, not UI colours;
- alert thresholds are consumer/configuration policy unless a future message is explicitly defined as a source-native alarm;
- loss of a node or message family must be detectable by timeout.

## 3. V1 physical/data-link baseline

AEF-CAN V1 uses **ISO 11898-1 Classical CAN**, initially at **500 kbit/s**, with standard 11-bit identifiers and payloads of 0–8 bytes.

For the current ESP32-S3 hardware:
- ESP32-S3 TWAI provides the Classical CAN-compatible controller;
- an external CAN transceiver is required;
- ESP32-S3 native TWAI is not CAN FD capable;
- CAN-H/CAN-L use a twisted pair;
- the physical bus is terminated with 120 ohms at each physical end;
- topology should be a linear trunk with short stubs rather than a star.

CAN FD is a possible future transport, but V1 does not require it. Application code must not assume that the conceptual AEF data model can only ever be carried in 8-byte frames.

## 4. Network architecture

Nodes are peers on a multi-master broadcast bus. The EIU does not send data "to the EFIS"; it publishes data onto the bus.

Example:

```text
 Rotax sensors
      |
      v
 +---------+       +---------+       +---------+
 |   EIU   |=======| Horizon |=======| Logger  |
 +---------+ CAN   +---------+       +---------+
      |                                  |
 engine I/O                         optional storage

 Future nodes may include air-data, fuel, electrical or second-display modules.
```

No normal measurement publisher depends on a particular display being present.

## 5. Identifier allocation

V1 reserves the 11-bit identifier space by function:

| CAN ID range | Purpose |
|---|---|
| 0x000–0x07F | Network control / highest-priority exceptional traffic |
| 0x080–0x0FF | Node management and discovery |
| 0x100–0x17F | Engine measurements |
| 0x180–0x1FF | Electrical |
| 0x200–0x27F | Air data |
| 0x280–0x2FF | Navigation / GNSS |
| 0x300–0x37F | Attitude / motion |
| 0x380–0x3FF | Fuel |
| 0x400–0x47F | Environmental |
| 0x480–0x4FF | Aircraft state |
| 0x500–0x57F | Alerts/events |
| 0x580–0x5FF | Configuration/service |
| 0x600–0x67F | Diagnostics |
| 0x680–0x6FF | Logging/time synchronization |
| 0x700–0x77F | Experimental/development |
| 0x780–0x7FF | Reserved |

Lower CAN identifiers have higher arbitration priority. Allocation within ranges must therefore be deliberate; IDs are not assigned merely in chronological order.

## 6. Initial engine messages

The first EIU implementation reserves:

| ID | Name | Nominal rate | Purpose |
|---|---|---:|---|
| 0x090 | NODE_ANNOUNCE | boot + 1 Hz | identity/protocol/capabilities summary |
| 0x100 | ENGINE_FAST_V1 | 10 Hz | RPM, oil pressure, oil temperature |
| 0x101 | CHT_V1 | 5 Hz | CHT 1/2 |
| 0x102 | EGT_12_V1 | 5 Hz | EGT 1/2 |
| 0x103 | EGT_34_V1 | 5 Hz | EGT 3/4 |
| 0x104 | ENGINE_COOLING_V1 | 5 Hz | coolant temperature |
| 0x180 | EIU_ELECTRICAL_V1 | 2 Hz | EIU supply voltage/current |
| 0x600 | SENSOR_STATUS_V1 | 2 Hz | sensor validity/fault bitmap |
| 0x601 | EIU_HEALTH_V1 | 1 Hz | EIU health/reset/internal state |
| 0x091 | NODE_HEARTBEAT_V1 | 1 Hz | node alive/protocol version |

Exact byte layouts are defined by `protocol/aef-can.yaml`, which is the machine-readable source of truth.

## 7. Encoding rules

### 7.1 Integers, not floating point

Wire values use fixed-width scaled integers. Examples:
- 4.23 bar -> integer 423 at 0.01 bar/LSB;
- 96.4 degC -> integer 964 at 0.1 degC/LSB;
- 4870 RPM -> integer 4870 at 1 RPM/LSB.

### 7.2 Canonical wire units

| Quantity | Canonical representation |
|---|---|
| temperature | 0.1 degC |
| pressure | 0.01 bar |
| voltage | 0.01 V |
| current | 0.01 A |
| rotational speed | 1 RPM |
| altitude (future) | 0.1 m |
| speed (future) | 0.01 m/s |
| fuel quantity (future) | 0.01 L |

Consumers convert canonical values into user-selected display units. Unit preference never changes the wire format.

### 7.3 Endianness

All multi-byte V1 signal values are **little-endian**. This is a protocol rule, not an assumption inherited from a processor.

### 7.4 Reserved values/bytes

Reserved bytes and bits must be transmitted as zero and ignored by receivers unless a later compatible revision assigns them. Receivers must not fail solely because a reserved field becomes defined in a compatible minor revision.

## 8. Validity and faults

A numeric value alone is insufficient. Consumers must know whether it is trustworthy.

V1 sensor status defines these semantic states:
- VALID
- NOT_INSTALLED
- OPEN_CIRCUIT
- SHORT_CIRCUIT
- OUT_OF_RANGE
- STALE
- CALIBRATING
- SENSOR_FAULT

Where the compact measurement frame has no room for per-signal state, status is carried by the associated SENSOR_STATUS message and freshness is also enforced locally by each consumer.

A consumer must mark data stale when its message timeout expires, even if the last numeric value looked plausible.

Initial timeout guidance:
- 10 Hz data: stale after 500 ms;
- 5 Hz data: stale after 1 s;
- 2 Hz data: stale after 2 s;
- 1 Hz health/heartbeat: node considered missing after 3 s.

These are protocol defaults and may be tightened after bench testing.

### 8.1 SENSOR_STATUS_V1 scalable layout

The V1 status frame uses explicit logical sensor identifiers rather than a Rotax-specific fixed bitmap:

| Byte | Meaning |
|---:|---|
| 0 | producer node instance |
| 1 | status page |
| 2 | sensor ID A |
| 3 | state A |
| 4 | sensor ID B |
| 5 | state B |
| 6 | sensor ID C |
| 7 | state C |

A producer sends as many pages as required. Sensor IDs are stable protocol identifiers (for example RPM, oil pressure, CHT1 or EGT4); they are not ADC channel numbers. This permits different engines, sensor counts and multiple producer nodes without changing the state encoding. A sensor omitted from all current pages is not automatically assumed valid or installed; capabilities/configuration determine expectation.

## 9. Versioning and compatibility

AEF-CAN uses protocol **major.minor** versioning.

- **Major** changes may be incompatible.
- **Minor** changes are additive/backward compatible.
- Existing message byte meanings are never silently changed.
- A materially different payload receives a new message definition/name and, where necessary, a new CAN ID.
- Unrecognised messages are ignored.
- Missing optional messages are not automatically faults.
- Consumers declare which protocol major versions they support.

Firmware version and protocol version are independent.

## 10. Node identity and discovery

Nodes must not assume that there is exactly one EIU or one display.

A node announcement exposes at least:
- protocol major/minor;
- node type;
- logical node instance;
- hardware revision;
- firmware version or build identifier;
- capability bitmap.

Capabilities describe data a node can produce or services it can provide. This permits, for example, a 2-CHT Rotax installation and a future 6-cylinder engine monitor to coexist with the same protocol architecture.

A future extended discovery/service mechanism may carry human-readable product/serial information. V1 keeps periodic discovery compact to avoid wasting bus bandwidth.

## 11. Producer/consumer separation

Producers publish physical facts and source health. They do not publish presentation decisions.

Correct:
```text
oil_pressure = 1.72 bar
oil_pressure_status = VALID
```

Not part of the measurement protocol:
```text
oil_pressure_colour = RED
```

The Horizon configuration owns thresholds, colours, unit conversion and page layout.

## 12. Configuration and commands

V1 engine measurement operation is broadcast-first and does not require request/response polling.

The 0x580–0x5FF range is reserved for future controlled services such as:
- identify node;
- read calibration metadata;
- set authorised calibration;
- request diagnostics;
- select optional sample rates;
- invoke a sensor test.

Measurement delivery must not depend on these services being used.

Configuration writes should eventually use explicit acknowledgement, validation and persistence rules; they must not be introduced ad hoc.

## 13. CAN FD and future transports

The AEF data model is separated from the current Classical CAN encoding. A future node may use an external CAN-FD controller or a later MCU with native CAN FD.

Migration rules:
1. Classical CAN V1 remains a supported baseline for V1 nodes.
2. A CAN-FD extension must not be placed on a Classical-CAN-only bus without an explicit gateway/segmentation design.
3. Semantic signal names, units, validity and versioning should survive transport changes.
4. Generated application models should not expose a hard-coded eight-byte assumption beyond the Classical CAN codec.

## 14. Machine-readable source of truth

`protocol/aef-can.yaml` is authoritative for IDs, signals, units, scaling, rates, versions and timeouts.

Long-term generation targets:
- C/C++ encode/decode structures for ESP-IDF;
- Swift models/codecs for the iPhone simulator;
- Python decoders and log-analysis tools;
- Markdown protocol tables;
- deterministic test vectors;
- bus simulators/fuzz tests.

Generated files must carry a "do not edit; generated from aef-can.yaml" header.

## 15. Testing requirements

Before an AEF-CAN implementation is called validated, test at least:
- encode/decode round trips at min/nominal/max values;
- endianness;
- signed temperatures;
- missing frames and stale transitions;
- each sensor fault state;
- node disappearance/reappearance;
- unknown IDs;
- newer compatible minor-version traffic;
- bus-off/recovery behaviour;
- duplicate node-instance detection;
- realistic bus-load calculation;
- EIU-to-Horizon bench operation through real transceivers and termination.

Simulation/codec tests do not constitute physical CAN validation.

## 16. Initial implementation sequence

1. ~~Freeze V1 YAML schema and core message byte layouts.~~ **DONE for core V1.**
2. ~~Add a schema validator/linter.~~ **DONE: `scripts/validate-aef-can.py`.**
3. ~~Generate or hand-verify initial golden test vectors.~~ **DONE: `protocol/golden-vectors.txt`; initial vectors independently byte-checked.**
4. Implement a transport-neutral AEF data model.
5. Implement Classical CAN codec.
6. Add EIU simulator traffic.
7. Add Horizon consumer with stale/fault behaviour.
8. Bench-test two physical transceivers with 120-ohm end termination.
9. Add logging/diagnostic tooling.
10. Only then expand configuration services or additional node families.

## 17. Design principles to preserve

**Stable semantics over clever packing.** Save bandwidth, but never at the expense of ambiguous data.

**Publish facts, not UI.** Producers do not know how consumers present data.

**Validity is first-class data.** A believable stale value is worse than an obvious failure.

**Add, don't reinterpret.** New versions extend the protocol without changing old meanings.

**Hardware independence.** AEF-CAN belongs to the aircraft system architecture, not to ESP32.

**One specification.** Firmware, simulator, tests and documentation derive from the same machine-readable definition.


## 18. V1 implementation artefacts

The core V1 wire contract is now frozen sufficiently to start codecs and simulators.

- `protocol/aef-can.yaml` — authoritative machine-readable protocol definition.
- `protocol/golden-vectors.txt` — deterministic example frames for cross-language codec tests.
- `scripts/validate-aef-can.py` — structural validation of IDs, field overlap and Classical CAN payload bounds.

Changing the meaning, offset, scaling, signedness or unit of a frozen V1 field is an incompatible change and must not be committed as an in-place edit. Additive reserved-field use must obey the compatibility rules; otherwise define a new message/version.

The next implementation layer is a transport-neutral codec/model shared semantically across ESP-IDF C/C++, Swift and Python, followed by simulated EIU publication and Horizon freshness/fault consumption.


## 19. C codec implementation

The first executable V1 codec is now in `firmware/main/aef_can_codec.[ch]`. It is deliberately independent of ESP-IDF/TWAI and can therefore be compiled both into Horizon firmware and as ordinary host C.

Initial implemented codecs cover `ENGINE_FAST_V1`, two-temperature frames used by CHT/EGT, and `SENSOR_STATUS_V1`. Decoders enforce DLC and V1 reserved-byte/state constraints rather than accepting malformed frames silently.

Host regression is in `tests/aef_can_codec_test.c`; `scripts/test-aef-can-codec.sh` builds it with strict C11 warnings and compares encoded data with the frozen golden byte patterns. This is codec validation only, not TWAI/transceiver/bus validation.

Next implementation increment: complete the remaining V1 message codecs, add a small AEF frame dispatcher/freshness model, then connect that abstraction to simulated EIU publication before adding the ESP-IDF TWAI transport.


## 20. EIU and sensor discovery / commissioning architecture — 1 October 2026

AEF-CAN shall support **device discovery and capability enumeration** rather than assuming a permanently hard-coded EIU node/address. Discovery is layered because conventional analogue and thermocouple senders cannot electronically identify their semantic role.

### Discovery levels

1. **Device discovery.** An EIU announces node identity, device class, hardware/firmware/protocol versions and channel capabilities. Horizon can therefore discover a compatible EIU without a pre-created per-device configuration.
2. **Electrical discovery.** The EIU safely characterises each input as supported by its hardware: for example open/inactive, resistive, voltage, thermocouple or frequency/pulse. It reports raw diagnostic information and confidence/compatibility information where useful.
3. **Semantic assignment.** Electrical characteristics alone generally cannot prove that a resistive sender is oil temperature rather than another compatible temperature sender, nor can a thermocouple identify itself as EGT 1 versus EGT 2. Horizon therefore presents compatible roles/profiles during commissioning and requires explicit user confirmation.

### Persistent commissioning

After confirmation, the channel-to-role/profile mapping is stored persistently with enough identity/version information to detect incompatible hardware or configuration changes. Normal subsequent boots should require no commissioning interaction when the discovered hardware matches the stored configuration.

A stored mapping conceptually binds:
- EIU identity / compatible device class;
- physical channel;
- electrical input type;
- sender/profile identifier;
- semantic aircraft role (for example OIL_TEMP or EGT_1);
- calibration/configuration revision where applicable.

### Change and fault detection

The EIU continuously performs non-disruptive plausibility diagnostics appropriate to each configured channel. It shall distinguish, where electrically possible, valid measurement, open circuit, short circuit, out of range, missing sensor and unsupported/ambiguous state. Horizon must never turn these states into a plausible numeric indication.

If an input previously stored as empty later contains a plausible sensor, the EIU reports a **new/unassigned sensor** condition and Horizon offers commissioning for that channel. If a commissioned sensor disappears or changes incompatibly, Horizon reports the fault/change rather than silently remapping it.

Thermocouple discovery is deliberately limited: the EIU may detect a plausible thermocouple circuit/open circuit and its configured front-end type, but semantic cylinder/EGT assignment remains a commissioning decision.

### Published measurement contract

Normal AEF-CAN measurements should carry or be associated with:
- semantic sensor/channel identity;
- engineering value and defined units/scaling;
- validity/diagnostic state;
- sequence/freshness information;
- sufficient raw/diagnostic data for maintenance where the message family defines it.

Horizon shall invalidate stale data when freshness limits are exceeded. EIU reboot, sequence discontinuity, node loss/reappearance and configuration revision changes must be observable rather than hidden.

### Extensibility

The same mechanism is intended to support future EIU channels and other AEF-CAN sensor nodes (for example fuel pressure/level, manifold pressure or additional temperature modules) without embedding each physical product into Horizon UI logic. Producers publish identity, capabilities, facts and validity; Horizon owns semantic commissioning and presentation.

The machine-readable AEF-CAN schema will require additive discovery/capability/configuration message definitions before this feature is considered wire-protocol complete.


## 21. AEF-CAN remote firmware-update service — architecture

AEF-CAN shall provide a versioned maintenance service for remote node firmware delivery. This is separate from normal engine telemetry and must not reinterpret existing V1 measurement frames.

Required transaction semantics include: target-node identity and hardware compatibility; update request/ready refusal states; image metadata (product/hardware compatibility, version, size and cryptographic digest/signature metadata); ordered data transfer with explicit progress/acknowledgement and bounded retry; end-to-end complete-image verification; activation request; reboot/reappearance; running-version report; and success/rollback status.

Classical CAN bandwidth is acceptable because updates are infrequent and reliability is preferred over speed. The exact segmentation/windowing scheme and CAN identifiers are **not yet frozen** and must be added additively to the machine-readable protocol schema.

The EIU bootloader independently verifies firmware authenticity before execution. CAN transport integrity, Horizon verification and cryptographic image authenticity are distinct checks.

Firmware update mode must not produce stale-but-plausible engine data: Horizon explicitly marks EIU engine indications unavailable/stale while the node is in maintenance/update/reboot state.


### Executable V1 maintenance transport — 1 October 2026

The first executable transport model is now implemented in `ota-server/admin/eiu_can_ota.py`. The canonical schema reserves 0x5C0-0x5FF for firmware maintenance and defines `FW_CONTROL_V1` (0x5C0), `FW_META_V1` (0x5C1), `FW_DATA_V1` (0x5C2) and `FW_STATUS_V1` (0x5C3).

The V1 baseline deliberately uses simple stop-and-wait segmentation: each Classical CAN DATA frame contains a uint16 sequence number and up to six firmware bytes. The simulated EIU rejects out-of-order blocks and oversized data, acknowledges accepted sequence numbers, verifies the complete image digest before activation, retains the RPM=0 activation gate and exercises first-boot confirmation/configuration preservation. This simple baseline favours deterministic recovery and testability; a later additive windowed transport may improve throughput without redefining V1.

`test_eiu_can_ota.py` is part of the normal Docker rebuild/test runner. This remains protocol simulation, not physical TWAI/CAN validation.
