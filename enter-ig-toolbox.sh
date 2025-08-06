#!/bin/bash
#
# Open a shell in the running container or start the container first
#

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# date (now)
DT=$(date +"%Y-%m-%d")

set -e

source "${ME_DIR}/ig-toolbox-common.sh"

# Get running containers that use the image
running_containers=($(docker ps --filter ancestor="$IMAGE_NAME" --format '{{.Names}}'))

if [ ${#running_containers[@]} -eq 0 ]; then
  echo "📦 No running containers based on image '$IMAGE_NAME'."
  read -p "Do you want to start a new one? (y/N): " start_new
  if [[ "$start_new" =~ ^[Yy]$ ]]; then
    PORT=$(find_free_port) || exit 1
    docker_run "$PORT"
  else
    echo "🛑 Aborted."
    exit 0
  fi

elif [ ${#running_containers[@]} -eq 1 ]; then
  echo "✅ Entering the only running container: ${running_containers[0]}"
  docker exec -it "${running_containers[0]}" bash

else
  echo "🧠 Multiple running containers found:"
  select name in "${running_containers[@]}"; do
    if [[ -n "$name" ]]; then
      echo "Entering: $name"
      docker exec -it "$name" bash
      break
    else
      echo "Invalid selection"
    fi
  done
fi
