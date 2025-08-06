#!/bin/bash
set -e

IMAGE_NAME="ig-toolbox"

echo "🔍 Looking for containers using image: $IMAGE_NAME..."

# Find containers using the image
CONTAINERS=$(docker ps -a -q --filter ancestor=$IMAGE_NAME)

if [ -n "$CONTAINERS" ]; then
    echo "🛑 Stopping and removing containers:"
    docker rm -f $CONTAINERS
else
    echo "✅ No running or stopped containers found for $IMAGE_NAME."
fi

# Remove the old image
if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "🧹 Removing old image: $IMAGE_NAME"
    docker image rm -f "$IMAGE_NAME"
else
    echo "✅ No existing image named $IMAGE_NAME found."
fi

# Rebuild the image
echo "🛠️ Building new image: $IMAGE_NAME:latest"
docker build -t "$IMAGE_NAME:latest" .

echo "✅ Build complete."
