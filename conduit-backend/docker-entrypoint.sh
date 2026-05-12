#!/bin/sh
set -eu

python - <<'PY'
import os
import sys
import time

import psycopg2

host = os.getenv("DJANGO_DB_HOST", "database")
port = int(os.getenv("DJANGO_DB_PORT", "5432"))
name = os.getenv("DJANGO_DB_NAME", "conduit")
user = os.getenv("DJANGO_DB_USER", "conduit")
password = os.getenv("DJANGO_DB_PASSWORD", "conduit")

for attempt in range(30):
    try:
        connection = psycopg2.connect(
            host=host,
            port=port,
            dbname=name,
            user=user,
            password=password,
        )
        connection.close()
        sys.exit(0)
    except Exception as exc:
        print(
            "Database connection attempt {attempt}/30 failed: {error}".format(
                attempt=attempt + 1,
                error=exc,
            ),
            file=sys.stderr,
        )
        time.sleep(2)

print("Database is not reachable after waiting.", file=sys.stderr)
sys.exit(1)
PY

python manage.py migrate --noinput

exec gunicorn conduit.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers "${GUNICORN_WORKERS:-3}" \
  --timeout "${GUNICORN_TIMEOUT:-60}"
