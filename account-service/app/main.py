from contextlib import asynccontextmanager
import hashlib, os, secrets
from datetime import datetime, timezone
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
from pwdlib import PasswordHash
import psycopg
from psycopg.rows import dict_row

DATABASE_URL=os.environ["DATABASE_URL"]
password_hash=PasswordHash.recommended()

SCHEMA="""
CREATE TABLE IF NOT EXISTS users (
 id BIGSERIAL PRIMARY KEY, email TEXT UNIQUE NOT NULL,
 password_hash TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS devices (
 id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
 device_id TEXT UNIQUE NOT NULL, mac_fingerprint TEXT,
 registration_hash TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS entitlements (
 id BIGSERIAL PRIMARY KEY, device_id BIGINT REFERENCES devices(id) ON DELETE CASCADE,
 product TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'active',
 provider TEXT, provider_reference TEXT, updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS audit_events (
 id BIGSERIAL PRIMARY KEY, event TEXT NOT NULL, subject TEXT,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
"""

def db():
    return psycopg.connect(DATABASE_URL,row_factory=dict_row)

@asynccontextmanager
async def lifespan(app: FastAPI):
    with db() as c:
        c.execute(SCHEMA)
        c.commit()
    yield

app=FastAPI(title="EFIS Account Service",version="0.1.0",lifespan=lifespan)

class Register(BaseModel):
    email: EmailStr
    password: str
class DeviceRegister(BaseModel):
    user_id: int
    device_id: str
    mac: str|None=None
class PaymentEvent(BaseModel):
    provider: str
    provider_reference: str
    device_id: str
    product: str
    paid: bool

@app.get("/healthz")
def health():
    with db() as c: c.execute("SELECT 1")
    return {"status":"ok"}

@app.post("/v1/users",status_code=201)
def register(x:Register):
    if len(x.password)<12: raise HTTPException(400,"password must be at least 12 characters")
    try:
        with db() as c:
            row=c.execute("INSERT INTO users(email,password_hash) VALUES(%s,%s) RETURNING id,email,created_at",
                          (x.email.lower(),password_hash.hash(x.password))).fetchone(); c.commit()
        return row
    except psycopg.errors.UniqueViolation:
        raise HTTPException(409,"account already exists")

@app.post("/v1/devices",status_code=201)
def add_device(x:DeviceRegister):
    code=secrets.token_urlsafe(9)
    rh=hashlib.sha256(code.encode()).hexdigest()
    try:
        with db() as c:
            row=c.execute("""INSERT INTO devices(user_id,device_id,mac_fingerprint,registration_hash)
             VALUES(%s,%s,%s,%s) RETURNING id,user_id,device_id,created_at""",
             (x.user_id,x.device_id,x.mac,rh)).fetchone(); c.commit()
        return {**row,"registration_code":code}
    except psycopg.errors.UniqueViolation:
        raise HTTPException(409,"device already registered")

@app.get("/v1/devices/{device_id}/entitlements")
def entitlements(device_id:str):
    with db() as c:
        rows=c.execute("""SELECT e.product,e.status,e.provider,e.updated_at FROM entitlements e
          JOIN devices d ON d.id=e.device_id WHERE d.device_id=%s""",(device_id,)).fetchall()
    return {"device_id":device_id,"entitlements":rows}

@app.post("/internal/payment-event")
def payment_event(x:PaymentEvent):
    # Prototype internal adapter endpoint. Production provider webhooks MUST verify
    # provider signatures before converting an event into this normalized form.
    if not x.paid: return {"accepted":True,"entitlement_changed":False}
    with db() as c:
        d=c.execute("SELECT id FROM devices WHERE device_id=%s",(x.device_id,)).fetchone()
        if not d: raise HTTPException(404,"device not found")
        c.execute("""INSERT INTO entitlements(device_id,product,status,provider,provider_reference)
          VALUES(%s,%s,'active',%s,%s)""",(d["id"],x.product,x.provider,x.provider_reference))
        c.execute("INSERT INTO audit_events(event,subject) VALUES('payment_entitlement',%s)",(x.device_id,))
        c.commit()
    return {"accepted":True,"entitlement_changed":True}
