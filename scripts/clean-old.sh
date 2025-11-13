#!/usr/bin/env bash

# Clean out old images and keep the last N images
# N = default 5

set -euo pipefail

# Load configuration (.env for IMAGE_NAME)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -o allexport; source "${ROOT_DIR}/.env"; set +o allexport
else
  echo ".env file missing. Cannot determine ${IMAGE_NAME}." >&2
  exit 1
fi

IMAGE_PREFIX="${IMAGE_NAME}"

# How many images to keep (can override with N env var, e.g. N=7 make clean-old)
KEEP_N="${N:-5}"
DRY_RUN="${DRY_RUN:-0}"

echo "Looking for images with prefix '${IMAGE_PREFIX}' (excluding ':local')..."
ALL_IMAGES=$(docker images --format '{{.Repository}}:{{.Tag}}' \
  | grep "^${IMAGE_PREFIX}:" \
  | grep -v ":local$" \
  || true)

if [[ -z "${ALL_IMAGES}" ]]; then
  echo "No ${IMAGE_PREFIX} images found to consider."
  exit 0
fi

echo "All matching images (unsorted):"
echo "${ALL_IMAGES}"
echo

# Sort tags so the most recent ones by naming convention (YYYY.MM.DD) appear first.
# This relies on your tag scheme ig-toolbox:YYYY.MM.DD-git-<sha>-<arch>
SORTED_IMAGES=$(echo "${ALL_IMAGES}" | sort -r)

TO_KEEP=$(echo "${SORTED_IMAGES}" | head -n "${KEEP_N}" || true)
TO_DELETE=$(comm -23 \
  <(echo "${SORTED_IMAGES}" | sort) \
  <(echo "${TO_KEEP}" | sort) \
  || true)

echo "Configured to keep the most recent ${KEEP_N} images."
echo
echo "Images to keep:"
[ -n "${TO_KEEP}" ] && echo "${TO_KEEP}" || echo "  (none?)"
echo
if [[ -z "${TO_DELETE}" ]]; then
  echo "No older images to delete."
  exit 0
fi

echo "Images to delete:"
echo "${TO_DELETE}"
echo

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN=1 set. Not deleting anything."
  exit 0
fi

# Stop and remove containers depending on the images to be deleted
echo "Checking for containers using images to be deleted..."
for IMG in ${TO_DELETE}; do
  CONTAINERS=$(docker ps -a --filter "ancestor=${IMG}" --format '{{.ID}}' || true)
  if [[ -n "${CONTAINERS}" ]]; then
    echo "Removing containers for image ${IMG}:"
    echo "${CONTAINERS}"
    docker rm -f ${CONTAINERS}
  fi
done

echo
echo "Removing old images..."
docker rmi -f ${TO_DELETE}

echo "Old image cleanup complete."
