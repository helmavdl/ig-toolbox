#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -o allexport; source "${ROOT_DIR}/.env"; set +o allexport
fi

DATE_TAG="$(date -u +%Y.%m.%d)"
GIT_SHA="$(git rev-parse --short=7 HEAD 2>/dev/null || echo 'nogit')"

TAG_BASE="${IMAGE_NAME}:${DATE_TAG}-git-${GIT_SHA}"

BUILD_ARGS=(
  "--build-arg" "JAVA_MAJOR=${JAVA_MAJOR}"
  "--build-arg" "DOTNET_CHANNEL=${DOTNET_CHANNEL}"
  "--build-arg" "FIRELY_TERMINAL_VERSION=${FIRELY_TERMINAL_VERSION}"
  "--build-arg" "HAPI_CLI_VERSION=${HAPI_CLI_VERSION}"
  "--build-arg" "NODE_VERSION=${NODE_VERSION}"
)
