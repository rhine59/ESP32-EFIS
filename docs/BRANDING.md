# Thingy product branding

**Status:** WORKING BRAND / NOT LEGALLY CLEARED  
**Adopted for development:** 2 October 2026

## Product family

The project will use the following customer-facing product identity during development:

- **Master brand:** **Thingy**
- **EFIS / flight-display product:** **RedOne**
- **Engine-interface product:** **BlueOne**
- **Full product references:** **Thingy RedOne** and **Thingy BlueOne**
- **Technical roles:** RedOne is the EFIS; BlueOne is the engine interface currently described technically in the architecture as the EIU/ECI.

A simple instrument presentation may use:

```text
Thingy
RedOne
Flight Display
```

The companion engine-interface enclosure, commissioning UI and support material should use:

```text
Thingy
BlueOne
Engine Interface
```

## Naming rule

**Thingy** is the umbrella brand. **RedOne** and **BlueOne** are product names, not replacements for every engineering acronym.

Customer-facing documentation, boot/splash screens, support material, diagrams and future packaging should say **Thingy RedOne** and **Thingy BlueOne**. Technical prose may retain **EFIS** and **EIU/ECI** where those terms describe a system role, protocol endpoint or established implementation identifier.

This distinction is intentional: branding can evolve without silently changing wire protocols, firmware package identities, source-code symbols, device IDs or deployed service names.

## Technical identity stability

The branding decision does **not** by itself rename:

- repository `ESP32-EFIS`;
- firmware project/internal identifiers such as `esp32_efis`;
- existing `EFIS-...` Device IDs;
- AEF-CAN protocol identifiers or message names;
- Docker service names, URLs, signing identities or OTA product identifiers;
- persisted configuration keys or compatibility metadata.

Those require explicit migration decisions if they are ever changed.

## Documentation usage

From this checkpoint:

- use **Thingy RedOne** when referring to the customer product that provides the EFIS/flight-display functions;
- use **Thingy BlueOne** when referring to the customer engine-interface product;
- use **RedOne** and **BlueOne** as the short product names once context is clear;
- retain **EFIS**, **EIU/ECI**, AEF-CAN and other engineering terms when describing architecture;
- do not introduce the superseded working names **MicroSky Avionics**, **MicroSky Horizon** or **Horizon** as the product name in new material.

Where older documentation uses “Horizon” to mean the **artificial-horizon/PFD page**, that instrument-page meaning is not a product-brand reference and may remain.

## Legal and commercial status

These remain working names until appropriate trademark, company/trading-name, domain and product-collision checks are completed. Do not use ™ or ® claims until the corresponding legal position is established.

## Before commercial freeze

Complete and document trademark/name/domain checks, final wordmark/logo and colour rules, enclosure marking rules, product-label/serial-number format, and the relationship between the Thingy trading brand and the legal manufacturer identity.
