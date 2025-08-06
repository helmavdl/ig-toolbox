#!/bin/bash
#
# helper script to start the docker image from the commandline
# (outside of VS code)
#

set -e

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${ME_DIR}/ig-toolbox-common.sh"

PORT=$(find_free_port) || exit 1
docker_run "$PORT"
