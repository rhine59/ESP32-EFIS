# RM3100 ESP-IDF component (I2C)

Native ESP-IDF 5.x I2C-master implementation of the RM3100 functionality used by the Arduino library [EvdokimovVladimir/RM3100](https://github.com/EvdokimovVladimir/RM3100) (MIT). This is a clean-room adaptation of the documented device register interface, not a verbatim copy of Arduino source. It does not depend on Arduino, Wire, or SPIClass.

## Scope
- I2C addressing (0x20..0x23), revision register, cycle counts, timing register.
- Single-shot and continuous three-axis acquisition.
- STATUS.DRDY polling with finite timeout.
- Signed 24-bit results, timestamps, approximate microtesla conversion.
- ESP-IDF error propagation and bus ownership.

## Example (after creating an I2C master bus)
```c
#include "rm3100.h"
rm3100_t mag = {0};
ESP_ERROR_CHECK(rm3100_init(&mag, bus_handle, 0x20, 100000));
ESP_ERROR_CHECK(rm3100_start_continuous(&mag));
rm3100_sample_t raw;
esp_err_t err = rm3100_read_when_ready(&mag, &raw, 150);
if (err == ESP_OK) {
    float ut[3];
    ESP_ERROR_CHECK(rm3100_raw_to_ut(&mag, &raw, ut));
}
```

## Integration gates
1. **I2C only** in this first port. SPI, DRDY GPIO interrupt and BIST self-test are not yet implemented.
2. No live EFIS heading integration. First confirm actual board address, 3.3 V supply, cable length, pull-ups, revision, axis mapping, and data-ready behaviour on hardware.
3. Calibration (hard/soft iron, installation rotation and tilt compensation) is separate. Approximate raw-to-uT conversion is **not** a calibrated heading.
4. The RM3100 revision register is not a guaranteed unique chip-ID signature; probe success alone does not authenticate the device.
5. This driver has not yet been exercised on the physical RM3100; bench tests and compile validation remain required.
6. On shared I2C buses, serialize multi-register configuration and coordinate ownership with the rest of firmware.
