# Minimal Physical OTA Test Node

## Purpose

Provide the smallest possible physical ESP32-S3 setup for exercising the ESP32-EFIS OTA lifecycle independently of the EFIS display, sensors, GNSS, CAN/EIU and other aircraft hardware.

This is a development and regression-test fixture. It is not an aircraft instrument.

## Minimum hardware

- One ESP32-S3 development board
- USB cable for power, initial programming and serial diagnostics
- Wi-Fi network with access to the ESP32-EFIS OTA service
- One visible status LED
  - Prefer the board's controllable onboard LED where suitable.
  - Otherwise use one external LED, approximately 330 ohm series resistor, and a spare GPIO.

No display, AHRS, pressure sensors, GNSS receiver, CAN interface or EIU is required.

## Two permanent test images

Maintain two deliberately trivial firmware builds. They should differ visibly and identify themselves over serial and the device status page.

| Image | Example version | Visible indication | Serial identity |
| --- | --- | --- | --- |
| OTA-A | 0.1.0-A | slow LED blink, approximately 1 Hz | ESP32-EFIS OTA TEST - IMAGE A |
| OTA-B | 0.1.0-B | fast LED blink, approximately 4 Hz | ESP32-EFIS OTA TEST - IMAGE B |

A and B should remain permanently buildable so OTA regression tests can repeatedly alternate A -> B -> A without depending on production EFIS firmware.

## Required OTA behaviour

Publishing an image must NOT automatically install or activate it on a device.

The physical test node must preserve distinct user-controlled states:

1. **Running** - current active image.
2. **Available** - newer/different image discovered in the published manifest.
3. **Downloaded/staged** - image has been pulled into the inactive OTA partition and verified.
4. **Activation requested** - user explicitly authorises switching to the staged image.
5. **Rebooting** - boot selection changes and the device restarts.
6. **Healthy** - new image completes its startup checks and confirms itself.
7. **Rollback** - later negative tests deliberately fail health confirmation and prove recovery.

The basic experiment is:

    Image A running
          |
          v
    publish Image B
          |
          v
    CHECK FOR UPDATE
          |
          v
    B shown as available
          |
          v
    DOWNLOAD
          |
          v
    B written to inactive OTA partition
          |
          v
    SHA-256 / image verification succeeds
          |
          v
    ACTIVATE & REBOOT
          |
          v
    Image B boots
          |
          v
    fast LED + version B confirms success

Repeat in the opposite direction to test B -> A.

## Minimal user interface

For the first physical harness, host a very small status/control web page on the ESP32 so a Mac, iPhone or other browser on the test network can operate it.

Example:

    ESP32-EFIS OTA TEST NODE

    Running firmware:       0.1.0-A
    Published firmware:     0.1.0-B
    Downloaded firmware:    none

    Wi-Fi:                  Connected
    OTA server:             Reachable

    [ CHECK FOR UPDATE ]

    Update 0.1.0-B available

    [ DOWNLOAD ]

    Firmware downloaded
    SHA-256: OK
    Ready for activation

    [ ACTIVATE & REBOOT ]

The interface must make it obvious that **DOWNLOAD** and **ACTIVATE & REBOOT** are separate user actions.

Serial logging should expose the same state transitions for diagnosis and automated testing.

## Partitioning

Use an ESP-IDF OTA-capable partition table with OTA metadata and two application slots (for example ota_0 and ota_1). The test project should use the same fundamental A/B update mechanism intended for production ESP32-EFIS firmware.

Exact partition sizes should be selected when the test firmware is implemented, with enough headroom to test images representative of expected production firmware.

## Suggested repository implementation

Create a self-contained test project, for example:

    tools/
      ota-device-test/
        README.md
        CMakeLists.txt
        sdkconfig.defaults
        partitions.csv
        main/
          CMakeLists.txt
          main.c
          wifi.c
          ota.c
          webui.c

The implementation should be intentionally small, but the OTA state machine and verification rules should be reusable or representative of the production implementation.

## Relationship to the server harness

The physical node complements the existing Synology OTA server/admin test harness.

    ESP32-S3 physical test node
             |
             | Wi-Fi / HTTPS
             v
    ESP32-EFIS OTA service
             |
             +-- manifest
             +-- Image A
             +-- Image B
             +-- image hashes / metadata

Server-side tests prove staging, publishing, manifests and downloads. The physical node proves that a real ESP32 can discover, pull, verify, stage and activate those published images.

## Initial acceptance tests

The first hardware milestone is complete when all of the following have been demonstrated:

- Image A can be installed initially by USB.
- A visibly identifies itself with the slow LED pattern.
- B can be published through the OTA administration workflow.
- A discovers B without automatically installing it.
- User can explicitly download B.
- Downloaded B is stored in the inactive OTA slot.
- Image integrity is verified before activation.
- A continues running after download until activation is requested.
- User can explicitly request ACTIVATE & REBOOT.
- B boots and visibly identifies itself with the fast LED pattern.
- Device reports B as the running version.
- The process can be reversed by publishing and installing A again.

## Later destructive/negative tests

After A/B operation is reliable, add a third intentionally unsuitable test image (for example OTA-C-BAD) solely for controlled bench testing. It can deliberately withhold successful startup confirmation so ESP-IDF rollback behaviour can be verified.

Later tests should cover:

- interrupted download
- loss of Wi-Fi during download
- corrupt image/hash mismatch
- malformed or unavailable manifest
- power interruption before activation
- power interruption during reboot/first boot where practical
- failed post-boot health check
- automatic rollback
- inability to activate an unverified image
- repeated A/B/A regression cycles

## Safety/design rule

OTA publication, download and activation are separate events.

The production design must never interpret publication alone as permission to change the running EFIS firmware. The physical test node exists specifically to make that lifecycle observable and testable before the mechanism is integrated with the full EFIS application.
