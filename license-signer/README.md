# EFIS Licence Signer

Private internal signing service implementing the adopted Ed25519 + deterministic-CBOR licence design.

## Boundary
The service binds to loopback port 8092 by default and must not be exposed through the public reverse proxy/router. The private key is mounted at runtime and is never baked into the image or committed. The container runs non-root, read-only, drops capabilities and enables no-new-privileges.

The bearer token is initial service-to-service scaffolding. Production must additionally restrict network access and use hardened key custody.

For the complete Synology build, deployment, isolation, recovery and validation procedure see [`BUILD-AND-DEPLOY.md`](BUILD-AND-DEPLOY.md).

## Development bring-up
Copy .env.example to .env, replace CHANGE-ME with a strong random service token, then:

    cd license-signer
    ./scripts/generate-dev-key.sh
    docker compose build
    docker compose up -d
    curl http://127.0.0.1:8092/healthz

Development keys are disposable and excluded from Git. Never use them as production signing keys.

POST /internal/v1/sign is for the authorized account-service backend only, after entitlement/ownership/payment checks.

Status: source implemented; Synology container build, test vectors, account-service integration, production key custody and ESP32 verification remain pending.
