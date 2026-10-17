# Experimental Recovery-button bootloader override

This is a **build-verified, unflashed bench prototype**, not a production bootloader. ESP-IDF v5.4.4 supports replacing the second-stage bootloader main component through `bootloader_components/main`. This lab override samples candidate GPIO44 eight times at 1 ms intervals and, if consistently low, requests the factory image instead of the normal OTA selection. It preserves the silicon GPIO0 ROM download mode. The factory slot must contain a valid recovery application; this lab currently does not provide one by default.

**Critical limitations:** GPIO44 is currently a spare debug test pad, not a wired recovery button, and may conflict with UART0 RX. Its input mux and pull-up state have **not been verified**; the current prototype samples the GPIO input register directly. It must not be flashed to RedOne or used in flight. It also does not implement boot-loop accounting, authenticated Lollipop-requested entry, or automatic recovery from every invalid OTA metadata state. The standard ESP-IDF fallback may attempt factory after invalid applications, but this must be tested with fault injection. This experimental override is isolated to `hardware/boot-recovery-lab` and does not alter the normal `firmware/recovery` build.

Before any bench flash: confirm the exact GPIO wiring and bootloader input-enable behaviour; connect a verified external pull-up and switch; flash valid recovery into factory; verify A/B boot selection and ROM USB recovery; then test with corrupted slots and repeated resets. Do not change eFuses or enable irreversible security settings during this stage.

Build (no flash): `source scripts/efis-env.sh && cd hardware/boot-recovery-lab && idf.py -B build-recovery-override build`.
