"""Connection-level recovery; never replay a customer transaction."""
import asyncio
import logging
import random
import psycopg
from psycopg.rows import dict_row

logger = logging.getLogger("uvicorn.error")


def connect(url):
    return psycopg.connect(url, row_factory=dict_row, connect_timeout=5)


async def initialize(connect_db, schema, attempts=12):
    """Retry connection failures with capped jitter, committing schema atomically."""
    for attempt in range(1, attempts + 1):
        try:
            await asyncio.to_thread(_initialize_once, connect_db, schema)
            logger.info("Account database initialization complete")
            return
        except (psycopg.OperationalError, psycopg.InterfaceError):
            # Exception text can contain connection credentials; do not log it.
            if attempt == attempts:
                logger.error("Account database startup retry budget exhausted")
                raise RuntimeError("Database unavailable during startup") from None
            delay = min(15, 2 ** (attempt - 1)) + random.uniform(0, 1)
            logger.warning("Database unavailable; startup attempt %d/%d, retry in %.1fs",
                           attempt, attempts, delay)
            await asyncio.sleep(delay)


def _initialize_once(connect_db, schema):
    with connect_db() as connection:
        connection.execute("SET LOCAL statement_timeout = '15s'")
        connection.execute("SET LOCAL lock_timeout = '5s'")
        connection.execute(schema)
        connection.commit()


def probe(connect_db):
    with connect_db() as connection:
        connection.execute("SET LOCAL statement_timeout = '3s'")
        connection.execute("SELECT 1")
