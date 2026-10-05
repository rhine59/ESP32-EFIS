import base64, hashlib, hmac, json, os, tempfile, urllib.request, urllib.error
import cbor2
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import urljoin

ROOT=Path(__file__).parent
DEVICE=os.getenv("DEVICE_ID","EFIS-SIM-0001")
OTA=os.getenv("OTA_BASE_URL","").rstrip("/")
LIC=os.getenv("LICENSE_BASE_URL","").rstrip("/")
ALLOW=os.getenv("SIM_ALLOW_MUTATIONS","false").lower()=="true"
DEVICE_SECRET=os.getenv("DEVICE_SECRET","simulator-development-secret-change-me").encode()
LICENCE_STORE=Path(os.getenv("LICENSE_STORE","/data/licence.cbor.b64"))
state={"device_id":DEVICE,"network":"offline","firmware":"2.4.0","staged":None,
       "eiu":{"firmware":"1.7.0","protocol":"1.2","capabilities":["ENGINE_DATA_V1","OTA_V1"]},
       "offline_cache":{"release":None,"ready":False,"sha256":None,"bytes":0},
       "release_order":[],"license":{"status":"NOT INSTALLED","class":None},"faults":[]}

def get_json(url):
    with urllib.request.urlopen(url,timeout=8) as r: return json.loads(r.read())

def post_json(url, obj):
    data=json.dumps(obj).encode()
    req=urllib.request.Request(url,data=data,headers={"Content-Type":"application/json"},method="POST")
    with urllib.request.urlopen(req,timeout=8) as r: return json.loads(r.read())

def b64u(s):
    return base64.urlsafe_b64decode(s + "="*((4-len(s)%4)%4))

def verify_license_blob(encoded, allow_network_trust=False):
    env=cbor2.loads(b64u(encoded))
    if env.get("v")!=1 or env.get("alg")!="Ed25519": raise RuntimeError("unsupported licence envelope")
    trust_path=LICENCE_STORE.parent/("trust-"+env["kid"]+".pub")
    if allow_network_trust:
        trust=get_json(LIC+"/v1/trust/"+env["kid"])
        if not trust.get("simulation_only"): raise RuntimeError("refusing non-simulator trust bootstrap")
        pub=b64u(trust["public_key"])
        trust_path.parent.mkdir(parents=True,exist_ok=True)
        tmp=trust_path.with_suffix(".tmp"); tmp.write_bytes(pub); os.replace(tmp,trust_path)
    elif trust_path.exists():
        pub=trust_path.read_bytes()
    else:
        raise RuntimeError("trusted licence verification key not provisioned")
    Ed25519PublicKey.from_public_bytes(pub).verify(env["sig"],env["payload"])
    payload=cbor2.loads(env["payload"])
    if payload.get(1)!=1: raise RuntimeError("unsupported licence schema")
    if payload.get(2)!="ESP32-EFIS": raise RuntimeError("wrong product in licence")
    if payload.get(3)!=DEVICE: raise RuntimeError("licence Device ID mismatch")
    return {"status":"VALID","class":payload.get(7),"license_id":payload.get(4),"kid":env["kid"]}

def persist_license(encoded):
    LICENCE_STORE.parent.mkdir(parents=True,exist_ok=True)
    tmp=LICENCE_STORE.with_suffix(".tmp")
    tmp.write_text(encoded)
    os.replace(tmp,LICENCE_STORE)

def load_installed_license():
    if not LICENCE_STORE.exists(): return
    try:
        state["license"]=verify_license_blob(LICENCE_STORE.read_text().strip(),False)
    except Exception as e:
        state["license"]={"status":"INVALID","class":None,"error":str(e)}

def acquire_signed_blob():
    ch=post_json(LIC+"/v1/device/challenge",{"device_id":DEVICE})
    nonce=ch["challenge"]
    proof=hmac.new(DEVICE_SECRET,(DEVICE+"\n"+nonce).encode(),hashlib.sha256).hexdigest()
    return post_json(LIC+"/v1/device/license",{"device_id":DEVICE,"challenge":nonce,"proof":proof})

def run_license_negative_test(kind):
    if not LICENCE_STORE.exists(): raise RuntimeError("install a valid signed licence first")
    encoded=LICENCE_STORE.read_text().strip()
    env=cbor2.loads(b64u(encoded))
    if kind=="tamper":
        raw=bytearray(env["payload"]); raw[-1]^=1; env["payload"]=bytes(raw)
    elif kind=="bad-signature":
        sig=bytearray(env["sig"]); sig[0]^=1; env["sig"]=bytes(sig)
    elif kind=="wrong-device":
        if state["network"]!="online": raise RuntimeError("wrong-device test requires simulator network online")
        test=post_json(LIC+"/v1/test/wrong-device-license",{})
        if not test.get("simulation_only"): raise RuntimeError("refusing non-simulator wrong-device fixture")
        candidate=test["license"]
    elif kind=="interrupted-replacement":
        if state["network"]!="online": raise RuntimeError("replacement test requires simulator network online")
        r=acquire_signed_blob(); candidate=r["license"]
        candidate_state=verify_license_blob(candidate,True)
        tmp=LICENCE_STORE.with_suffix(".tmp")
        tmp.write_text(candidate)
        return {"result":"INTERRUPTED","test":kind,"candidate":candidate_state["license_id"],
                "installed":state["license"]["license_id"],"temp_exists":tmp.exists()}
    else:
        raise RuntimeError("unknown negative test")
    if kind!="wrong-device":
        candidate=base64.urlsafe_b64encode(cbor2.dumps(env,canonical=True)).decode().rstrip("=")
    try:
        verify_license_blob(candidate,False)
    except Exception as e:
        return {"result":"REJECTED","test":kind,"reason":str(e),"installed":state["license"]["status"]}
    raise RuntimeError("SECURITY TEST FAILED: invalid licence was accepted")

def retrieve_and_verify_license():
    if state["network"]!="online": raise RuntimeError("maintenance Wi-Fi is offline")
    if not LIC: raise RuntimeError("licence service is not configured")
    r=acquire_signed_blob()
    candidate=verify_license_blob(r["license"],True)
    persist_license(r["license"])
    state["license"]=candidate
    return state["license"]

def manifest():
    if state["network"]!="online": raise RuntimeError("maintenance Wi-Fi is offline")
    if not OTA:
        return {"mock":True,"product":"ESP32-EFIS","version":"2.5.0","build":250,
                "image_url":"mock://esp32-efis-2.5.0.bin",
                "sha256":"SIMULATED","minimum_allowed_version":"0.0.0",
                "release_notes":"Simulator mock release"}
    m=get_json(OTA+"/efis/manifest.json")
    required=("product","version","image_url","sha256")
    missing=[k for k in required if not m.get(k)]
    if missing: raise RuntimeError("manifest missing "+", ".join(missing))
    if m["product"]!="ESP32-EFIS": raise RuntimeError("wrong product in manifest")
    if "CHANGE-ME" in str(m["image_url"]) or "REPLACE_" in str(m["sha256"]):
        raise RuntimeError("OTA manifest is still a placeholder; publish a real release first")
    if len(str(m["sha256"]))!=64: raise RuntimeError("manifest SHA-256 is not 64 hex characters")
    return m

def cache_image(m):
    if m.get("mock"):
        state["offline_cache"]={"release":m["version"],"ready":True,"sha256":"SIMULATED","bytes":0}
        return
    url=m["image_url"]
    if url.startswith("/"): url=urljoin(OTA+"/",url.lstrip("/"))
    h=hashlib.sha256(); total=0
    with urllib.request.urlopen(url,timeout=30) as r:
        while True:
            b=r.read(65536)
            if not b: break
            h.update(b); total+=len(b)
    got=h.hexdigest().lower(); want=str(m["sha256"]).lower()
    if got!=want: raise RuntimeError("SHA-256 mismatch: expected "+want+" got "+got)
    state["offline_cache"]={"release":m["version"],"ready":True,"sha256":got,"bytes":total}

class H(SimpleHTTPRequestHandler):
    def translate_path(self,path):
        p=path.split("?",1)[0]
        if p=="/": p="/index.html"
        return str(ROOT/"static"/p.lstrip("/"))
    def sendj(self,obj,status=200):
        b=json.dumps(obj).encode(); self.send_response(status); self.send_header("Content-Type","application/json")
        self.send_header("Content-Length",str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        if self.path=="/api/state": return self.sendj(state)
        if self.path=="/api/firmware/check":
            try: return self.sendj(manifest())
            except Exception as e: return self.sendj({"error":str(e)},502)
        if self.path=="/api/license/status":
            return self.sendj(state["license"])
        if self.path=="/api/license/test/storage":
            trust=list(LICENCE_STORE.parent.glob("trust-*.pub"))
            return self.sendj({"simulation_only":True,"licence_exists":LICENCE_STORE.exists(),
                               "temp_exists":LICENCE_STORE.with_suffix(".tmp").exists(),
                               "trust_key_count":len(trust)})
        return super().do_GET()
    def do_POST(self):
        n=int(self.headers.get("Content-Length","0")); body=json.loads(self.rfile.read(n) or b"{}")
        if self.path=="/api/sim/network":
            state["network"]=body.get("state","offline"); return self.sendj(state)
        if self.path=="/api/sim/reset":
            state.update(network="offline",firmware="2.4.0",staged=None,faults=[],release_order=[])
            state["offline_cache"]={"release":None,"ready":False,"sha256":None,"bytes":0}
            state["license"]={"status":"NOT INSTALLED","class":None}; return self.sendj(state)
        if self.path=="/api/firmware/cache":
            try:
                m=manifest(); cache_image(m); return self.sendj(state)
            except Exception as e:
                state["offline_cache"]={"release":None,"ready":False,"sha256":None,"bytes":0}
                return self.sendj({"error":str(e)},502)
        if self.path=="/api/firmware/stage":
            if not state["offline_cache"]["ready"]: return self.sendj({"error":"verified firmware image not cached"},409)
            state["staged"]=state["offline_cache"]["release"]; state["release_order"]=["horizon"]; return self.sendj(state)
        if self.path=="/api/firmware/activate":
            if state["staged"]: state["firmware"],state["staged"]=state["staged"],None
            return self.sendj(state)
        if self.path=="/api/license/test":
            try: return self.sendj(run_license_negative_test(body.get("test","")))
            except Exception as e: return self.sendj({"error":str(e)},409)
        if self.path=="/api/license/refresh":
            try: return self.sendj(retrieve_and_verify_license())
            except Exception as e: return self.sendj({"error":str(e)},502)
        if self.path=="/api/license/mock-install":
            state["license"]={"status":"VALID","class":body.get("class","DEVELOPMENT")}; return self.sendj(state)
        if self.path=="/api/license/mock-reset":
            if LICENCE_STORE.exists(): LICENCE_STORE.unlink()
            tmp=LICENCE_STORE.with_suffix(".tmp")
            if tmp.exists(): tmp.unlink()
            state["license"]={"status":"NOT INSTALLED","class":None}; return self.sendj(state)
        if self.path=="/api/license/test/corrupt-store":
            if not LICENCE_STORE.exists(): return self.sendj({"error":"no installed licence to corrupt"},409)
            LICENCE_STORE.write_text("CORRUPTED-LICENCE")
            return self.sendj({"simulation_only":True,"result":"CORRUPTED"})
        return self.sendj({"error":"not found"},404)

load_installed_license()
ThreadingHTTPServer(("0.0.0.0",8080),H).serve_forever()
