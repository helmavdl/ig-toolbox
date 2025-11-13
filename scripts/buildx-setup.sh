#!/usr/bin/env bash
# Prepare Buildx and CPU emulation so you can cross-build locally.
set -euo pipefail

BUILDER_NAME="${1:-local-multi}"

# 1) Ensure binfmt emulators are registered (once per host).
#    This enables running amd64 builds on Apple Silicon and vice versa.
docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null

# 2) Create (if missing) and select a buildx builder that uses a container driver.
if ! docker buildx inspect "${BUILDER_NAME}" >/dev/null 2>&1; then
  docker buildx create --name "${BUILDER_NAME}" --driver docker-container --use >/dev/null
else
  docker buildx use "${BUILDER_NAME}" >/dev/null
fi

# 3) Bootstrap starts the builder and wires in QEMU support via binfmt.
docker buildx inspect --bootstrap >/dev/null

echo "Buildx is ready (builder: ${BUILDER_NAME})."
