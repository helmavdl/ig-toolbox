#!/bin/bash
#
# Install all dependencies as defined in package.json
#
# 2025-11-14 Helma van der Linden
#

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# assume we are in <root>/scripts
ROOT_DIR="$( dirname "$ME_DIR" )"

# date (now)
DT=$(date +"%Y-%m-%d")

echo "Installing FHIR dependencies..."
fhir restore
jq -r '.dependencies | to_entries[] | "\(.key)@\(.value)"' package.json | while read -r package; do 
	if [ "${package#nictiz}" != "${package}" ]; then 
		echo "Inflating $package..."; 
		fhir inflate --package $package || { echo "Failed to inflate $package"; exit 1; }; 
	fi 
done
echo "All dependencies installed."
