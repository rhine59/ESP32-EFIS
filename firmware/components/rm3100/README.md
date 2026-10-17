# RM3100 native ESP-IDF driver — reference manual

**Applies to:** `rm3100.c` / `include/rm3100.h` in this repository, ESP-IDF 5.x, ESP32-S3.  
**Status:** compiled successfully with ESP-IDF 5.4.4 in standalone and full EFIS builds (diagnostics enabled); **not validated with a physical RM3100**.  
**Scope:** I²C implementation only; supplementary/non-primary EFIS. The authoritative integration/build record is [docs/RM3100-ESP-IDF-PORT-AND-VALIDATION.md](../../../docs/RM3100-ESP-IDF-PORT-AND-VALIDATION.md).

## 1. Purpose and architecture

This component controls the PNI RM3100 three-axis magnetometer using the documented register interface. It is a native C ESP-IDF implementation inspired by the functionality of [EvdokimovVladimir/RM3100](https://github.com/EvdokimovVladimir/RM3100), not a verbatim Arduino translation. No Arduino core, Wire, or SPIClass dependency is needed.

The **caller creates and owns** the ESP-IDF I²C master bus. `rm3100_init` adds an I²C device to that bus; `rm3100_deinit` removes the device but does **not** delete the bus. In EFIS, the MCP23008 module creates the shared bus and exposes `mcp23008_bus_handle()`; the RM3100 borrows it. Bus must remain valid until RM3100 deinit. Configuration and lifecycle calls must be serialized by the application if used across tasks.

Data flow: I²C bus → RM3100 register transactions → signed 24-bit XYZ counts → approximate µT conversion → **diagnostic logs only**. Calibration, tilt compensation and heading presentation are intentionally absent.

## 2. Hardware and electrical interface

The intended part is the **PNI RM3100-CB, P/N 14754**, pending procurement/commissioning. Connect the *actual carrier board* using its documented supply voltage, logic voltage and pinout. Do not assume a bare RM3100 sensor or an unknown breakout is 5 V tolerant.

| Connection | Requirement |
| --- | --- |
| Supply / ground | Verify carrier board supply rating; common ground with ESP32-S3 |
| SDA / SCL | ESP32-S3 I²C master bus; external pull-ups appropriate to bus capacitance |
| Address straps | SA1/SA0 select a 7-bit address from 0x20 to 0x23 |
| DRDY | Not used by this driver; data-ready is polled via STATUS |
| SPI | Not implemented in this component |
| Remote cable | Validate bus rise time, pull-ups, shielding/grounding and noise at actual cable length |

The EFIS bus is already used by MCP23008. The application currently configures that bus with internal pull-ups; these are generally too weak to rely upon for a long remote I²C cable. Verify external pull-ups, bus voltage, total capacitance and interference before fitting to an aircraft.

## 3. Build integration

Component directory: `firmware/components/rm3100`. `CMakeLists.txt` registers `rm3100.c`, publishes `include` and requires `esp_driver_i2c` and `esp_timer`. A consuming ESP-IDF component should declare `rm3100` in `REQUIRES` or `PRIV_REQUIRES`, as appropriate.

Include `#include "rm3100.h"`. The public header is C++ compatible through `extern "C"`.

## 4. Public types and constants

`rm3100_t`: device handle (`dev`), current cycle count (`cycle_count`), and software-tracked continuous-mode flag (`continuous`). **Initialize to zero** and treat members as internal state; do not mutate them directly.

`rm3100_sample_t`: signed 32-bit `x`, `y`, `z` containing sign-extended 24-bit counts; `timestamp_us` is the ESP32 local time at the end of the I²C read, **not** the magnetic conversion instant.

| Constant | Value | Meaning |
| --- | --- | --- |
| `RM3100_I2C_ADDRESS_DEFAULT` | `0x20` | Default address; actual board straps may differ |
| `RM3100_CYCLE_COUNT_DEFAULT` | `200` | Default per-axis cycle count |
| `RM3100_TMRC_75HZ` | `0x93` | Timing register code labelled 75 Hz |
| `RM3100_TMRC_37HZ` | `0x94` | Timing register code labelled 37 Hz; initial setting |

Timing-register labels indicate requested update timing, **not guaranteed effective three-axis sample rate**. Effective rate depends on cycle count and conversion duration; measure it on the hardware.

## 5. API reference

All APIs return `esp_err_t`. `ESP_OK` means the *requested I²C/software operation* completed, not that magnetic measurements are calibrated or valid for flight.

| Function | Purpose | Preconditions / notes |
| --- | --- | --- |
| `rm3100_init(sensor, bus, address, scl_speed_hz)` | Attach device, probe, stop conversions, set CC=200 and TMRC=0x94 | Non-null zeroed sensor and live bus; address 0x20–0x23; positive bus clock. On failure attempts cleanup |
| `rm3100_deinit(sensor)` | Stop and remove I²C device, clear structure | Do not use device afterwards; bus remains caller-owned |
| `rm3100_get_revision(sensor, revision)` | Read register 0x36 | Revision is **not** a unique identification signature |
| `rm3100_set_cycle_count(sensor, count)` | Write same cycle count to X/Y/Z CC registers | This implementation permits **30–400**; updates cached count only on successful write |
| `rm3100_set_tmrc(sensor, tmrc)` | Set timing register | This implementation permits raw codes **0x92–0x9F**; does not enforce conversion feasibility |
| `rm3100_start_continuous(sensor)` | Enable X/Y/Z continuous measurements | Sets CMM=0x71; updates software mode flag on success |
| `rm3100_stop(sensor)` | Stop continuous measurements | Sets CMM=0; software flag updated on success |
| `rm3100_trigger_single(sensor)` | Trigger one X/Y/Z measurement | Only when `continuous == false`; caller must wait for data-ready |
| `rm3100_data_ready(sensor, ready)` | Read STATUS bit 7 | Polling call; `ready` is meaningful only if return is `ESP_OK` |
| `rm3100_read_raw(sensor, sample)` | Read 9 bytes XYZ and timestamp | **Does not check DRDY**; call after ready to avoid stale samples |
| `rm3100_read_when_ready(sensor, sample, timeout_ms)` | Poll STATUS until ready, then read XYZ | Approximately 5 ms polling intervals, finite elapsed-time deadline; may return `ESP_ERR_TIMEOUT` |
| `rm3100_raw_to_ut(sensor, sample, xyz_ut)` | Approximate counts-to-µT conversion | Requires valid cached cycle count; **no calibration** |

### Error behavior

- `ESP_ERR_INVALID_ARG`: invalid pointer/address/speed/cycle count/timing code or similar invalid arguments.
- `ESP_ERR_INVALID_STATE`: single-shot requested while software flag indicates continuous mode.
- `ESP_ERR_TIMEOUT`: no DRDY before `read_when_ready` deadline, or potentially a lower-level I²C timeout.
- Other ESP-IDF I²C errors propagate from `i2c_master_*`. Log `esp_err_to_name(err)` and distinguish missing device, bus contention, invalid address and electrical faults.
- `rm3100_deinit` attempts a stop but returns the device-removal result; the stop error is intentionally ignored.

**Concurrency:** This is not a multi-task synchronized device abstraction. Use one owner task or an application mutex around mode changes, reads and deinit. Do not delete the I²C bus while the device exists.

## 6. Device register map used by the implementation

| Address | Name | Access performed | Description |
| --- | --- | --- | --- |
| `0x00` | POLL | Write | Single-shot X/Y/Z trigger; payload `0x70` |
| `0x01` | CMM | Write | Continuous measurement; `0x71` start, `0x00` stop |
| `0x04` | CCX | Write 6 bytes | CCX, CCY, CCZ; each 16-bit, high byte first |
| `0x0B` | TMRC | Write | Measurement timing control |
| `0x24` | MX | Read 9 bytes | X, Y, Z each signed 24-bit, most significant byte first |
| `0x34` | STATUS | Read | Bit 7 DRDY (`0x80`) |
| `0x36` | REVID | Read | Revision value |

The driver sends the register address then uses an I²C transmit-receive transaction for reads. Bus transaction timeout is **100 ms**. For writes, the driver uses a register prefix and up to 8 data bytes. The nine-byte measurement is read using `i2c_master_transmit_receive`.

## 7. Initialization and use

The following code assumes the application has **already created the I²C master bus**. Never create a second master bus on the same SDA/SCL pins just for this driver.

```c
#include "rm3100.h"
#include "esp_log.h"

static const char *TAG = "mag";

static void read_magnetometer(i2c_master_bus_handle_t bus)
{
    rm3100_t mag = {0};
    esp_err_t err = rm3100_init(&mag, bus, 0x20, 100000);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "init: %s", esp_err_to_name(err));
        return;
    }

    uint8_t rev = 0;
    if (rm3100_get_revision(&mag, &rev) == ESP_OK)
        ESP_LOGI(TAG, "revision 0x%02x", rev);

    err = rm3100_start_continuous(&mag);
    if (err == ESP_OK) {
        rm3100_sample_t sample;
        err = rm3100_read_when_ready(&mag, &sample, 150);
        if (err == ESP_OK) {
            float ut[3];
            if (rm3100_raw_to_ut(&mag, &sample, ut) == ESP_OK)
                ESP_LOGI(TAG, "X=%+.2f Y=%+.2f Z=%+.2f uT",
                         ut[0], ut[1], ut[2]);
        }
    }
    if (err != ESP_OK)
        ESP_LOGE(TAG, "measurement: %s", esp_err_to_name(err));

    (void)rm3100_deinit(&mag);
}
```

**Single-shot pattern:** initialize → ensure stopped → `rm3100_trigger_single` → `rm3100_read_when_ready` → process sample. **Continuous pattern:** initialize → `rm3100_start_continuous` → repeatedly `rm3100_read_when_ready` → stop/deinit. Avoid repeatedly reading faster than conversion; check timestamps and whether DRDY represents new data.

## 8. Counts, units, and heading

Each axis uses a signed **24-bit two's-complement** count. The driver sign-extends it to `int32_t`. Example: bytes `FF FF FF` become -1, and `80 00 00` become -8,388,608.

Approximate sensitivity in this implementation:

```text
gain_counts_per_uT ≈ 0.3671 × cycle_count + 1.5
magnetic_field_uT = raw_count / gain_counts_per_uT
```

At CC=200, the approximation is **74.92 counts/µT**. It is a device sensitivity estimate, **not a calibration**. There is no temperature compensation, sensor-axis rotation, bias correction, ellipsoid correction, tilt compensation or magnetic-to-true-heading conversion.

Do **not** derive heading simply from `atan2(y,x)` for aircraft use. Heading requires validated sensor orientation, hard/soft-iron compensation, attitude compensation using BMI088, magnetic declination policy, failure detection and known data age. Even then this EFIS is supplementary, not a certified primary instrument.

## 9. EFIS integration and diagnostic switch

EFIS uses `mcp23008_bus_handle()` after `mcp23008_init()`. Diagnostic-only code in `firmware/main/app_main.c` initializes the RM3100 and periodically logs magnetic XYZ values.

In `idf.py menuconfig` → **ESP32 EFIS development options**:
- `EFIS_RM3100_DIAGNOSTICS`: off by default; requires non-QEMU build.
- `EFIS_RM3100_I2C_ADDRESS`: `0x20` through `0x23`, default `0x20`.

The current diagnostic polls DRDY approximately every **200 ms** (20 iterations of the 10 ms main loop), and logs a sample if ready. This is a **diagnostic logging cadence**, not a promise of sensor output rate. It does not update the compass panel. In the source, the RM3100 diagnostic is compiled only when its Kconfig flag is enabled.

## 10. Troubleshooting

| Symptom | Likely checks |
| --- | --- |
| Init fails or NACK | Power/ground, SDA/SCL reversed, actual address straps, pull-ups, cable, bus clock, shared-bus initialization |
| Revision reads but no XYZ | CMM start success, STATUS DRDY, CC/TMRC compatibility, sensor power stability |
| Repeated or stale readings | Confirm DRDY before reading, reduce polling rate, inspect conversion cadence |
| Saturated or implausible field | Magnetic contamination, nearby currents/steel, wrong axes, wrong sensitivity assumption, sensor placement |
| High error rate during display activity | Shared I²C contention, electrical noise, cable capacitance, inadequate pull-ups |
| Compilation fails | ESP-IDF 5.x I²C master API, `esp_driver_i2c`/`esp_timer` dependencies, component discovery, project Kconfig |

For a failed measurement, log both error code and stage (probe, stop, CC, TMRC, CMM, STATUS, XYZ). A revision read alone is not proof that the sensor is genuine or healthy.

## 11. Verification and acceptance criteria

**Completed (17 October 2026):** native component standalone build passed; full EFIS build passed; full EFIS non-QEMU build with `CONFIG_EFIS_RM3100_DIAGNOSTICS=1` passed using ESP-IDF 5.4.4 on Mac. Firmware was not flashed.

**Still required:**
1. Procure and inspect actual RM3100 board; record pinout, address straps and supply limits.
2. Confirm probe, revision and readback of CC/TMRC on real hardware.
3. Capture raw and µT XYZ readings with the board held level and rotated through each axis; verify signs and axis mapping.
4. Characterize output rate versus CC/TMRC, DRDY behavior, timeouts, unplug/replug and bus recovery.
5. Verify shared MCP23008 bus under display load and at the intended remote cable length.
6. Characterize magnetic interference and complete installed hard/soft-iron calibration.
7. Add missing BIST, validated data quality/staleness checks and tilt-compensated heading only after bench evidence.
8. Preserve raw captures, logs, calibration parameters, test firmware hash and repeatable test results.

## 12. Known limitations and future work

- **I²C only**; SPI and DRDY GPIO interrupt support are absent.
- No RM3100 BIST/self-test, register readback verification or explicit power-reset sequencing.
- No built-in bus recovery, hot-plug support, application-level locking or retries.
- No per-axis cycle counts (writes same CC to all three axes).
- TMRC is range-checked, not validated against conversion time at selected CC.
- Timestamp is at read time; no sensor conversion timestamp or freshness guarantee.
- Microtesla conversion is approximate and not an installed-system calibration.
- No heading computation, magnetic declination or BMI088 fusion.
- No live EFIS compass connection.
- Not bench-tested with the physical RM3100; not flight validated.

## 13. References and source of truth

- PNI RM3100 sensor datasheet / user manual: use the revision appropriate to the purchased module to verify register fields, cycle-count timing, supply and sensitivity before bench commissioning.
- [Arduino library used as functional reference](https://github.com/EvdokimovVladimir/RM3100).
- [ESP-IDF I²C master documentation](https://docs.espressif.com/projects/esp-idf/en/v5.4.4/esp32s3/api-reference/peripherals/i2c.html).
- [Port and build-validation record](../../../docs/RM3100-ESP-IDF-PORT-AND-VALIDATION.md).
- [GitHub source repository](https://github.com/rhine59/ESP32-EFIS).

**Document applies to the implementation inspected on 17 October 2026.** Recheck against code whenever the driver changes.
