#!/bin/bash
#
# script with common functions to be used with enter-ig-toolbox and start-ig-toolbox
#

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# date (now)
DT=$(date +"%Y-%m-%d")

# Image and volume setup
IMAGE_NAME="ig-toolbox:latest"
TOOLBOX_PATH="${ME_DIR}/scripts"
PROJECT_PATH="$(pwd)"

# Retrieve credentials from 1Password
FIRELY_USERNAME=$(op read "op://VZVZ/SIMPLIFIER.NET/email")
FIRELY_PASSWORD=$(op read "op://VZVZ/SIMPLIFIER.NET/password")

# 🔍 Find a free port in 8080–8099 range
find_free_port() {
  for port in {8080..8099}; do
    if ! lsof -iTCP:"$port" -sTCP:LISTEN -t >/dev/null; then
      echo "$port"
      return 0
    fi
  done
  echo "No free ports found in range 8080-8099" >&2
  return 1
}


# Check if a container name already exists (running or stopped)
container_name_exists() {
  local name="$1"
  docker ps -a --format '{{.Names}}' | grep -q "^${name}$"
}

# Generate a unique container name based on port or fallback
generate_unique_container_name() {
  local base="ig-dev"
  local suffix="$1"
  local name="${base}-${suffix}"

  if ! container_name_exists "$name"; then
    echo "$name"
    return
  fi

  # Try adding incremental suffix if base exists
  for i in {1..20}; do
    local candidate="${name}-${i}"
    if ! container_name_exists "$candidate"; then
      echo "$candidate"
      return
    fi
  done

  echo "❌ Could not find unique container name" >&2
  return 1
}

# 🚀 Run a new Docker container for the IG toolbox
docker_run() {
  local port="$1"
  local container_name
  container_name=$(generate_unique_container_name "$port") || exit 1

  echo "🚀 Starting container '$container_name'"
  echo "Host port $port → Container port 80"
  echo "Project: $PROJECT_PATH"
  echo "Scripts: $TOOLBOX_PATH"

  docker run -it \
    --name "$container_name" \
    -v "$PROJECT_PATH":/workspaces \
    -v "$TOOLBOX_PATH":/workspaces/ig-scripts:ro \
    -w /workspaces \
    -e FIRELY_USERNAME="$FIRELY_USERNAME" \
    -e FIRELY_PASSWORD="$FIRELY_PASSWORD" \
    -p "$port":80 \
    "$IMAGE_NAME" \
    bash
}
