# syntax=docker/dockerfile:1.7

# ----------------------------------------------------
# Base image with common deps and settings
# ----------------------------------------------------
FROM debian:bookworm-slim AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------
# Build-time knobs (override with --build-arg)
# ----------------------------------------------------
ARG JAVA_MAJOR=17
ARG DOTNET_CHANNEL=8.0
ARG FIRELY_TERMINAL_VERSION=3.4.0
ARG HAPI_CLI_VERSION=8.2.1
ARG NODE_VERSION=20.17.0

# BuildKit provides these automatically; keep them declared for clarity
ARG TARGETPLATFORM
ARG TARGETARCH

# ----------------------------------------------------
# Centralized URLs
# ----------------------------------------------------
ENV IG_PUBLISHER_API="https://api.github.com/repos/HL7/fhir-ig-publisher/releases/latest"
ENV FHIR_VALIDATOR_API="https://api.github.com/repos/hapifhir/org.hl7.fhir.core/releases/latest"
ENV IG_PUBLISHER_LATEST="https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar"
ENV FHIR_VALIDATOR_LATEST="https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar"
ENV DOTNET_INSTALLER_URL="https://dot.net/v1/dotnet-install.sh"
ENV NTS_PROXY_URL="https://raw.githubusercontent.com/Nictiz/snippets/refs/heads/main/NTS-proxy/NTS-proxy.py"
ENV HAPI_CLI_URL="https://github.com/hapifhir/hapi-fhir/releases/download/v${HAPI_CLI_VERSION}/hapi-fhir-${HAPI_CLI_VERSION}-cli.zip"

# ----------------------------------------------------
# Base OS deps (arch-agnostic)
# ----------------------------------------------------

# System packages, Java, Ruby, build tools, utilities
RUN --mount=type=cache,target=/var/cache/apt <<'EOF' bash
set -e

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg unzip xz-utils \
  jq yq \
  locales git build-essential zlib1g-dev \
  mitmproxy python3-requests python3-termcolor \
  ruby-full \
  "openjdk-${JAVA_MAJOR}-jre" \
  plantuml graphviz \
  nginx gettext-base

  rm -rf /var/lib/apt/lists/*
EOF

# ----------------------------------------------------
# Locale
# ----------------------------------------------------
RUN <<'EOF' bash
set -e
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
locale-gen
EOF
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"


# ----------------------------------------------------
# Node stage (exact version + checksum)
# ----------------------------------------------------
FROM base AS node

ARG NODE_VERSION
ARG TARGETARCH

ENV NODE_HOME="/usr/local/node" PATH="/usr/local/node/bin:/usr/local/bin:${PATH}"

RUN <<'EOF' bash
set -euo pipefail

case "${TARGETARCH:-amd64}" in
  amd64) NODE_DIST="linux-x64" ;;
  arm64) NODE_DIST="linux-arm64" ;;
  *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;;
esac

NODE_BASE_URL="https://nodejs.org/dist/v${NODE_VERSION}"
NODE_TARBALL="node-v${NODE_VERSION}-${NODE_DIST}.tar.xz"

cd /tmp

# Download tarball and checksums into /tmp
curl -fsSLO "${NODE_BASE_URL}/${NODE_TARBALL}"
curl -fsSLO "${NODE_BASE_URL}/SHASUMS256.txt"

# Verify checksum (now both files are in /tmp, the cwd)
grep " ${NODE_TARBALL}$" SHASUMS256.txt | sha256sum -c -

# Install Node into NODE_HOME
mkdir -p "${NODE_HOME}"
tar -xJf "/tmp/${NODE_TARBALL}" -C "${NODE_HOME}" --strip-components=1
ln -sf "${NODE_HOME}/bin/node" /usr/local/bin/node
ln -sf "${NODE_HOME}/bin/npm"  /usr/local/bin/npm
ln -sf "${NODE_HOME}/bin/npx"  /usr/local/bin/npx

# Clean up
rm -f "/tmp/${NODE_TARBALL}" "/tmp/SHASUMS256.txt"

node --version
npm --version
EOF

# ----------------------------------------------------
# Node CLIs (float to latest; record resolved versions)
# ----------------------------------------------------
RUN <<'EOF' bash
set -e
npm install -g fsh-sushi gofsh @bonfhir/cli

mkdir -p /opt/ig-toolbox-meta
{
  (sushi   --version 2>/dev/null | xargs -I{} echo "RESOLVED_SUSHI_VERSION={}") || true
  (gofsh   --version 2>/dev/null | xargs -I{} echo "RESOLVED_GOFSH_VERSION={}") || true
  (bonfhir --version 2>/dev/null | xargs -I{} echo "RESOLVED_BONFHIR_VERSION={}") || true
} >> /opt/ig-toolbox-meta/node.env
EOF


# ----------------------------------------------------
# .NET + Firely Terminal stage
# ----------------------------------------------------
FROM base AS dotnet

ARG DOTNET_CHANNEL
ARG FIRELY_TERMINAL_VERSION
ARG TARGETARCH

ENV DOTNET_ROOT="/usr/share/dotnet" PATH="$PATH:/usr/local/bin"

RUN <<'EOF' bash
set -euo pipefail

curl -fsSLo /tmp/dotnet-install.sh "${DOTNET_INSTALLER_URL}"
if [[ "${TARGETARCH:-amd64}" == "amd64" ]]; then 
  ARCH_DOTNET="x64"; 
else 
  ARCH_DOTNET="arm64"; 
fi
bash /tmp/dotnet-install.sh --channel "${DOTNET_CHANNEL}" --architecture "${ARCH_DOTNET}" --install-dir "${DOTNET_ROOT}"
ln -s "${DOTNET_ROOT}/dotnet" /usr/bin/dotnet
rm -f /tmp/dotnet-install.sh
dotnet --info
EOF

# install Firely terminal
RUN <<'EOF' bash
set -e
dotnet tool install --tool-path /usr/local/bin firely.terminal --version "${FIRELY_TERMINAL_VERSION}"

mkdir -p /opt/ig-toolbox-meta
{
  echo "RESOLVED_DOTNET_CHANNEL=${DOTNET_CHANNEL}"
  echo "RESOLVED_FIRELY_TERMINAL_VERSION=${FIRELY_TERMINAL_VERSION}"
} >> /opt/ig-toolbox-meta/dotnet.env
EOF

# ----------------------------------------------------
# HAPI FHIR CLI stage
# ----------------------------------------------------
FROM base AS hapi

ARG HAPI_CLI_VERSION

ENV PATH="$PATH:/usr/share/hapi-fhir-cli"

RUN <<'EOF' bash
set -e
mkdir -p /usr/share/hapi-fhir-cli
curl -fsSL "${HAPI_CLI_URL}" -o /tmp/hapi-cli.zip
unzip -q /tmp/hapi-cli.zip -d /usr/share/hapi-fhir-cli
rm -f /tmp/hapi-cli.zip
mkdir -p /opt/ig-toolbox-meta
echo "RESOLVED_HAPI_FHIR_CLI_VERSION={${HAPI_CLI_VERSION}" >> /opt/ig-toolbox-meta/hapi.env
EOF


# ----------------------------------------------------
# IG Publisher stage (resolve latest at build time)
# ----------------------------------------------------
FROM base AS igpublisher

RUN <<'EOF' bash
set -euo pipefail

mkdir -p /usr/share/igpublisher /opt/ig-toolbox-meta
TAG="$(curl -fsSL ${IG_PUBLISHER_API} | jq -r .tag_name || true)"

if [[ -z "$TAG" || "$TAG" == "null" ]]; then
  echo "GitHub API unavailable; using latest jar"
  curl -fsSL ${IG_PUBLISHER_LATEST} -o /usr/share/igpublisher/publisher.jar
  echo "RESOLVED_IG_PUBLISHER_TAG=latest" >> /opt/ig-toolbox-meta/igpublisher.env
else
  echo "IG Publisher tag: $TAG"
  curl -fsSL "https://github.com/HL7/fhir-ig-publisher/releases/download/${TAG}/publisher.jar" -o /usr/share/igpublisher/publisher.jar
  echo "RESOLVED_IG_PUBLISHER_TAG=${TAG}" >> /opt/ig-toolbox-meta/igpublisher.env
fi

printf '%s\n' '#!/usr/bin/env bash' 'exec java -jar /usr/share/igpublisher/publisher.jar "$@"' > /usr/bin/publisher
chmod +x /usr/bin/publisher
EOF


# ----------------------------------------------------
# FHIR Validator stage (resolve latest at build time)
# ----------------------------------------------------
FROM base AS validator

RUN <<'EOF' bash

set -euo pipefail

mkdir -p /opt/ig-toolbox-meta
TAG="$(curl -fsSL ${FHIR_VALIDATOR_API} | jq -r .tag_name || true)"

if [[ -z "$TAG" || "$TAG" == "null" ]]; then
  echo "GitHub API unavailable; using latest validator"
  curl -fsSL ${FHIR_VALIDATOR_LATEST} -o /usr/share/validator_cli.jar
  echo "RESOLVED_FHIR_VALIDATOR_TAG=latest" >> /opt/ig-toolbox-meta/validator.env
else
  echo "FHIR Validator tag: $TAG"
  curl -fsSL "https://github.com/hapifhir/org.hl7.fhir.core/releases/download/${TAG}/validator_cli.jar" -o /usr/share/validator_cli.jar
  echo "RESOLVED_FHIR_VALIDATOR_TAG=${TAG}" >> /opt/ig-toolbox-meta/validator.env
fi
EOF

# ----------------------------------------------------
#  NTS proxy stage to use the Dutch Terminology server in the validation
# ----------------------------------------------------
FROM base AS ntsproxy

RUN <<'EOF' bash
set -euo pipefail

mkdir -p /usr/share/ntsproxy /opt/ig-toolbox-meta
curl -fsSL "${NTS_PROXY_URL}" -o /usr/share/ntsproxy/NTS-proxy.py

TAG="$(mitmproxy --version | cut -d':' -f2 || true)"

echo "RESOLVED_MITMPROXY_TAG=${TAG}" >> /opt/ig-toolbox-meta/mitmproxy.env
EOF

# ----------------------------------------------------
# Final image: assemble tools, add scripts
# ----------------------------------------------------
FROM base AS final

# Make build args visible in this stage for labels
ARG NODE_VERSION
ARG DOTNET_CHANNEL
ARG FIRELY_TERMINAL_VERSION
ARG HAPI_CLI_VERSION
ARG JAVA_MAJOR
ARG TARGETARCH

# ----------------------------------------------------
# Java (multi-arch JAVA_HOME) & IG Publisher tuning
# ----------------------------------------------------
# Debian installs OpenJDK under /usr/lib/jvm/java-<major>-openjdk-<arch>
# TARGETARCH is "amd64" or "arm64", which matches Debian suffixes.
ENV JAVA_HOME="/usr/lib/jvm/java-${JAVA_MAJOR}-openjdk-${TARGETARCH}"
ENV JAVA_TOOL_OPTIONS="-Xms6g -Xmx6g \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UseStringDeduplication \
  -XX:+AlwaysPreTouch \
  -XX:+ParallelRefProcEnabled \
  -Dfile.encoding=UTF-8" 


# Node from node stage
COPY --from=node /usr/local/node /usr/local/node
ENV PATH="/usr/local/node/bin:/usr/local/bin:${PATH}"

# .NET + Firely from dotnet stage
COPY --from=dotnet /usr/share/dotnet /usr/share/dotnet
RUN ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Copy the entire tool-path directory, not just the shim
COPY --from=dotnet /usr/local/bin/ /usr/local/bin/

# HAPI CLI
COPY --from=hapi /usr/share/hapi-fhir-cli /usr/share/hapi-fhir-cli
ENV PATH="$PATH:/usr/share/hapi-fhir-cli"

# IG Publisher and launcher
COPY --from=igpublisher /usr/share/igpublisher /usr/share/igpublisher
COPY --from=igpublisher /usr/bin/publisher /usr/bin/publisher

# FHIR Validator
COPY --from=validator /usr/share/validator_cli.jar /usr/share/validator_cli.jar

# Proxy for NTS server
COPY --from=ntsproxy /usr/share/ntsproxy /usr/share/ntsproxy
RUN ln -s /usr/share/ntsproxy/ntsproxy.py /usr/bin/ntsproxy.py


# Bring in version metadata from each stage
COPY --from=node        /opt/ig-toolbox-meta/node.env        /opt/ig-toolbox-meta/node.env
COPY --from=dotnet      /opt/ig-toolbox-meta/dotnet.env      /opt/ig-toolbox-meta/dotnet.env
COPY --from=hapi        /opt/ig-toolbox-meta/hapi.env        /opt/ig-toolbox-meta/hapi.env
COPY --from=igpublisher /opt/ig-toolbox-meta/igpublisher.env /opt/ig-toolbox-meta/igpublisher.env
COPY --from=validator   /opt/ig-toolbox-meta/validator.env   /opt/ig-toolbox-meta/validator.env
COPY --from=ntsproxy    /opt/ig-toolbox-meta/mitmproxy.env   /opt/ig-toolbox-meta/mitmproxy.env

# Merge them into /etc/environment once
RUN <<'EOF' bash
set -e
if [[ -d /opt/ig-toolbox-meta ]]; then
  for f in /opt/ig-toolbox-meta/*.env; do
    [[ -f "$f" ]] || continue
    cat "$f" >> /etc/environment
  done
fi
EOF

# ----------------------------------------------------
# Ruby gems (float to latest)
# ----------------------------------------------------
RUN <<'EOF' bash
set -e
gem install -N jekyll bundler
EOF

# ----------------------------------------------------
# Oh My Bash (optional shell UX)
# ----------------------------------------------------
RUN <<'EOF' bash
set -e
bash -lc "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" || true
# add 24h clock to oh my bash
echo 'export THEME_CLOCK_FORMAT="%H:%M:%S"' >> /root/.bashrc
EOF

# ----------------------------------------------------
# Helper scripts
# ----------------------------------------------------

COPY build-scripts/run-nginx.sh /usr/bin/run-nginx.sh
COPY build-scripts/update-checker.sh /usr/bin/update-checker.sh
COPY build-scripts/add-vscode-files /usr/bin/add-vscode-files
COPY build-scripts/add-profile /usr/bin/add-profile
COPY build-scripts/add-fhir-resource-diagram /usr/bin/add-fhir-resource-diagram
COPY build-scripts/entrypoint.sh /entrypoint.sh

RUN <<'EOF' bash
set -e
chmod +x /usr/bin/run-nginx.sh /usr/bin/update-checker.sh \
         /usr/bin/add-vscode-files /usr/bin/add-profile /usr/bin/add-fhir-resource-diagram \
         /entrypoint.sh
EOF

# ----------------------------------------------------
# Workdir & entrypoint
# ----------------------------------------------------
WORKDIR /workspaces
ENTRYPOINT ["/entrypoint.sh"]

# Image metadata / provenance labels
LABEL org.opencontainers.image.title="ig-toolbox" \
      org.opencontainers.image.description="FHIR tooling image with SUSHI, GoFSH, BonFHIR, IG Publisher, Validator, Firely Terminal, HAPI CLI, etc." \
      org.opencontainers.image.vendor="VZVZ" \
      ig.toolbox.node.version="${NODE_VERSION}" \
      ig.toolbox.dotnet.channel="${DOTNET_CHANNEL}" \
      ig.toolbox.firely.terminal.version="${FIRELY_TERMINAL_VERSION}" \
      ig.toolbox.hapi.cli.version="${HAPI_CLI_VERSION}"
