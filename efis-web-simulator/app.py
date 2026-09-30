import json, os, urllib.request, urllib.error
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

ROOT=Path(__file__).parent
DEVICE=os.getenv("DEVICE_ID","EFIS-SIM-0001")
OTA=os.getenv("OTA_BASE_URL","").rstrip("/")
LIC=os.getenv("LICENSE_BASE_URL","").rstrip("/")
ALLOW=os.getenv("SIM_ALLOW_MUTATIONS","false").lower()=="true"
state={"device_id":DEVICE,"network":"offline","firmware":"0.0.0-sim","staged":None,
       "license":{"status":"NOT INSTALLED","class":None},"faults":[]}

def get_json(url):
    with urllib.request.urlopen(url,timeout=5) as r: return json.loads(r.read())

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
            if not OTA: return self.sendj({"mock":True,"version":"1.0.0-test","url":"mock://firmware.bin","sha256":"SIMULATED"})
            try: return self.sendj(get_json(OTA+"/efis/manifest.json"))
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
            state.update(network="offline",firmware="0.0.0-sim",staged=None,faults=[])
            state["license"]={"status":"NOT INSTALLED","class":None}; return self.sendj(state)
        if self.path=="/api/firmware/stage":
            state["staged"]=body.get("version","1.0.0-test"); return self.sendj(state)
        if self.path=="/api/firmware/activate":
            if state["staged"]: state["firmware"],state["staged"]=state["staged"],None
            return self.sendj(state)
        if self.path=="/api/license/mock-install":
            state["license"]={"status":"VALID","class":body.get("class","DEVELOPMENT")}; return self.sendj(state)
        if self.path=="/api/license/mock-reset":
            state["license"]={"status":"NOT INSTALLED","class":None}; return self.sendj(state)
        return self.sendj({"error":"not found"},404)

ThreadingHTTPServer(("0.0.0.0",8080),H).serve_forever()
