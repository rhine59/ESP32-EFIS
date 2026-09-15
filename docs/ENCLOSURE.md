# Flight-development enclosure

This document records the current 3D-printable enclosure for the ESP32 supplementary/non-primary multifunction flight instrument.

## Front geometry — unchanged

Adding Altimeter and Compass does not enlarge the face. The design remains conventional 3 1/8-inch format: 80.30 mm reference panel opening, 79.60 mm locating body, 88 × 88 mm flange, 58 mm depth target, 62.9 mm four-hole pattern, Newhaven round LCD, 55 mm clear aperture and PEC09 front control.

The front bezel, body, optical window, display carrier, BMI088 carrier and 68 mm PCB fit-gauge geometry remain valid.

## Rear-cover multifunction revision

The Bosch BMP585 pressure system and remote PNI RM3100-CB require two rear services. The OpenSCAD source now adds **two reinforced 12 mm diameter × 5 mm bosses**, each with an intentionally undersize **3 mm pilot hole**: upper-left `STATIC` and upper-right `MAG`.

The final fitting/gland is not guessed in CAD. Enlarge the pilot only after purchased hardware is measured. At this stage only rear-cover geometry changes; regenerate its STL from the current SCAD before printing the multifunction cover.

## Pressure installation

First plumbing development uses the **Adafruit BMP585 Ported breakout PID 6413**, avoiding an improvised sensor plenum during early tests. The module/tubing must be supported independently and connected through the STATIC service. Leak-test the system, prevent cabin-pressure leakage, avoid kinks/excessive pneumatic volume and select the final fitting to match the aircraft's actual static tubing.

After bench/static testing, decide whether the final article retains a separately mounted ported BMP585 module or integrates the bare BMP585 with a purpose-designed sealed plenum. That decision will trigger the next carrier/rear-cover CAD revision automatically.

## Remote magnetometer

The reference heading sensor is **PNI RM3100-CB**, deliberately remote from display/ESP32/DC-DC/backlight/steel panel hardware. The MAG boss is a cable service only. The sensor needs a separate rigid non-magnetic bracket with permanent FWD/UP/lateral-axis marks and strain relief at both cable ends. Keep its harness away from high-current wiring.

## Existing internal stack

Front to rear remains bezel/PEC09 → 62 × 2 mm hard-coated AR window → LCD → display carrier → rigid BMI088 cradle → 68 mm custom carrier PCB on 60 mm PCD → rear cover. USB-C remains at the lower rear with service slot and cable strain relief. The 58 mm depth remains the target until physical fit proves otherwise.

## CAD / STL status

Authoritative source: `enclosure/source/ESP32_Artificial_Horizon_Flight_Development_Case.scad`. Current targets are body, front bezel, display carrier, BMI088 carrier, custom PCB fit gauge, revised rear cover and USB strain-relief clamp. **Older rear-cover STLs do not contain STATIC/MAG bosses and must not be treated as current multifunction geometry.**

## Verification

Before aircraft use: verify display/IMU/USB fit; leak-test static plumbing; check pressure response/lag/hysteresis; prove RM3100-CB mounting cannot move; characterize magnetic interference with electrical loads on/off; verify sensor-axis transforms; deliberately disconnect/stale each source and confirm unmistakable invalid indication.

This remains a supplementary/non-primary instrument under flight development.
