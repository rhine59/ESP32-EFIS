"""Run in the disposable account container after each documented outage phase."""
import json
import sys
import time
import urllib.request
import urllib.error
from app.main import db

mode = sys.argv[1]
if mode == 'outage':
    with urllib.request.urlopen('http://127.0.0.1:8091/livez', timeout=10) as response:
        assert response.status == 200
    try:
        urllib.request.urlopen('http://127.0.0.1:8091/healthz', timeout=10)
    except urllib.error.HTTPError as error:
        assert error.code == 503, error.code
    else:
        raise AssertionError('Outage was not detected')
    print('PASS: database outage returns 503; process remains live')
else:
    deadline = time.monotonic() + 180
    while True:
        try:
            with urllib.request.urlopen('http://127.0.0.1:8091/healthz', timeout=10) as response:
                assert json.load(response)['status'] == 'ok'
            break
        except (OSError, urllib.error.URLError):
            if time.monotonic() > deadline:
                raise
            time.sleep(2)
    with db() as connection:
        if mode == 'seed':
            connection.execute("INSERT INTO audit_events(event,subject) VALUES ('recovery_test','sentinel')")
        else:
            count = connection.execute("SELECT count(*) AS n FROM audit_events WHERE event='recovery_test' AND subject='sentinel'").fetchone()['n']
            assert count == 1, count
    print('PASS: database ready; test sentinel ' + ('committed' if mode == 'seed' else 'preserved'))
