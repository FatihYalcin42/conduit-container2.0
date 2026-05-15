#!/bin/sh
set -eu

attempt=1
max_attempts=30

until PGPASSWORD="${DJANGO_DB_PASSWORD:-conduit}" pg_isready \
  -h "${DJANGO_DB_HOST:-database}" \
  -p "${DJANGO_DB_PORT:-5432}" \
  -U "${DJANGO_DB_USER:-conduit}" \
  -d "${DJANGO_DB_NAME:-conduit}"; do
  echo "Database connection attempt ${attempt}/${max_attempts} failed." >&2
  if [ "$attempt" -ge "$max_attempts" ]; then
    echo "Database is not reachable after waiting." >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 2
done

python manage.py migrate --noinput

exec gunicorn conduit.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers "${GUNICORN_WORKERS:-3}" \
  --timeout "${GUNICORN_TIMEOUT:-60}"
