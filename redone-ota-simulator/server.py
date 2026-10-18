"""Simulation-only RedOne OTA endpoint. Never accepts real ESP images."""
import hashlib
import json
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

FIXTURES = Path(__file__).resolve().parent / 'fixtures'
KNOWN = {
    'A': ('0.1.0-sim-A', 'aa0621fe57d4b5d6831c963c0e5c52b693493e9d7e6585797826bc80c6a4c06d'),
    'B': ('0.1.1-sim-B', 'f9acbce913f72c1c235a1fb11e7eb766737bb4a12765132153df2646aaee97df'),
}
lock = threading.Lock()
state = {'active': 'A', 'previous': None, 'staged': None, 'buffer': bytearray(), 'verified': False}


def snapshot():
    return {'simulator': True, 'hardware': False, 'active_partition': state['active'],
            'active_version': KNOWN[state['active']][0], 'staged_partition': state['staged'],
            'received_bytes': len(state['buffer']), 'expected_bytes': 4096,
            'verified': state['verified'], 'rollback_available': state['previous'] is not None}


class Handler(BaseHTTPRequestHandler):
    def send_json(self, code, value):
        body = json.dumps(value).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == '/health':
            return self.send_json(200, {'ok': True, 'simulator': True})
        if self.path == '/api/status':
            with lock:
                return self.send_json(200, snapshot())
        if self.path == '/api/fixtures':
            return self.send_json(200, {k: {'version': v[0], 'sha256': v[1], 'bytes': 4096} for k, v in KNOWN.items()})
        if self.path == '/api/fixtures/B/download':
            data = (FIXTURES / 'redone-0.1.1-sim-B.bin').read_bytes()
            self.send_response(200)
            self.send_header('Content-Type', 'application/octet-stream')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            return self.wfile.write(data)
        self.send_json(404, {'error': 'not found'})

    def do_POST(self):
        try:
            size = int(self.headers.get('Content-Length', '0'))
            if size > 4096 or size < 0:
                return self.send_json(413, {'error': 'payload too large'})
            payload = self.rfile.read(size)
            with lock:
                if self.path == '/api/transfer/reset':
                    state.update(buffer=bytearray(), staged=None, verified=False)
                elif self.path == '/api/transfer/chunk':
                    offset = int(self.headers.get('X-Offset', '-1'))
                    if offset != len(state['buffer']):
                        return self.send_json(409, {'error': 'offset mismatch', 'received_bytes': len(state['buffer'])})
                    state['buffer'].extend(payload)
                    state.update(staged=None, verified=False)
                elif self.path == '/api/verify':
                    buf = bytes(state['buffer'])
                    digest = hashlib.sha256(buf).hexdigest()
                    if len(buf) != 4096 or buf[:1] == b'\xe9' or digest != KNOWN['B'][1]:
                        state.update(staged=None, verified=False)
                        return self.send_json(422, {'error': 'simulator fixture verification failed', 'sha256': digest})
                    state.update(staged='B', verified=True)
                elif self.path == '/api/activate':
                    if not state['verified'] or state['staged'] != 'B':
                        return self.send_json(409, {'error': 'verified staged image required'})
                    state.update(previous=state['active'], active='B', staged=None, verified=False)
                elif self.path == '/api/rollback':
                    if state['previous'] is None:
                        return self.send_json(409, {'error': 'no rollback available'})
                    state.update(active=state['previous'], previous=None, staged=None, verified=False)
                elif self.path == '/api/reset':
                    state.update(active='A', previous=None, staged=None, buffer=bytearray(), verified=False)
                else:
                    return self.send_json(404, {'error': 'not found'})
                return self.send_json(200, snapshot())
        except (ValueError, KeyError) as exc:
            self.send_json(400, {'error': str(exc)})


if __name__ == '__main__':
    ThreadingHTTPServer(('0.0.0.0', int(os.environ.get('PORT', '8193'))), Handler).serve_forever()
