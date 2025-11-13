#!/usr/bin/env bash
# Local build for your current architecture (loads into docker images)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/vars.sh"

# Detect host's docker server platform (expects linux/amd64 or linux/arm64)
PLATFORM="$(docker version --format '{{.Server.Os}}/{{.Server.Arch}}')"
[[ "${PLATFORM}" == linux/* ]] || { echo "Unsupported docker server platform: ${PLATFORM}"; exit 1; }

# Use buildx so everything is consistent, but --load only supports a single platform.
ARCH="${PLATFORM#linux/}"
TAG="${TAG_BASE}-${ARCH}"

docker buildx build \
  --platform "${PLATFORM}" \
  "${BUILD_ARGS[@]}" \
  -t "${TAG}" \
  --load \
  .

echo "Built and loaded local image: ${TAG}"
