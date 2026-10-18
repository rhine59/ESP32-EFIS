import hashlib
import http.client
import json
import threading
import unittest
from http.server import ThreadingHTTPServer
from server import Handler, KNOWN
from pathlib import Path

class SimulatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
    def call(self, method, path, body=b'', headers=None):
        conn = http.client.HTTPConnection('127.0.0.1', self.server.server_port)
        conn.request(method, path, body=body, headers=headers or {})
        resp = conn.getresponse()
        payload = resp.read()
        conn.close()
        return resp.status, json.loads(payload) if resp.getheader('Content-Type') == 'application/json' else payload
    def test_transfer_verify_activate_rollback(self):
        self.call('POST', '/api/reset')
        data = (Path(__file__).parent/'fixtures/redone-0.1.1-sim-B.bin').read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), KNOWN['B'][1])
        self.assertEqual(self.call('POST', '/api/transfer/chunk', data[:2048], {'X-Offset':'0'})[0], 200)
        self.assertEqual(self.call('POST', '/api/transfer/chunk', data[2048:], {'X-Offset':'2048'})[0], 200)
        self.assertEqual(self.call('POST', '/api/verify')[0], 200)
        self.assertEqual(self.call('POST', '/api/activate')[1]['active_partition'], 'B')
        self.assertEqual(self.call('POST', '/api/rollback')[1]['active_partition'], 'A')
    def test_corrupt_rejected(self):
        self.call('POST', '/api/reset')
        self.call('POST', '/api/transfer/chunk', b'x'*4096, {'X-Offset':'0'})
        self.assertEqual(self.call('POST', '/api/verify')[0], 422)
        self.assertEqual(self.call('POST', '/api/activate')[0], 409)
    def test_bad_offset(self):
        self.call('POST', '/api/reset')
        self.assertEqual(self.call('POST', '/api/transfer/chunk', b'x', {'X-Offset':'4'})[0], 409)

if __name__ == '__main__': unittest.main()
