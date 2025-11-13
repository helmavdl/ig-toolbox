#!/usr/bin/env bash
# delete the image and remove all containers based on that image

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -o allexport; source "${ROOT_DIR}/.env"; set +o allexport
else
  echo ".env file missing. Cannot determine IMAGE_NAME." >&2
  exit 1
fi

IMAGE_PREFIX="${IMAGE_NAME:-ig-toolbox}"

echo "Searching for containers using images starting with '${IMAGE_PREFIX}'..."

CONTAINERS=$(docker ps -a --format "{{.ID}} {{.Image}}" \
  | grep "^.* ${IMAGE_PREFIX}" || true)

if [[ -z "${CONTAINERS}" ]]; then
  echo "No containers found using ${IMAGE_PREFIX} images."
else
  echo "Stopping and removing containers:"
  echo "${CONTAINERS}"
  IDS=$(echo "${CONTAINERS}" | awk '{print $1}')
  docker rm -f ${IDS}
fi

echo
echo "Searching for images starting with '${IMAGE_PREFIX}'..."

IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" \
  | grep "^${IMAGE_PREFIX}" || true)

if [[ -z "${IMAGES}" ]]; then
  echo "No images found matching ${IMAGE_PREFIX}."
  exit 0
fi

echo "Removing images:"
echo "${IMAGES}"

docker rmi -f ${IMAGES}

echo "Cleanup complete."
