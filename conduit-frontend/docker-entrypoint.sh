#!/bin/sh
set -eu

cat <<EOF >/usr/share/nginx/html/env.js
window.__env = {
  apiUrl: "${FRONTEND_API_URL:-http://localhost:8000/api}"
};
EOF
