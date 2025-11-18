#!/bin/bash
#
# Build a package locally
#
# 2025-11-17 Helma van der Linden
#

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# assume we are in <root>/scripts
ROOT_DIR="$( dirname "$ME_DIR" )"

# date (now)
DT=$(date +"%Y-%m-%d")

PKG_NAME=$(jq -r '.name' package.json)
PKG_VERSION=$(jq -r '.version' package.json)

PKG_FILE="${PKG_NAME}-${PKG_VERSION}.tgz"

sushi
rm -rf _pack
mkdir _pack
cp fsh-generated/resources/*.json _pack/
cp package.json _pack/

# 2025-11-17 NOTE fhir pack only works correctly 
# if the directory and filename are provided

fhir pack _pack --name "${PKG_FILE}"

PKG_FILE="$(ls -t *.tgz 2>/dev/null | head -n 1)"
if [ -z "$PKG_FILE" ]; then 
    echo "ERROR: No .tgz file found after 'fhir pack'"
    exit 1
fi
fhir install "$PKG_FILE" --file

# the fhir install action adds the package as dependency to the current package.json 🤯
make package.json