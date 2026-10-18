# Staged Lollipop OTA mounts

OTA Compose accepts `OTA_PUBLIC_DIR` as a deployment-specific environment variable, defaulting to `./public` for development. On the NAS staging checkout, set `OTA_PUBLIC_DIR=/volume1/docker/ESP32-EFIS/ota-server/public` so the new OTA server and admin both use the **existing published firmware directory**. Preserve the existing private `OTA_SIGNING_KEY_FILE` setting from the production environment. Do not copy signing keys or `.env` into Git.

For safe deployment, configure secrets in a private external env file or a separately permission-restricted `.env` in the staging checkout; do not print rendered Compose environment values to logs. Confirm resolved bind source paths using an inspection that prints only mount source/destination, and validate that the public directory contains the expected signed releases before recreating containers. The original account DB and licence/simulator volumes are already external by exact name. The OTA shared network retains the existing name `ota-server_default`.

**No production container recreation is included in this source change.**
