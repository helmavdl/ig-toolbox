#!/bin/bash
#
# This script configures and starts nginx with the available project(s) in the container
#

set -euo pipefail

echo "[INFO] Configuring NGINX for multi-project IG hosting..."

PROJECTS_DIR="/workspaces/projects"
OUTPUT_DIR="output"
NGINX_CONF="/etc/nginx/conf.d/ig-projects.conf"
INDEX_FILE="/workspaces/index.html"

# Clean existing config
rm -f /etc/nginx/conf.d/*
rm -f "$INDEX_FILE"

# Start config file with single server block
cat <<EOF > "$NGINX_CONF"
server {
    listen 80;
    server_name localhost;

    index index.html;
    root /workspaces;

    location / {
        try_files /index.html =404;
    }

EOF

# Begin HTML index
echo "<h1>FHIR IG Projects</h1><ul>" > "$INDEX_FILE"

# Loop through all projects
for dir in "$PROJECTS_DIR"/*; do
  [[ -d "$dir/input/fsh" && -f "$dir/$OUTPUT_DIR/index.html" ]] || continue

  project=$(basename "$dir")
  echo "[INFO] Adding location for project: $project"

  # Append location block
  cat <<EOF >> "$NGINX_CONF"
    location /${project}/ {
        alias ${dir}/${OUTPUT_DIR}/;
        index index.html;
        try_files \$uri /${project}/index.html;
    }

EOF

  # Add link to index.html
  echo "<li><a href='/${project}/index.html'>${project}</a></li>" >> "$INDEX_FILE"
done

# Close server block
echo "}" >> "$NGINX_CONF"

# Finish HTML index
echo "</ul>" >> "$INDEX_FILE"

echo "[INFO] Starting NGINX..."
exec nginx -g "daemon off;"
