#!/usr/bin/env bash
# Sync the $version alias in input/fsh/aliases.fsh to the version in sushi-config.yaml.
# sushi-config.yaml is the single source of truth; run from the IG project root.
# Idempotent and safe to run on every build.
set -euo pipefail

[ -f sushi-config.yaml ] || { echo "sync-version: no sushi-config.yaml in $(pwd), skipping"; exit 0; }
aliases="input/fsh/aliases.fsh"
[ -f "$aliases" ] || { echo "sync-version: no $aliases, skipping"; exit 0; }

ver=$(grep -E '^version:' sushi-config.yaml | head -1 | sed -E 's/^version:[[:space:]]*//' | tr -d '[:space:]')
[ -n "$ver" ] || { echo "sync-version: ERROR could not read version from sushi-config.yaml" >&2; exit 1; }

if ! grep -qE '^Alias:[[:space:]]*\$version[[:space:]]*=' "$aliases"; then
  echo "sync-version: WARN no '\$version' alias found in $aliases" >&2
  exit 0
fi

cur=$(grep -E '^Alias:[[:space:]]*\$version[[:space:]]*=' "$aliases" | head -1 | sed -E 's/.*=[[:space:]]*//' | tr -d '[:space:]')
if [ "$cur" = "$ver" ]; then
  echo "sync-version: \$version already $ver"
  exit 0
fi

# Rewrite the alias line, preserving the no-quotes convention.
sed -i.bak -E "s|^(Alias:[[:space:]]*\\\$version[[:space:]]*=[[:space:]]*).*|\\1${ver}|" "$aliases"
rm -f "${aliases}.bak"
echo "sync-version: \$version ${cur} -> ${ver}"
