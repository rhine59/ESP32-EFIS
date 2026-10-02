# Thingies RedOne / BlueOne mechanical materials and thermal standard

Status: **ADOPTED design direction — validate by prototype test before production freeze.**

This document records the current materials, enclosure fastening and thermal-management decisions for the Thingies **RedOne** EFIS and **BlueOne** Engine Interface Unit (EIU).

## 3D-printing materials

- **PLA / PLA+** — dimensional and fit prototypes only. Do not use as the normal installed cockpit enclosure material.
- **PETG** — development fixtures and suitable internal/non-sun-exposed parts.
- **ASA** — default production-direction material for the RedOne main enclosure, rear cover and display bezel because of its useful heat, UV and environmental resistance.
- **PA-CF (carbon-fibre nylon)** — reserve for selected high-load/high-temperature parts where testing demonstrates a real advantage. Do not make it the default enclosure material merely for stiffness/appearance.
- **TPU (nominally 95A unless testing selects otherwise)** — seals, feet and vibration-isolation components.

ASA may be specified in different colours. Production BOM entries shall ultimately identify **manufacturer, exact ASA grade and colour**, not merely “ASA”, because pigment and formulation can affect thermal/UV behaviour. Enclosure colour and product identity are separate decisions; RedOne need not have an all-red enclosure and BlueOne need not have an all-yellow enclosure.

## Threaded enclosure fasteners

For repeatedly serviced RedOne enclosure joints, use **M5 brass heat-set threaded inserts** installed into purpose-designed ASA bosses and mating stainless-steel machine screws.

Documentation, CAD and BOMs shall use the term **heat-set threaded insert** for this feature. Reserve **captive nut** for a separate nut mechanically retained in a pocket or cage.

Boss geometry shall be designed for the selected insert rather than using a generic printed hole. Provide adequate radial wall thickness, insertion lead-in, insert depth and local ribs/support. Insert installation temperature and process shall be validated on the final ASA grade.

For BlueOne, heat-set inserts remain an option, but mechanically captive nuts or other metal insert systems remain candidates until the EIU mounting location, temperature and vibration environment are frozen and tested.

## RedOne thermal design

Do **not** add a conventional finned heatsink or cooling fan by default.

The primary thermal risks are the 1000-nit display/backlight, ESP32-S3, DC-DC conversion/protection electronics and cockpit solar loading. The design shall therefore:

1. use passive thermal management first;
2. keep heat-producing power electronics sensibly separated from temperature-sensitive components;
3. retain useful internal air volume and avoid unnecessary insulating structures around hot components;
4. provide PCB copper area and thermal vias where appropriate;
5. reserve mechanical provision for a small thermal pad/internal aluminium heat spreader if prototype testing demonstrates that one is required;
6. avoid enclosure ventilation holes by default because they increase dust/moisture contamination;
7. avoid a fan unless measured thermal performance shows passive cooling is inadequate.

The design target for validation is currently **-20 °C to +70 °C enclosure/environmental range**, aligned with the display operating range. This is a development target, not a certification claim.

## Temperature monitoring

RedOne shall include a **dedicated PCB/internal temperature sensor** suitable for engineering measurement and operational diagnostics. Do not rely solely on the ESP32 internal temperature indication for enclosure thermal validation.

Firmware shall make the measured temperature available to diagnostics/logging and support configurable thermal warning/fault thresholds. The exact sensor, location and thresholds are to be frozen after thermal characterization.

## RedOne thermal validation

Test a representative assembled unit at minimum under:

- maximum display brightness;
- representative maximum processor load;
- CAN activity;
- maintenance-mode Wi-Fi/Bluetooth activity where applicable;
- representative aircraft supply conditions;
- elevated ambient temperature;
- representative solar loading.

Record internal/PCB temperature and critical component temperatures until thermal equilibrium. Use the results to decide whether an internal aluminium spreader or other passive measure is required.

## BlueOne EIU thermal design

Do not assume the RedOne ASA enclosure solution automatically applies to BlueOne.

The BlueOne mounting location may expose it to higher ambient temperature, vibration and harness/connector loads. Its PCB should use appropriate copper areas and thermal vias from the outset. An internal aluminium spreader, enclosure-coupled heat path, PA-CF enclosure component, or alternative enclosure/material may be selected after the actual installation environment is defined.

Before BlueOne enclosure freeze, establish and test its maximum/minimum ambient temperature, vibration, moisture/contamination exposure and connector mechanical loads.

## Design principle

**Measure before adding cooling hardware.** The architecture shall provide thermal sensing and provision for passive heat spreading, but heatsinks, vents and fans are not fitted without test evidence that they are required.
