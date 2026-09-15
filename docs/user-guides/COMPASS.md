# Compass panel — user guide

## Purpose
The Compass panel is a classic round heading presentation with a fixed lubber line and heading bug. It is a supplementary/non-primary display.

## Controls
- **Short press:** next panel (Horizon).
- **Long press (~0.8 s):** enter/leave Compass settings.
- **Rotate while settings are active:** move the heading bug one degree per detent, wrapping through 000/359 degrees.
- **Short press while settings are active:** leave settings without changing panel.

## Display concept
The renderer provides a circular compass card, 10-degree ticks, stronger 30-degree divisions, a yellow fixed lubber line and yellow heading bug. The final version should add large cardinal/intercardinal labels and numeric heading readout suitable for the round 2.1-inch display.

## Heading source required
**BMI088 alone cannot provide a stable absolute compass heading.** Its gyro can propagate yaw for short periods but yaw will drift, and its accelerometer does not provide magnetic north.

The current Compass panel therefore remains explicitly invalid rather than presenting integrated gyro yaw as a compass heading.

A later design decision is required for the absolute heading source. Candidates include a properly installed/calibrated three-axis magnetometer, GNSS-derived track used explicitly as track rather than heading, or fusion of additional sources. A magnetometer inside an aircraft instrument panel must be evaluated carefully for magnetic interference from wiring, speakers, steel hardware, current-carrying conductors and other avionics.

## Heading versus track
The final UI must not silently label GNSS course-over-ground as magnetic heading. If GNSS track is offered, it should be identified as **TRK**. A true magnetic compass presentation requires a heading source and appropriate magnetic calibration/variation handling.

## Failure behaviour
If the selected heading source is missing, stale or fails validity checks, the compass display must be visibly invalid rather than freezing the previous heading.

## Bench/aircraft checks
Verify 360-degree continuity, heading-bug wraparound, source freshness, invalid-state behaviour and magnetic installation effects before relying on the supplementary indication.
