from contextlib import asynccontextmanager
import hashlib, os, secrets, smtplib, ssl
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from fastapi import FastAPI, HTTPException, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
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
CREATE TABLE IF NOT EXISTS audit_events(id BIGSERIAL PRIMARY KEY,event TEXT NOT NULL,subject TEXT,created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS email_verification_tokens(id BIGSERIAL PRIMARY KEY,user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,token_hash TEXT UNIQUE NOT NULL,expires_at TIMESTAMPTZ NOT NULL,used_at TIMESTAMPTZ,created_at TIMESTAMPTZ NOT NULL DEFAULT now());
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMPTZ;"""
def db(): return psycopg.connect(DATABASE_URL,row_factory=dict_row)

def send_verification_email(user_id:int,email:str):
    token=secrets.token_urlsafe(32)
    token_hash=hashlib.sha256(token.encode()).hexdigest()
    expires=datetime.now(timezone.utc)+timedelta(minutes=int(os.getenv("EMAIL_VERIFY_MINUTES","30")))
    with db() as c:
        token_row=c.execute("INSERT INTO email_verification_tokens(user_id,token_hash,expires_at) VALUES(%s,%s,%s) RETURNING id",(user_id,token_hash,expires)).fetchone()
        c.commit()
    base=os.environ["PUBLIC_BASE_URL"].rstrip("/")
    msg=EmailMessage()
    msg["Subject"]="Verify your Lollipop account"
    msg["From"]=os.environ["SMTP_FROM"]
    msg["To"]=email
    msg.set_content(f"Verify your Lollipop account by opening this link:\n\n{base}/verify-email?token={token}\n\nThis link expires in {os.getenv('EMAIL_VERIFY_MINUTES','30')} minutes and can be used once.")
    host=os.environ["SMTP_HOST"]; port=int(os.getenv("SMTP_PORT","465"))
    user=os.getenv("SMTP_USER",""); password=os.getenv("SMTP_PASSWORD","")
    if os.getenv("SMTP_SSL","1")=="1":
        with smtplib.SMTP_SSL(host,port,context=ssl.create_default_context()) as smtp:
            if user: smtp.login(user,password)
            smtp.send_message(msg)
    else:
        with smtplib.SMTP(host,port) as smtp:
            smtp.starttls(context=ssl.create_default_context())
            if user: smtp.login(user,password)
            smtp.send_message(msg)
    with db() as c:
        c.execute("UPDATE email_verification_tokens SET used_at=now() WHERE user_id=%s AND id<>%s AND used_at IS NULL",(user_id,token_row["id"]))
        c.commit()

def issue_verification(user_id:int,email:str):
    try:
        send_verification_email(user_id,email)
        return True
    except Exception:
        with db() as c:
            c.execute("DELETE FROM email_verification_tokens WHERE user_id=%s AND used_at IS NULL AND created_at > now() - interval '1 minute'",(user_id,))
            c.execute("INSERT INTO audit_events(event,subject) VALUES('verification_delivery_failed',%s)",(email,))
            c.commit()
        return False
@asynccontextmanager
async def lifespan(app):
    with db() as c: c.execute(SCHEMA); c.commit()
    yield
app=FastAPI(title="EFIS Account Service",version="0.2.0",lifespan=lifespan)
app.add_middleware(SessionMiddleware,secret_key=SESSION_SECRET,https_only=os.getenv("COOKIE_SECURE","1")=="1",same_site="lax")
app.mount("/static",StaticFiles(directory="app/static"),name="static")
class Register(BaseModel): email:EmailStr; password:str
class DeviceRegister(BaseModel): user_id:int; device_id:str; mac:str|None=None
class PaymentEvent(BaseModel): provider:str; provider_reference:str; device_id:str; product:str; paid:bool
def current_user(r):
    uid=r.session.get("uid")
    if not uid:return None
    with db() as c:return c.execute("SELECT id,email,created_at,email_verified_at FROM users WHERE id=%s AND email_verified_at IS NOT NULL",(uid,)).fetchone()
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
    if not u["email_verified_at"]: return templates.TemplateResponse(request,"login.html",{"error":"Verify your email address before signing in."},status_code=403)
    request.session.clear();request.session["uid"]=u["id"];return RedirectResponse("/dashboard",303)
@app.get("/register",response_class=HTMLResponse)
def register_page(request:Request):return templates.TemplateResponse(request,"register.html",{"error":None})
@app.post("/register")
def register_web(request:Request,email:str=Form(...),password:str=Form(...)):
    if len(password)<12:return templates.TemplateResponse(request,"register.html",{"error":"Use at least 12 characters."},status_code=400)
    try:
        with db() as c:u=c.execute("INSERT INTO users(email,password_hash) VALUES(%s,%s) RETURNING id",(email.lower().strip(),password_hash.hash(password))).fetchone();c.commit()
    except psycopg.errors.UniqueViolation:
        with db() as c:u=c.execute("SELECT id,email,email_verified_at FROM users WHERE email=%s",(email.lower().strip(),)).fetchone()
        if u and not u["email_verified_at"]: issue_verification(u["id"],u["email"])
        return templates.TemplateResponse(request,"verify_pending.html",{"email":email.lower().strip()},status_code=202)
    issue_verification(u["id"],email.lower().strip())
    return templates.TemplateResponse(request,"verify_pending.html",{"email":email.lower().strip()},status_code=202)
@app.get("/verify-email",response_class=HTMLResponse)
def verify_email(request:Request,token:str):
    token_hash=hashlib.sha256(token.encode()).hexdigest()
    with db() as c:
        row=c.execute("""SELECT t.id,t.user_id FROM email_verification_tokens t JOIN users u ON u.id=t.user_id WHERE t.token_hash=%s AND t.used_at IS NULL AND t.expires_at>now() AND u.email_verified_at IS NULL FOR UPDATE""",(token_hash,)).fetchone()
        if not row:return templates.TemplateResponse(request,"verify_result.html",{"success":False},status_code=400)
        c.execute("UPDATE email_verification_tokens SET used_at=now() WHERE id=%s",(row["id"],))
        c.execute("UPDATE users SET email_verified_at=now() WHERE id=%s",(row["user_id"],))
        c.execute("UPDATE email_verification_tokens SET used_at=now() WHERE user_id=%s AND used_at IS NULL",(row["user_id"],))
        c.execute("INSERT INTO audit_events(event,subject) VALUES('email_verified',%s)",(str(row["user_id"]),))
        c.commit()
    return templates.TemplateResponse(request,"verify_result.html",{"success":True})

@app.post("/resend-verification",response_class=HTMLResponse)
def resend_verification(request:Request,email:str=Form(...)):
    normalized=email.lower().strip()
    with db() as c:u=c.execute("SELECT id,email,email_verified_at FROM users WHERE email=%s",(normalized,)).fetchone()
    if u and not u["email_verified_at"]: issue_verification(u["id"],u["email"])
    return templates.TemplateResponse(request,"verify_pending.html",{"email":normalized},status_code=202)

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
        issue_verification(row["id"],row["email"])
        return {"status":"verification_required"}
    except psycopg.errors.UniqueViolation:
        with db() as c:row=c.execute("SELECT id,email,email_verified_at FROM users WHERE email=%s",(x.email.lower(),)).fetchone()
        if row and not row["email_verified_at"]: issue_verification(row["id"],row["email"])
        return {"status":"verification_required"}
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