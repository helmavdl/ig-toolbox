#!/usr/bin/env bash
set -euo pipefail

IG_NAME="${1:?IG name required}"
DRY_RUN="${DRY_RUN:-false}"

TARGET_HOST="${TARGET_HOST:?TARGET_HOST required}"
TARGET_USER="${TARGET_USER:-deploy}"

BUILD_DIR="${BUILD_DIR:-output}"
TARGET_BASE_PATH="${TARGET_BASE_PATH:-/var/www/fhir-igs}"
TARGET_PATH="${TARGET_BASE_PATH}/${IG_NAME}"

if [[ ! -d "${BUILD_DIR}" ]]; then
  echo "[ERROR] Build directory not found: ${BUILD_DIR}" >&2
  exit 1
fi

RSYNC_ARGS=(-rlvzO --delete)

if [[ "${DRY_RUN}" == "true" ]]; then
  RSYNC_ARGS+=(--dry-run)
fi

echo "[INFO] IG_NAME=${IG_NAME}"
echo "[INFO] BUILD_DIR=${BUILD_DIR}"
echo "[INFO] TARGET=${TARGET_HOST}:${TARGET_PATH}/"

rsync "${RSYNC_ARGS[@]}" \
  "${BUILD_DIR}/" \
  "${TARGET_USER}@${TARGET_HOST}:${TARGET_PATH}/"
