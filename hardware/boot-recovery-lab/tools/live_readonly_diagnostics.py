#!/usr/bin/env python3
"""Read-only HTTP diagnostics for existing RedOne; no flash, reboot or OTA calls."""
import argparse
import json
import os
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen

PATHS = ('/status', '/boot-health')


def classify(path, status, payload):
    if status == 404 and path == '/boot-health':
        return {'endpoint': path, 'state': 'not_installed', 'note': 'Older RedOne firmware; not a device failure'}
    if status == 401:
        return {'endpoint': path, 'state': 'authentication_required'}
    if status != 200:
        return {'endpoint': path, 'state': 'http_error', 'http_status': status}
    try:
        data = json.loads(payload)
    except (ValueError, TypeError):
        return {'endpoint': path, 'state': 'invalid_json'}
    if not isinstance(data, dict):
        return {'endpoint': path, 'state': 'unexpected_response'}
    # Never dump raw response; unknown future fields may contain sensitive data.
    allowed = ('running', 'selected', 'next', 'bootState', 'rollbackAvailable',
               'rollbackReason', 'updateReady', 'pendingVerify', 'mayConfirmBoot',
               'blocker', 'evidenceSource', 'inactiveImagePresent')
    safe = {key: data[key] for key in allowed if key in data and type(data[key]) in (str, bool, int)}
    return {'endpoint': path, 'state': 'ok', 'fields': safe}


def collect(base_url, token, opener=urlopen):
    url = urlsplit(base_url)
    if url.scheme != 'http' or not url.hostname or url.username or url.password or url.query or url.fragment or url.path not in ('', '/'):
        raise ValueError('Use a plain local http://IP[:port] origin without credentials or path')
    if not token or len(token) < 32:
        raise ValueError('A provisioned device token is required via environment variable')
    results = []
    for path in PATHS:
        request = Request(base_url.rstrip('/') + path,
                          headers={'X-Lab-Token': token, 'Accept': 'application/json'},
                          method='GET')
        try:
            with opener(request, timeout=4) as response:
                results.append(classify(path, response.status, response.read(8192)))
        except HTTPError as exc:
            results.append(classify(path, exc.code, b''))
            exc.close()
        except (URLError, TimeoutError, OSError):
            results.append({'endpoint': path, 'state': 'unreachable'})
    return {'mode': 'live-http-read-only', 'results': results,
            'flash_written': False, 'boot_selection_changed': False,
            'physical_deployment_authorized': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-url', required=True, help='Local RedOne http://IP:port origin')
    parser.add_argument('--token-env', default='REDONE_LAB_TOKEN', help='Environment variable name, not token value')
    args = parser.parse_args()
    print(json.dumps(collect(args.base_url, os.environ.get(args.token_env)), indent=2))


if __name__ == '__main__':
    main()
