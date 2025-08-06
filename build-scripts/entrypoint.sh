#!/bin/bash
set -e

export PATH="/usr/local/bin/ig-scripts:$PATH"

echo "[ENTRYPOINT] Generating dynamic NGINX config..."
/usr/bin/run-nginx.sh &

echo "[ENTRYPOINT] Running update checker..."
/usr/bin/update-checker.sh

echo "[ENTRYPOINT] Starting interactive shell..."
exec /bin/bash
