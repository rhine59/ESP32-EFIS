# EFIS licence-service development harness

This is the first executable vertical slice of the adopted offline licensing architecture. It is **development/simulator only**.

It provides a short-lived challenge, HMAC proof of possession for the synthetic device credential, an active DEVELOPMENT entitlement for `EFIS-SIM-0001`, and a deterministic-CBOR licence payload signed with Ed25519. The signing key is generated at first start and retained only in the Docker volume. It is never committed to Git.

The public-key endpoint exists solely so the web simulator can bootstrap a test trust anchor. Production EFIS units must instead receive trusted public verification keys during controlled provisioning.

Run:

```sh
docker compose up -d --build
```

Host health endpoint: `http://127.0.0.1:8094/health`.

The development default device secret is intentionally non-production. Set `DEVICE_SECRET` consistently in this service and the simulator when testing. Production device credentials require a provisioning design and protected storage.

## First acceptance path

1. Start this service.
2. Put simulator maintenance Wi-Fi online.
3. Select LICENSE → GET / REFRESH.
4. Simulator requests a one-time challenge.
5. Simulator proves possession of its test device credential.
6. Service returns the signed licence.
7. Simulator verifies Ed25519 signature, schema, product and immutable Device ID before changing local licence state.
8. Reboot/reset behaviour is tested separately.

Negative tests must cover replayed/expired challenge, wrong device secret, wrong Device ID/product, malformed CBOR, unknown key ID and modified signature/payload.
