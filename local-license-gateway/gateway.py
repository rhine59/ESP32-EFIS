import http.client, http.server, json, ssl, socket
from zeroconf import IPVersion, ServiceInfo, Zeroconf

UPSTREAM_HOST='127.0.0.1'; UPSTREAM_PORT=8093
ALLOWED_PREFIX='/api/phone/'

class Handler(http.server.BaseHTTPRequestHandler):
    def _proxy(self):
        if not self.path.startswith(ALLOWED_PREFIX):
            self.send_error(404); return
        length=int(self.headers.get('Content-Length','0'))
        body=self.rfile.read(length) if length else None
        conn=http.client.HTTPConnection(UPSTREAM_HOST,UPSTREAM_PORT,timeout=15)
        headers={'Content-Type':self.headers.get('Content-Type','application/json'),
                 'X-RedOne-Local-Gateway':'1'}
        conn.request(self.command,self.path,body=body,headers=headers)
        response=conn.getresponse(); data=response.read()
        self.send_response(response.status)
        self.send_header('Content-Type',response.getheader('Content-Type','application/json'))
        self.send_header('Cache-Control','no-store')
        self.send_header('Content-Length',str(len(data)))
        self.end_headers(); self.wfile.write(data)
    def do_GET(self):
        if self.path=='/healthz':
            data=json.dumps({'status':'ok','service':'redone-local-gateway'}).encode()
            self.send_response(200); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data); return
        self._proxy()
    def do_POST(self): self._proxy()
    def log_message(self,*args): pass

probe=socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    probe.connect(('192.0.2.1', 9))
    lan_address=probe.getsockname()[0]
finally:
    probe.close()
addresses=[socket.inet_aton(lan_address)]
info=ServiceInfo('_redone-license._tcp.local.', 'RedOne Licence._redone-license._tcp.local.', addresses=addresses, port=9443, properties={'version':'1','tls-name':'redone-license.local'}, server='redone-license.local.')
zeroconf=Zeroconf(ip_version=IPVersion.V4Only)
zeroconf.register_service(info)
server=http.server.ThreadingHTTPServer(('0.0.0.0',9443),Handler)
ctx=ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); ctx.minimum_version=ssl.TLSVersion.TLSv1_2
ctx.load_cert_chain('/run/redone-tls/tls.crt','/run/redone-tls/tls.key')
server.socket=ctx.wrap_socket(server.socket,server_side=True)
try:
    server.serve_forever()
finally:
    zeroconf.unregister_service(info); zeroconf.close()
