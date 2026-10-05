import base64, hashlib, hmac, json, os, secrets, time, uuid
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path
import cbor2
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization

DEVICE=os.getenv("DEVICE_ID","EFIS-SIM-0001")
SECRET=os.getenv("DEVICE_SECRET","").encode()
PRODUCT="ESP32-EFIS"; KID="sim-dev-1"; KEY=Path("/data/license-ed25519.key")
challenges={}

def b64(b): return base64.urlsafe_b64encode(b).rstrip(b"=").decode()
def unb64(s): return base64.urlsafe_b64decode(s+"="*((4-len(s)%4)%4))
def key():
    if KEY.exists(): return Ed25519PrivateKey.from_private_bytes(KEY.read_bytes())
    k=Ed25519PrivateKey.generate()
    KEY.write_bytes(k.private_bytes(serialization.Encoding.Raw,serialization.PrivateFormat.Raw,serialization.NoEncryption()))
    os.chmod(KEY,0o600); return k
SIGNING_KEY=key()
PUB=SIGNING_KEY.public_key().public_bytes(serialization.Encoding.Raw,serialization.PublicFormat.Raw)

def issue(device):
    payload={1:1,2:PRODUCT,3:device,4:str(uuid.uuid4()),5:int(time.time()),6:int(time.time()),7:"DEVELOPMENT",8:["BASE"],}
    raw=cbor2.dumps(payload,canonical=True)
    env={"v":1,"alg":"Ed25519","kid":KID,"payload":raw,"sig":SIGNING_KEY.sign(raw)}
    return b64(cbor2.dumps(env,canonical=True))

class H(BaseHTTPRequestHandler):
    def sendj(self,o,status=200):
        b=json.dumps(o).encode(); self.send_response(status); self.send_header("Content-Type","application/json"); self.send_header("Content-Length",str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        if self.path=="/health": return self.sendj({"ok":True})
        if self.path=="/v1/trust/"+KID: return self.sendj({"kid":KID,"alg":"Ed25519","public_key":b64(PUB),"simulation_only":True})
        return self.sendj({"error":"not found"},404)
    def do_POST(self):
        n=int(self.headers.get("Content-Length","0")); body=json.loads(self.rfile.read(n) or b"{}")
        if self.path=="/v1/device/challenge":
            d=body.get("device_id","")
            if d!=DEVICE: return self.sendj({"error":"unknown device"},404)
            nonce=b64(secrets.token_bytes(24)); challenges[nonce]=time.time()+120
            return self.sendj({"device_id":d,"challenge":nonce,"expires_in":120})
        if self.path=="/v1/device/license":
            d=body.get("device_id",""); nonce=body.get("challenge",""); proof=body.get("proof","")
            expiry=challenges.pop(nonce,None)
            if d!=DEVICE or not expiry or expiry<time.time(): return self.sendj({"error":"invalid or expired challenge"},401)
            want=hmac.new(SECRET,(d+"\n"+nonce).encode(),hashlib.sha256).hexdigest()
            if not SECRET or not hmac.compare_digest(want,proof): return self.sendj({"error":"device authentication failed"},401)
            return self.sendj({"device_id":d,"product":PRODUCT,"entitlement":"ACTIVE","license":issue(d)})
        if self.path=="/v1/test/wrong-device-license":
            return self.sendj({"simulation_only":True,"device_id":"EFIS-SIM-WRONG","license":issue("EFIS-SIM-WRONG")})
        return self.sendj({"error":"not found"},404)
    def log_message(self,*args): pass
ThreadingHTTPServer(("0.0.0.0",8080),H).serve_forever()
