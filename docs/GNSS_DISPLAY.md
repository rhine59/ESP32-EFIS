# GNSS position and accuracy display

## Adopted requirement

The **Horizon/PFD** and **Compass** pages shall both include GNSS position information when a valid GNSS source is available. Latitude and longitude are shown in WGS84 decimal degrees together with fix state, horizontal accuracy estimate and satellites used where available.

This is supplementary information. GNSS position does not replace the independent attitude, barometric-altitude or magnetic-heading sources.

## Position presentation

The compact 480×480 layout shall reserve a lower information strip for GNSS without obscuring the primary attitude or compass symbology. The minimum useful presentation is:

```text
GPS  53.9621°N  2.0143°W
3D   ACC 2.4m   8 SAT
```

The exact typography may be compressed after real-panel readability testing, but both Horizon/PFD and Compass must expose the same position-quality semantics.

## Accuracy colour coding

Colour applies to the **latitude/longitude numbers and accuracy value/status marker**, not merely a decorative icon:

| Horizontal accuracy estimate | Colour | Meaning |
|---:|---|---|
| <= 1 m | green | Excellent |
| > 1 m to 3 m | light green | Good |
| > 3 m to 10 m | yellow | Fair |
| > 10 m to 30 m | orange | Weak |
| > 30 m | red | Poor |
| no valid fix / stale / non-finite accuracy | red | Invalid |

These thresholds are project UI categories, not certification or integrity limits. They describe the receiver-reported horizontal accuracy estimate. They must not be presented as a guaranteed error bound.

## Validity and freshness

GNSS display validity is independent of attitude, altitude and magnetic heading. A failed GPS must not invalidate the artificial horizon or compass heading. Conversely, a valid GPS must not make an invalid attitude or magnetic-heading solution appear valid.

A position is display-valid only when the GNSS source reports a valid navigation fix, latitude/longitude are finite and in range, the horizontal accuracy estimate is finite/non-negative, and the sample is fresh. The implementation must define and test a stale timeout appropriate to the selected receiver/update rate. When invalid, coordinates are removed/obscured and the strip shows `GPS INVALID` or `GPS STALE` in red; the last plausible position must not remain displayed as though current.

## Heading and track terminology

Magnetic/true heading remains **HDG** and comes from the RM3100/AHRS heading pipeline. GNSS course over ground is **TRK**, never HDG. GNSS ground speed is **GS**, never IAS. If TRK/GS are later shown, they inherit GNSS validity/freshness but do not substitute for magnetic heading or airspeed.

## Data model

The shared instrument data model includes at least:

- `gps_latitude_deg`
- `gps_longitude_deg`
- `gps_horizontal_accuracy_m`
- `gps_satellites_used`
- `gps_fix_type`
- `gps_valid`
- `gps_stale`

The renderer uses the common `gnss_quality` classifier so Horizon and Compass cannot silently diverge in their colour thresholds.

## Receiver integration

The final GNSS receiver/interface is not yet frozen. Prefer a receiver/protocol that provides an explicit fix-valid indication and horizontal accuracy estimate rather than deriving a colour only from satellite count or HDOP. Receiver selection, antenna placement, RF coexistence, update rate and wiring remain hardware-design tasks.

## Simulation and tests

QEMU and Swift simulation must exercise at least: no fix, stale fix, <=1 m, 1–3 m, 3–10 m, 10–30 m and >30 m accuracy. Synthetic positions remain clearly marked as simulation data. Tests must verify that colour changes follow the shared thresholds and that GNSS failure does not freeze coordinates or alter unrelated instrument validity.
