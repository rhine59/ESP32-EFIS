# Display Design

## Selected reference panel

The project reference display is now the **Newhaven Display NHD-2.1-480480AF-ASXP**.

Key manufacturer specifications:

- 2.1-inch round IPS TFT
- 480 × 480 pixels
- **1000 cd/m² (1000 nit)** luminance
- ST7701S controller/driver
- transmissive, normally black
- full-view IPS
- no touch layer
- 18-bit parallel RGB or 1-lane MIPI DSI
- project interface: **18-bit parallel RGB**
- 40-pin, 0.5 mm-pitch FFC
- active area: **53.28 × 53.28 mm**
- outline: **58.18 × 60.71 × 2.26 mm**
- TFT supply around 3.0 V
- backlight around **6.0 V / 100 mA**
- operating temperature: -20 °C to +70 °C
- storage temperature: -30 °C to +80 °C
- EMI-shielded FPC
- anti-glare construction

## Why this display

The key requirement is cockpit readability. Common 2.1-inch round ST7701S panels are often 300–650 nit. The Newhaven part provides a documented 1000-nit backlight while retaining the same useful 480×480 round format.

The lack of a touch layer is deliberate. User input will come from a physical rotary encoder and push switch, reducing reflections and avoiding touch interaction in turbulence.

## Why 480×480

A 480×480 circular panel provides enough resolution for:

- smooth bank rotation
- crisp pitch ladder lines
- readable numeric pitch labels
- anti-aliased aircraft symbol
- warning annunciations
- future slip/skid or flight-director overlays

## ESP32-S3 interface

The selected panel supports both parallel RGB and MIPI DSI. The ESP32-S3 design will use the **18-bit parallel RGB interface**.

This consumes a substantial number of GPIOs because the interface includes:

- 18 RGB data bits
- pixel clock
- timing/control lines such as DE and/or HSYNC/VSYNC depending on the final timing configuration
- ST7701S initialisation/control signals
- reset
- backlight control

The exact ESP32-S3 board and GPIO map must therefore be frozen before wiring or a carrier PCB is finalised.

## FFC connection

The display uses a **40-pin 0.5 mm-pitch FFC**. Newhaven recommends a compatible connector such as **Molex 54104-4096**.

For bench testing it is preferable to use a proper FFC breakout/carrier rather than hand-wire the flexible tail.

## Backlight power

The instrument input remains **5 V USB-C**, but the selected high-brightness panel backlight requires approximately **6 V / 100 mA**.

A dedicated boost/constant-current LED driver is therefore required. Brightness control should be performed through that driver rather than by switching LED current directly with an ESP32 GPIO.

This driver must support:

- 5 V input
- suitable output compliance for the 6 V LED string
- at least the required 100 mA LED current
- PWM or analogue dimming
- a low enough minimum brightness for dusk/night use

The exact driver part is still TBD.

## Target frame rate

The display target is **30–60 fps**. Sensor acquisition and AHRS execution should run faster than the display so attitude estimation remains responsive even if rendering occasionally takes longer.

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

Brightness will be adjustable with the rotary encoder. A future ambient-light sensor may be added, but manual control should remain available.

The dimming range must be wide because a 1000-nit panel suitable for sunlight can be uncomfortably bright at dusk or at night.

## Mechanical integration

The enclosure CAD should use the actual Newhaven dimensions, not generic 2.1-inch assumptions:

- active area: 53.28 × 53.28 mm
- panel outline: 58.18 × 60.71 mm
- thickness: about 2.26 mm

The glass must be retained without point loading or bending. The FFC must have a controlled bend radius and a protected path to the carrier electronics.

## Failure display

A failed or stale attitude solution must not leave a believable frozen horizon. The renderer should replace or obscure the normal horizon with a clear message such as:

```text
ATTITUDE
 INVALID
```

The failure state should be visually unmistakable.
