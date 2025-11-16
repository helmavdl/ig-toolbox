#!/bin/bash
#
# Validate FHIR resources using the Firely Terminal
#
# 2025-11-16 Helma van der Linden
#

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# assume we are in <root>/scripts
ROOT_DIR="$( dirname "$ME_DIR" )"

# date (now)
DT=$(date +"%Y-%m-%d")

# Check for fhirpkg.lock.json; if missing, run `fhir restore`
if [ ! -f "fhirpkg.lock.json" ]; then
    fhir restore
fi
 
fhir validate "$@"