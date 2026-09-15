# Flight-development enclosure

This document records the current 3D-printable enclosure for the ESP32 supplementary/non-primary multifunction flight instrument.

## Front geometry — unchanged

Adding Altimeter and Compass does not enlarge the face. The design remains conventional 3 1/8-inch format: 80.30 mm reference panel opening, 79.60 mm locating body, 88 × 88 mm flange, 58 mm depth target, 62.9 mm four-hole pattern, Newhaven round LCD, 55 mm clear aperture and PEC09 front control.

The front bezel, body, optical window, display carrier, BMI088 carrier and 68 mm PCB fit-gauge geometry therefore remain valid.

## Rear-cover multifunction revision

The selected Bosch BMP581 pressure system and remote PNI RM3100-CB require two rear services. The OpenSCAD source now adds **two reinforced 12 mm diameter × 5 mm bosses**, each with an intentionally undersize **3 mm pilot hole**:

- upper-left rear: `STATIC` service for static-pressure plumbing
- upper-right rear: `MAG` service for the remote magnetometer harness

The final fitting and connector/gland are not guessed in CAD. Print with the pilot holes, then enlarge/machine only after the purchased hardware has been measured. This gives a mechanically useful revision now without locking the project to an arbitrary thread.

At this stage only the **rear-cover geometry changes**. Regenerate its STL from the current SCAD before printing the multifunction cover.

## Pressure installation

The reference pressure IC is **Bosch BMP581**, ultimately mounted on the custom carrier. It has no hose barb, so the PCB/mechanical design must form a small sealed pressure plenum around its pressure opening and connect that chamber to the STATIC fitting.

Requirements: do not obstruct the sensor opening with adhesive/coating/gasket debris; support the tubing independently of the sensor; leak-test chamber/fitting; prevent cabin-pressure leakage into the static chamber; avoid kinks and excessive pneumatic volume; select the final fitting to match the aircraft's actual static tubing.

## Remote magnetometer

The reference heading sensor is **PNI RM3100-CB** and is deliberately remote from the display/ESP32/DC-DC/backlight/steel panel hardware. The MAG boss is therefore a cable service only. The sensor needs a separate rigid non-magnetic bracket with permanent FWD/UP/lateral-axis markings and strain relief at both cable ends. Keep its harness away from high-current wiring.

## Existing internal stack

Front to rear remains: bezel/PEC09 → 62 × 2 mm hard-coated AR window → LCD → removable display carrier → rigid BMI088 cradle → 68 mm custom carrier PCB on 60 mm PCD → rear cover. USB-C remains at the lower rear with its existing service slot and cable strain relief.

The carrier PCB layout must now accommodate the bare BMP581/plenum and locking remote-magnetometer connector. The 58 mm depth remains the target until a physical fit test proves otherwise.

## CAD / STL status

Authoritative source: `enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad`.

Current targets are body, front bezel, display carrier, BMI088 carrier, custom PCB fit gauge, revised rear cover and USB strain-relief clamp. The **rear-cover STL must be regenerated** after this source change; older rear-cover STL files do not contain STATIC/MAG bosses.

## Verification

Before aircraft use: verify display/IMU/USB fit, leak-test static plumbing, check pressure response/lag/hysteresis, prove the RM3100-CB mount cannot move, characterize magnetic interference with electrical loads on/off, verify sensor-axis transforms, and deliberately disconnect/stale each source to confirm an unmistakable invalid indication.

This remains a supplementary/non-primary instrument under flight development.
