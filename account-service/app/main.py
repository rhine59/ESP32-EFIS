from contextlib import asynccontextmanager
import hashlib, os, secrets
from fastapi import FastAPI, HTTPException, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware
from pydantic import BaseModel, EmailStr
from pwdlib import PasswordHash
import psycopg
from psycopg.rows import dict_row
DATABASE_URL=os.environ["DATABASE_URL"]; SESSION_SECRET=os.environ["SESSION_SECRET"]
password_hash=PasswordHash.recommended(); templates=Jinja2Templates(directory="app/templates")
SCHEMA="""CREATE TABLE IF NOT EXISTS users(id BIGSERIAL PRIMARY KEY,email TEXT UNIQUE NOT NULL,password_hash TEXT NOT NULL,created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS devices(id BIGSERIAL PRIMARY KEY,user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,device_id TEXT UNIQUE NOT NULL,mac_fingerprint TEXT,registration_hash TEXT,created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS entitlements(id BIGSERIAL PRIMARY KEY,device_id BIGINT REFERENCES devices(id) ON DELETE CASCADE,product TEXT NOT NULL,status TEXT NOT NULL DEFAULT 'active',provider TEXT,provider_reference TEXT,updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS audit_events(id BIGSERIAL PRIMARY KEY,event TEXT NOT NULL,subject TEXT,created_at TIMESTAMPTZ NOT NULL DEFAULT now());"""
def db(): return psycopg.connect(DATABASE_URL,row_factory=dict_row)
@asynccontextmanager
async def lifespan(app):
    with db() as c: c.execute(SCHEMA); c.commit()
    yield
app=FastAPI(title="EFIS Account Service",version="0.2.0",lifespan=lifespan)
app.add_middleware(SessionMiddleware,secret_key=SESSION_SECRET,https_only=os.getenv("COOKIE_SECURE","1")=="1",same_site="lax")
class Register(BaseModel): email:EmailStr; password:str
class DeviceRegister(BaseModel): user_id:int; device_id:str; mac:str|None=None
class PaymentEvent(BaseModel): provider:str; provider_reference:str; device_id:str; product:str; paid:bool
def current_user(r):
    uid=r.session.get("uid")
    if not uid:return None
    with db() as c:return c.execute("SELECT id,email,created_at FROM users WHERE id=%s",(uid,)).fetchone()
@app.get("/healthz")
def health():
    with db() as c:c.execute("SELECT 1")
    return {"status":"ok"}
@app.get("/",response_class=HTMLResponse)
def home(request:Request):return templates.TemplateResponse(request,"home.html",{"user":current_user(request)})
@app.get("/login",response_class=HTMLResponse)
def login_page(request:Request):return templates.TemplateResponse(request,"login.html",{"error":None})
@app.post("/login")
def login(request:Request,email:str=Form(...),password:str=Form(...)):
    with db() as c:u=c.execute("SELECT * FROM users WHERE email=%s",(email.lower().strip(),)).fetchone()
    if not u or not password_hash.verify(password,u["password_hash"]):return templates.TemplateResponse(request,"login.html",{"error":"Invalid email or password"},status_code=400)
    request.session.clear();request.session["uid"]=u["id"];return RedirectResponse("/dashboard",303)
@app.get("/register",response_class=HTMLResponse)
def register_page(request:Request):return templates.TemplateResponse(request,"register.html",{"error":None})
@app.post("/register")
def register_web(request:Request,email:str=Form(...),password:str=Form(...)):
    if len(password)<12:return templates.TemplateResponse(request,"register.html",{"error":"Use at least 12 characters."},status_code=400)
    try:
        with db() as c:u=c.execute("INSERT INTO users(email,password_hash) VALUES(%s,%s) RETURNING id",(email.lower().strip(),password_hash.hash(password))).fetchone();c.commit()
    except psycopg.errors.UniqueViolation:return templates.TemplateResponse(request,"register.html",{"error":"Account already exists."},status_code=409)
    request.session.clear();request.session["uid"]=u["id"];return RedirectResponse("/dashboard",303)
@app.post("/logout")
def logout(request:Request):request.session.clear();return RedirectResponse("/",303)
@app.get("/dashboard",response_class=HTMLResponse)
def dashboard(request:Request):
    u=current_user(request)
    if not u:return RedirectResponse("/login",303)
    with db() as c:devices=c.execute("""SELECT d.id,d.device_id,d.mac_fingerprint,d.created_at,COALESCE(json_agg(json_build_object('product',e.product,'status',e.status,'provider',e.provider)) FILTER(WHERE e.id IS NOT NULL),'[]') entitlements FROM devices d LEFT JOIN entitlements e ON e.device_id=d.id WHERE d.user_id=%s GROUP BY d.id ORDER BY d.created_at DESC""",(u["id"],)).fetchall()
    return templates.TemplateResponse(request,"dashboard.html",{"user":u,"devices":devices})
@app.post("/portal/devices")
def portal_add_device(request:Request,device_id:str=Form(...),mac:str=Form("")):
    u=current_user(request)
    if not u:return RedirectResponse("/login",303)
    try:
        with db() as c:c.execute("INSERT INTO devices(user_id,device_id,mac_fingerprint) VALUES(%s,%s,%s)",(u["id"],device_id.strip().upper(),mac.strip() or None));c.commit()
    except psycopg.errors.UniqueViolation:pass
    return RedirectResponse("/dashboard",303)
@app.post("/v1/users",status_code=201)
def register(x:Register):
    if len(x.password)<12:raise HTTPException(400,"password must be at least 12 characters")
    try:
        with db() as c:row=c.execute("INSERT INTO users(email,password_hash) VALUES(%s,%s) RETURNING id,email,created_at",(x.email.lower(),password_hash.hash(x.password))).fetchone();c.commit()
        return row
    except psycopg.errors.UniqueViolation:raise HTTPException(409,"account already exists")
@app.post("/v1/devices",status_code=201)
def add_device(x:DeviceRegister):
    code=secrets.token_urlsafe(9);rh=hashlib.sha256(code.encode()).hexdigest()
    try:
        with db() as c:row=c.execute("INSERT INTO devices(user_id,device_id,mac_fingerprint,registration_hash) VALUES(%s,%s,%s,%s) RETURNING id,user_id,device_id,created_at",(x.user_id,x.device_id,x.mac,rh)).fetchone();c.commit()
        return {**row,"registration_code":code}
    except psycopg.errors.UniqueViolation:raise HTTPException(409,"device already registered")
@app.get("/v1/devices/{device_id}/entitlements")
def entitlements(device_id:str):
    with db() as c:rows=c.execute("SELECT e.product,e.status,e.provider,e.updated_at FROM entitlements e JOIN devices d ON d.id=e.device_id WHERE d.device_id=%s",(device_id,)).fetchall()
    return {"device_id":device_id,"entitlements":rows}
@app.post("/internal/payment-event")
def payment_event(x:PaymentEvent):
    if not x.paid:return {"accepted":True,"entitlement_changed":False}
    with db() as c:
        d=c.execute("SELECT id FROM devices WHERE device_id=%s",(x.device_id,)).fetchone()
        if not d:raise HTTPException(404,"device not found")
        c.execute("INSERT INTO entitlements(device_id,product,status,provider,provider_reference) VALUES(%s,%s,'active',%s,%s)",(d["id"],x.product,x.provider,x.provider_reference));c.execute("INSERT INTO audit_events(event,subject) VALUES('payment_entitlement',%s)",(x.device_id,));c.commit()
    return {"accepted":True,"entitlement_changed":True}