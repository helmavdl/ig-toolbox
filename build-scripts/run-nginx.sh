#!/bin/bash
#
# This script configures and starts nginx with the available project(s) in the container
#

set -euo pipefail

echo "[INFO] Preparing NGINX..."

rm -f /etc/nginx/conf.d/*

for workspace_dir in /workspaces/projects; do
    [[ -d "$workspace_dir" ]] || continue

    project_name=$(basename "$workspace_dir")
    project_conf="/etc/nginx/conf.d/${project_name}.conf"

    # Defaults
    SERVER_NAME=""
    ROOT_DIR="output"

    # Optional .project.env config
    if [[ -f "$workspace_dir/.project.env" ]]; then
        echo "[INFO] Loading config from $workspace_dir/.project.env"
        set -o allexport
        source "$workspace_dir/.project.env"
        set +o allexport
    fi

    echo "[INFO] Generating config for $project_name (SERVER_NAME=${SERVER_NAME:-localhost})"

    if [[ -n "${SERVER_NAME}" ]]; then
        cat <<EOF > "$project_conf"
server {
    listen 80;
    server_name $SERVER_NAME;

    root $workspace_dir/$ROOT_DIR;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }
}
EOF
    else
        cat <<EOF > "$project_conf"
server {
    listen 80;
    server_name localhost;

    location /$project_name/ {
        alias $workspace_dir/$ROOT_DIR/;
        index index.html;
        try_files \$uri /$project_name/index.html;
    }
}
EOF
    fi
done

echo "[INFO] Starting NGINX..."
exec nginx -g "daemon off;"
