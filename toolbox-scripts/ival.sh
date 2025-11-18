#!/bin/bash
#
# run IG publisher
#
# 2025-11-16 Helma van der Linden
#

set -Eeuo pipefail

# date (now)
DT=$(date +"%Y-%m-%d %H:%M:%S")

echo "$DT === Running IG Publisher once ==="

# java $JAVA_OPTS -jar /usr/share/igpublisher/publisher.jar \
#   	-ig ig.ini -output /tmp/output "$@"

# -------- Config (env-overridable) --------
# Heap sizing as % of container memory (Java 11+):
INIT_PCT="${INIT_PCT:-25}"    # initial heap % (e.g., 25)
MAX_PCT="${MAX_PCT:-75}"      # max heap % (e.g., 75)

# Other JVM flags (tune as you like)
# 

# JVM_FLAGS="${JVM_FLAGS:--XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled -Djava.io.tmpdir=/tmp}"
JVM_FLAGS=${JAVA_TOOL_OPTIONS}

IG_DIR="${IG_DIR:-$PWD}"
IG_INI="${IG_INI:-$PWD/ig.ini}"
JAR_PATH="${JAR_PATH:-/usr/share/igpublisher/publisher.jar}"

# default Publisher folders (these are what we tmpfs-mount in compose)
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/output}"
TEMP_DIR="${TEMP_DIR:-/tmp/temp}"

# Where to copy the finished site on the host
HOST_OUT="${HOST_OUT:-$PWD/output}"   # mapped to ./output in compose

# Find out which terminology server to use
TXOPTION_FILE=$HOME/.txoption
txoption=""
[[ -f "$TXOPTION_FILE" ]] && txoption=$(<"$TXOPTION_FILE")

# Extra args you might want to pass through to the Publisher
EXTRA_ARGS="${EXTRA_ARGS:-}"

# ------------------------------------------
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo "==> IG root:       $IG_DIR"
echo "==> IG ini:        $IG_INI"
echo "==> Publisher jar: $JAR_PATH"
echo "==> Output dir:    $OUTPUT_DIR (tmpfs expected)"

# Ensure folders exist (tmpfs mounts are already in compose)
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR" "$HOST_OUT"

start_ts=$(date +%s)

# # Unset envs that can silently override your heap settings
# unset _JAVA_OPTIONS || true
# unset JAVA_OPTIONS || true

# # Build final Java options
# PCT_FLAGS="-XX:InitialRAMPercentage=${INIT_PCT} -XX:MaxRAMPercentage=${MAX_PCT}"
PCT_FLAGS=""

# echo "Checking JVM container-aware sizing..."
# echo "Using: ${PCT_FLAGS} ${JVM_FLAGS}"
# java ${PCT_FLAGS} ${JVM_FLAGS} -XshowSettings:vm -version 2>&1 | sed -n '1,120p'

# Run the IG Publisher
java ${PCT_FLAGS} ${JVM_FLAGS} -jar "$JAR_PATH" -ig "$IG_INI" $txoption -rapido $EXTRA_ARGS

end_ts=$(date +%s)
echo "==> Publisher finished in $((end_ts - start_ts))s"

# Copy output from RAM → host bind (only if mapped/writable)
if [ -d "$HOST_OUT" ] && [ -w "$HOST_OUT" ]; then
	echo "==> Syncing $OUTPUT_DIR → $HOST_OUT"
	cp -R "$OUTPUT_DIR"/ "$HOST_OUT"/
	echo "==> Sync complete."
else
	echo "!! Host output target '$HOST_OUT' not available/writable; leaving files in '$OUTPUT_DIR'."
fi

cd -