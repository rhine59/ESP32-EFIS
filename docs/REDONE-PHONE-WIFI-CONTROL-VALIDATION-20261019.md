# RedOne iPhone Wi-Fi management validation — 19 October 2026

**Objective:** demonstrate live control-plane connectivity between the Lollipop iPhone app and the existing Mac-connected RedOne ESP32-S3. **Current decision: NOT YET VALIDATED.** Source presence is not evidence that the installed firmware supports a route.

## Source audit (passed)

Run `python3 hardware/boot-recovery-lab/tools/phone_wifi_control_audit.py` and `python3 -m unittest discover -s hardware/boot-recovery-lab/tests -p test_phone_wifi_control_audit.py`. The iPhone implements `NEHotspotConfiguration` joining, saved QR pairing, authenticated `/status`, and `/boot-health` reads. The newer firmware source declares `/status`, `/boot-health`, `/firmware/verify-manifest`, `/firmware/hash`, `/firmware/preflight`, plus locked `/update`, `/verify` and `/activate` routes. This is **source-only** inventory, not a live-board result.

## Live acceptance sequence on existing RedOne and iPhone

1. Confirm phone is running the latest Lollipop build; use Connection to scan saved pairing QR or rejoin `RedOne_<MAC>`. Record the iOS Wi-Fi SSID and app's confirmation. Do not publish/flash firmware merely to enable diagnostics.
2. Tap **Read EFIS status**. Expect authenticated device `RedOne`, version, `running=ota_0`, `next=ota_1`, and explicit rollback/update readiness. Repeat three times and record results. Any authentication prompt or timeout is a test failure to investigate, not proof of management.
3. Tap **Read diagnostics from EFIS** (boot-health). An HTTP 404 on the installed firmware is an **unsupported capability**, not a pass. Newer firmware source includes it but is not installed.
4. Disconnect/rejoin Wi-Fi from the phone and recheck authenticated status, ensuring the saved Keychain pairing is reused. Check incorrect or missing pairing credentials produce an explicit rejection; do not disclose tokens.
5. Keep firmware download on the phone separate from device transfer. Check cached signed image and phone preflight offline. Do not invoke physical `/update`, `/activate`, `/verify`, eFuse or boot-selection operations.
6. To validate authenticated non-mutating commands beyond GET, first confirm which installed routes exist and that their implementation is truly read-only. The source's signed-manifest/hash/preflight POST routes are **not proven installed** on the board. Do not send bulk firmware data merely to test the link.

## Pass criteria and known limitations

- **Connectivity PASS** requires observed phone join, authentication, three successful live `/status` reads and a successful rejoin/re-read; source tests alone are insufficient.
- **Diagnostics PASS** requires live boot-health evidence, not an HTTP 404 or simulator response.
- **Management PASS** requires independently verified authenticated, non-mutating command acknowledgements on the installed board; **not currently demonstrated**.
- **Firmware control/rollback** stays **LOCKED / NO-GO** pending separate security, recovery and physical authorization gates.

The current USB heartbeat confirms the existing ESP32 is running, but it cannot establish the phone's Wi-Fi path. No physical board changes were made by this audit.
