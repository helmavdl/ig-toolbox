#!/usr/bin/env bash
# Guard: fail if the version disagrees across sushi-config.yaml, package.json and the
# $version alias. Use as a pre-publish gate so a forgotten bump can't be released.
# Run from the IG project root.
set -euo pipefail

[ -f sushi-config.yaml ] || { echo "check-version: no sushi-config.yaml, skipping"; exit 0; }
cfg=$(grep -E '^version:' sushi-config.yaml | head -1 | sed -E 's/^version:[[:space:]]*//' | tr -d '[:space:]')
[ -n "$cfg" ] || { echo "check-version: ERROR no version in sushi-config.yaml" >&2; exit 1; }

fail=0

if [ -f package.json ]; then
  pkg=$(jq -r '.version // empty' package.json 2>/dev/null || true)
  if [ -n "$pkg" ] && [ "$pkg" != "$cfg" ]; then
    echo "check-version: MISMATCH  package.json=$pkg  vs  sushi-config=$cfg" >&2
    fail=1
  fi
fi

if [ -f input/fsh/aliases.fsh ] && grep -qE '^Alias:[[:space:]]*\$version[[:space:]]*=' input/fsh/aliases.fsh; then
  als=$(grep -E '^Alias:[[:space:]]*\$version[[:space:]]*=' input/fsh/aliases.fsh | head -1 | sed -E 's/.*=[[:space:]]*//' | tr -d '[:space:]')
  if [ "$als" != "$cfg" ]; then
    echo "check-version: MISMATCH  \$version alias=$als  vs  sushi-config=$cfg" >&2
    fail=1
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo "check-version: FAILED — run 'make sync-version' and 'make package.json', then rebuild" >&2
  exit 1
fi
echo "check-version: OK ($cfg)"
