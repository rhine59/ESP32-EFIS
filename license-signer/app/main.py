from __future__ import annotations
import base64, os, uuid
from datetime import datetime, timezone
from pathlib import Path
import cbor2
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="EFIS Licence Signer", version="0.1.0")
MAX_PAYLOAD = 4096
TOKEN = os.environ.get("SIGNER_API_TOKEN", "")
KID = os.environ.get("SIGNER_KEY_ID", "lic-2026-01")
KEYFILE = os.environ.get("SIGNER_PRIVATE_KEY_FILE", "/run/secrets/efis_license_ed25519.pem")

class SignRequest(BaseModel):
    product_id: str = Field(min_length=1, max_length=64)
    device_id: str = Field(pattern=r"^EFIS-[A-Z0-9-]{4,32}$")
    licence_class: str = Field(min_length=1, max_length=64)
    features: list[str] = Field(default_factory=list, max_length=64)
    entitlement_id: str = Field(min_length=1, max_length=128)
    expires_at: int | None = None
    transfer_grace_until: int | None = None

def require_auth(value: str | None) -> None:
    if not TOKEN or value != "Bearer " + TOKEN:
        raise HTTPException(401, "unauthorized")

def load_key() -> Ed25519PrivateKey:
    try:
        raw = Path(KEYFILE).read_bytes()
        key = serialization.load_pem_private_key(raw, password=None)
        if not isinstance(key, Ed25519PrivateKey):
            raise ValueError("not Ed25519")
        return key
    except Exception as exc:
        raise HTTPException(503, "signing key unavailable") from exc

def b64u(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

@app.get("/healthz")
def health():
    return {"status":"ok","service":"efis-license-signer","key_id":KID,
            "key_file_present":Path(KEYFILE).is_file()}

@app.post("/internal/v1/sign")
def sign(req: SignRequest, authorization: str | None = Header(default=None)):
    require_auth(authorization)
    now = int(datetime.now(timezone.utc).timestamp())
    payload = {1:1, 2:req.product_id, 3:req.device_id, 4:str(uuid.uuid4()),
               5:req.entitlement_id, 6:now, 7:req.licence_class,
               8:sorted(set(req.features))}
    if req.expires_at is not None:
        payload[10] = req.expires_at
    if req.transfer_grace_until is not None:
        payload[11] = {"until": req.transfer_grace_until}
    payload_bytes = cbor2.dumps(payload, canonical=True)
    if len(payload_bytes) > MAX_PAYLOAD:
        raise HTTPException(413, "licence payload too large")
    signature = load_key().sign(payload_bytes)
    envelope = {"v":1,"alg":"Ed25519","kid":KID,
                "payload":payload_bytes,"sig":signature}
    encoded = cbor2.dumps(envelope, canonical=True)
    return {"format":"EFIS-LIC-CBOR-1","licence":b64u(encoded),
            "licence_id":payload[4],"key_id":KID}
