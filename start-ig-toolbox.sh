#!/bin/bash
#
# helper script to start the docker image from the commandline
# (outside of VS code)
#

set -e

IMAGE_NAME="ig-toolbox:latest"
CONTAINER_NAME="ig-dev"

# Detect absolute path of the current project (mounted as /workspaces)
PROJECT_PATH="$(pwd)"

echo "🚀 Starting IG Toolbox container..."
docker run -it --rm \
  --name "$CONTAINER_NAME" \
  -v "$PROJECT_PATH":/workspaces \
  -w /workspaces \
  -p 8080:80 \
  "$IMAGE_NAME"
