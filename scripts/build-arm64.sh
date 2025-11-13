#!/usr/bin/env bash
# cross-build image for Apple Silicon

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/vars.sh"

"${SCRIPT_DIR}/buildx-setup.sh"

TAG="${TAG_BASE}-arm64"

docker buildx build \
  --platform linux/arm64 \
  "${BUILD_ARGS[@]}" \
  -t "${TAG}" \
  --load \
  .

echo "Built and loaded local image: ${TAG}"
