import os
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

os.environ.setdefault('DATABASE_URL', 'postgresql://unused')
os.environ.setdefault('SESSION_SECRET', 'test-only-secret')
import psycopg
from fastapi.testclient import TestClient
from app.database import initialize
from app.main import app


class StartupTests(unittest.IsolatedAsyncioTestCase):
    async def test_transient_connection_failure_then_success(self):
        connection = MagicMock()
        connection.__enter__.return_value = connection
        factory = MagicMock(side_effect=[psycopg.OperationalError('private'), connection])
        with patch('app.database.asyncio.sleep', new_callable=AsyncMock) as sleep:
            await initialize(factory, 'SELECT 1')
        self.assertEqual(factory.call_count, 2)
        connection.commit.assert_called_once()
        sleep.assert_awaited_once()

    async def test_retry_exhaustion_has_no_secret(self):
        factory = MagicMock(side_effect=psycopg.OperationalError('private-password'))
        with patch('app.database.asyncio.sleep', new_callable=AsyncMock) as sleep:
            with self.assertRaisesRegex(RuntimeError, '^Database unavailable during startup$'):
                await initialize(factory, 'SELECT 1', attempts=3)
        self.assertEqual(factory.call_count, 3)
        self.assertEqual(sleep.await_count, 2)

    async def test_schema_error_is_not_retried(self):
        connection = MagicMock()
        connection.__enter__.return_value = connection
        connection.execute.side_effect = psycopg.errors.SyntaxError('bad schema')
        factory = MagicMock(return_value=connection)
        with self.assertRaises(psycopg.errors.SyntaxError):
            await initialize(factory, 'broken')
        factory.assert_called_once()
        connection.commit.assert_not_called()


class HttpTests(unittest.TestCase):
    def test_outage_then_recovery_without_process_restart(self):
        # No context manager: startup is covered separately above.
        client = TestClient(app)
        with patch('app.main.probe', side_effect=[psycopg.OperationalError('private'), None]):
            unavailable = client.get('/healthz')
            self.assertEqual(unavailable.status_code, 503)
            self.assertEqual(unavailable.headers['retry-after'], '5')
            self.assertNotIn('private', unavailable.text)
            self.assertEqual(client.get('/livez').status_code, 200)
            self.assertEqual(client.get('/healthz').status_code, 200)

    def test_failed_write_is_not_replayed(self):
        client = TestClient(app)
        with patch('app.main.db', side_effect=psycopg.OperationalError('private')) as factory:
            response = client.post('/v1/logout', headers={'Authorization':'Bearer test'})
        self.assertEqual(response.status_code, 503)
        factory.assert_called_once()


if __name__ == '__main__':
    unittest.main()
