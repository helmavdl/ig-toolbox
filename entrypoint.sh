#!/bin/bash
set -e

echo "[ENTRYPOINT] Generating dynamic NGINX config..."
/usr/bin/run-nginx.sh &

echo "[ENTRYPOINT] Running update checker..."
/usr/bin/update-checker.sh

echo "[ENTRYPOINT] Starting interactive shell..."
exec /bin/bash
