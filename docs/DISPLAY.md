# Display Design

## Baseline panel

The selected display class is a **2.1-inch round 480×480 IPS LCD** using an **ST7701S-class controller**, in a **high-brightness/high-nit version** suitable for cockpit evaluation.

Preferred characteristics:

- 480×480 resolution
- IPS / wide viewing angle
- high-brightness backlight, ideally around 1000-nit class
- non-touch construction
- RGB pixel interface for high frame rate
- SPI or similar serial interface only for controller configuration where required

## Why 480×480

A 480×480 circular panel provides enough resolution for:

- smooth bank rotation
- crisp pitch ladder lines
- readable numeric pitch labels
- anti-aliased aircraft symbol
- warning annunciations
- future slip/skid or flight-director overlays

## Target frame rate

The display target is **30–60 fps**. Sensor acquisition should run faster than the display so the attitude solution remains responsive even if rendering occasionally takes longer.

## Graphics concept

The artificial horizon should use a conventional visual language:

- blue sky region
- brown/dark ground region
- white horizon line
- bank-angle scale
- pitch ladder
- fixed aircraft reference symbol
- prominent invalid-attitude overlay when required

## Brightness control

Brightness should be adjustable with the rotary encoder. A future ambient-light sensor may be added, but manual control should remain available.

The firmware should support a wide dimming range because a display bright enough for sunlight may be painfully bright at dusk or night.

## Optical design

The enclosure should allow later addition of:

- anti-glare cover lens
- anti-reflective coating or film
- optical bonding evaluation

Any cover lens must be checked for reflections, polarisation interaction, colour shift and reduced viewing angle.

## Mechanical integration

Common 2.1-inch round 480×480 panels have an active diameter of roughly 53 mm. This leaves useful bezel space inside a nominal 3 1/8-inch instrument format.

The display should be retained without stressing the glass. The flex cable must have a controlled bend radius and protected route to the electronics.

## Failure display

A failed or stale attitude solution must not leave a believable frozen horizon. The renderer should replace or obscure the normal horizon with a clear message such as:

```text
ATTITUDE
 INVALID
```

The failure state should be visually unmistakable.
