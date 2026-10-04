import hashlib, json, os, tempfile, urllib.request, urllib.error
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import urljoin

ROOT=Path(__file__).parent
DEVICE=os.getenv("DEVICE_ID","EFIS-SIM-0001")
OTA=os.getenv("OTA_BASE_URL","").rstrip("/")
LIC=os.getenv("LICENSE_BASE_URL","").rstrip("/")
ALLOW=os.getenv("SIM_ALLOW_MUTATIONS","false").lower()=="true"
state={"device_id":DEVICE,"network":"offline","firmware":"2.4.0","staged":None,
       "eiu":{"firmware":"1.7.0","protocol":"1.2","capabilities":["ENGINE_DATA_V1","OTA_V1"]},
       "offline_cache":{"release":None,"ready":False,"sha256":None,"bytes":0},
       "release_order":[],"license":{"status":"NOT INSTALLED","class":None},"faults":[]}

def get_json(url):
    with urllib.request.urlopen(url,timeout=8) as r: return json.loads(r.read())

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
            if not LIC: return self.sendj({"mock":True,**state["license"]})
            try: return self.sendj(get_json(LIC+"/v1/device/"+DEVICE+"/license"))
            except Exception as e: return self.sendj({"error":str(e)},502)
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
        if self.path=="/api/license/mock-install":
            state["license"]={"status":"VALID","class":body.get("class","DEVELOPMENT")}; return self.sendj(state)
        if self.path=="/api/license/mock-reset":
            state["license"]={"status":"NOT INSTALLED","class":None}; return self.sendj(state)
        return self.sendj({"error":"not found"},404)

ThreadingHTTPServer(("0.0.0.0",8080),H).serve_forever()
