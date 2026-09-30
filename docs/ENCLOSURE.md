# Flight-development enclosure

This document records the current 3D-printable enclosure for the ESP32 supplementary/non-primary multifunction flight instrument.

## Front geometry — unchanged

Adding Altimeter and Compass does not enlarge the face. The design remains conventional 3 1/8-inch format: 80.30 mm reference panel opening, 79.60 mm locating body, 88 × 88 mm flange, 58 mm depth target, 62.9 mm four-hole pattern, Newhaven round LCD, 55 mm clear aperture and PEC09 front control.

The front bezel, body, optical window, display carrier, BMI088 carrier and 68 mm PCB fit-gauge geometry remain valid.

## Rear-cover multifunction revision

The Bosch BMP585 static-pressure system and remote PNI RM3100-CB require rear services. The OpenSCAD source now adds **two reinforced 12 mm diameter × 5 mm bosses**, each with an intentionally undersize **3 mm pilot hole**: upper-left `STATIC` and upper-right `MAG`.

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

## Current production mechanical direction — 26 September 2026

The production concept places the EFIS body **behind the binnacle**. A minimal number of small cap-head Allen mounting bolts enter from the front of the binnacle and engage recessed stainless captive nuts in the enclosure; loose rear mounting nuts are not intended. Enclosure assembly hardware should also be minimised.

Production power is nominal **12 V aircraft input** through an appropriate protected/filtering conversion stage to internal 5 V and 3.3 V rails; USB-C becomes primarily a service/programming interface. The rear/interface concept also reserves GNSS and protected DATA/EXPANSION connectivity. Exact connector families, mounting pattern and dimensions remain unfrozen pending physical validation. Earlier renders/CAD remain conceptual where they conflict with these later requirements.



## Airspeed scope decision — 26 September 2026

**ASI/IAS capability is removed from the EFIS scope.** The enclosure requires only the **STATIC** pneumatic connection for the BMP585 altitude/barometric-pressure system. There is no PITOT connection and no differential-pressure sensor. Preserve the established round-display/front-bezel/PEC09/behind-binnacle/captive-nut enclosure concept. The previously generated rectangular multi-button image remains rejected and is not a design reference.


## Engine-sensor plug and GNSS connector revision — 30 September 2026

**ADOPTED DESIGN DIRECTION / CONNECTOR FAMILY TO BE FROZEN.** Provide externally accessible, keyed and positively retained plug access on the enclosure for a grouped engine-sensor harness. The intended initial measurement set is CHT, EGT, oil temperature, oil pressure and coolant/water temperature, with signal conditioning/protection appropriate to each sender type. Do not expose raw ESP32 GPIO/ADC pins at this connector. Final pin count, connector family, shielding/grounding, thermocouple treatment and whether conditioning lives on the main carrier or a separate engine-interface PCB remain engineering decisions pending sender identification and electrical validation.

The previously reserved dedicated **GNSS connector is removed**. GNSS is instead intended to use an external **USB GPS mouse/receiver** connected through the instrument USB interface. This requires USB-host support, suitable receiver/protocol selection and a mechanically retained service/flight connection; do not assume an arbitrary USB GPS device is compatible until validated. The GPS unit may be physically passive from the pilot's perspective, but a USB receiver is an active powered electronic device.
