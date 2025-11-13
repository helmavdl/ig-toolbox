#!/usr/bin/env bash
# Re-tag the most recent build for your host architecture as ig-toolbox:local
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/vars.sh"

ARCH="$(docker version --format '{{.Server.Arch}}')"
TAG="${TAG_BASE}-${ARCH}"

if ! docker image inspect "${TAG}" >/dev/null 2>&1; then
  echo "Image ${TAG} not found. Did you run make build?"
  exit 1
fi

echo "Tagging ${TAG} as ${IMAGE_NAME}:local"
docker tag "${TAG}" "${IMAGE_NAME}:local"
echo "You can now run: docker run -it ${IMAGE_NAME}:local"
