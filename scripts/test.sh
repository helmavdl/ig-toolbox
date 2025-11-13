#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/vars.sh"

# Pick the best matching tag for this host
ARCH="$(docker version --format '{{.Server.Arch}}')"
IMG="${TAG_BASE}-${ARCH}"

echo "Testing image ${IMG}"
docker run --rm "${IMG}" bash -lc '
  set -e
  echo "[node] $(node --version)"
  echo "[npm]  $(npm --version)"
  echo "[ruby] $(ruby --version)"
  echo "[java] $(java -version 2>&1 | head -n1)"
  echo "[dotnet]"
  dotnet --info | head -n 5
  echo "[sushi] $(sushi --version || true)"
  echo "[gofsh] $(gofsh --version || true)"
  echo "[bonfhir] $(bonfhir --version || true)"
  echo "[fhir terminal] $(fhir --version || true)"
  echo "[hapi cli] $(ls /usr/share/hapi-fhir-cli | wc -l) files present"
  echo "[ig publisher] $(java -jar /usr/share/igpublisher/publisher.jar -help >/dev/null 2>&1 && echo ok || echo missing)"
  echo "[validator] $(test -f /usr/share/validator_cli.jar && echo ok || echo missing)"
'
