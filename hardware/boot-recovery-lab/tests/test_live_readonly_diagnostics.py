import importlib.util
import sys
from pathlib import Path
import unittest
from urllib.error import HTTPError

path = Path(__file__).resolve().parents[1] / 'tools/live_readonly_diagnostics.py'
spec = importlib.util.spec_from_file_location('live_readonly_diagnostics', path)
m = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = m
spec.loader.exec_module(m)


class FakeResponse:
    status = 200
    def __enter__(self): return self
    def __exit__(self, *args): return False
    def read(self, limit): return b'{"running":"ota_0","api_token":"SECRET","updateReady":false}'


class LiveReadonlyDiagnostics(unittest.TestCase):
    def test_only_get_status_and_boot_health(self):
        requests = []
        def opener(request, timeout):
            requests.append(request)
            if request.full_url.endswith('/boot-health'):
                raise HTTPError(request.full_url, 404, 'Not Found', {}, None)
            return FakeResponse()
        result = m.collect('http://192.168.4.1:80', 'x' * 32, opener)
        self.assertEqual([r.get_method() for r in requests], ['GET', 'GET'])
        self.assertEqual([r.full_url.rsplit('/', 1)[-1] for r in requests], ['status', 'boot-health'])
        self.assertEqual(result['results'][1]['state'], 'not_installed')
        self.assertEqual(result['results'][0]['fields']['running'], 'ota_0')
        self.assertNotIn('api_token', str(result))
        self.assertFalse(result['physical_deployment_authorized'])

    def test_reject_credentials_in_url(self):
        with self.assertRaises(ValueError): m.collect('http://user:secret@192.168.4.1', 'x' * 32)

    def test_missing_token_rejected(self):
        with self.assertRaises(ValueError): m.collect('http://192.168.4.1', None)

    def test_unauthorised_is_distinct(self):
        self.assertEqual(m.classify('/status', 401, b'')['state'], 'authentication_required')


if __name__ == '__main__': unittest.main()
