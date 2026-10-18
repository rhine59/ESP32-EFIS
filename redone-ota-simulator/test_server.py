import hashlib
import http.client
import json
import os
import threading
import unittest
from http.server import ThreadingHTTPServer
from server import Handler, KNOWN
from pathlib import Path

class SimulatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        os.environ['REDONE_SIMULATOR_TOKEN'] = 'unit-test-token'
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
    def call(self, method, path, body=b'', headers=None):
        conn = http.client.HTTPConnection('127.0.0.1', self.server.server_port)
        conn.request(method, path, body=body, headers={'Authorization': 'Bearer unit-test-token', **(headers or {})})
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
    def test_authentication_required(self):
        self.call('POST', '/api/reset')
        self.assertEqual(self.call('GET', '/api/status', headers={'Authorization': ''})[0], 401)
        self.assertEqual(self.call('POST', '/api/activate', headers={'Authorization': ''})[0], 401)
        self.assertEqual(self.call('GET', '/health', headers={'Authorization': ''})[0], 200)

    def test_interrupted_transfer_resume(self):
        self.call('POST', '/api/reset')
        data = (Path(__file__).parent/'fixtures/redone-0.1.1-sim-B.bin').read_bytes()
        self.assertEqual(self.call('POST', '/api/transfer/chunk', data[:2048], {'X-Offset': '0'})[1]['received_bytes'], 2048)
        self.assertEqual(self.call('POST', '/api/verify')[0], 422)
        self.assertEqual(self.call('POST', '/api/activate')[0], 409)
        self.assertEqual(self.call('POST', '/api/transfer/chunk', data[2048:], {'X-Offset': '2048'})[1]['received_bytes'], 4096)
        self.assertEqual(self.call('POST', '/api/verify')[1]['verified'], True)
        self.assertEqual(self.call('POST', '/api/activate')[1]['active_partition'], 'B')
        self.assertEqual(self.call('POST', '/api/rollback')[1]['active_partition'], 'A')

    def test_reset_clears_partial_transfer(self):
        self.call('POST', '/api/reset')
        self.call('POST', '/api/transfer/chunk', b'x' * 512, {'X-Offset': '0'})
        state = self.call('POST', '/api/transfer/reset')[1]
        self.assertEqual(state['received_bytes'], 0)
        self.assertFalse(state['verified'])
        self.assertEqual(state['active_partition'], 'A')

    def test_bad_offset(self):
        self.call('POST', '/api/reset')
        self.assertEqual(self.call('POST', '/api/transfer/chunk', b'x', {'X-Offset':'4'})[0], 409)

if __name__ == '__main__': unittest.main()
