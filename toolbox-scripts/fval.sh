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

RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
ORANGE='\033[0;33m'


# Check for fhirpkg.lock.json; if missing, run `fhir restore`
make fhirpkg.lock.json

for h in "$@"; do
    echo '
 -------------------' "${h}"

    log_name="$(basename $h)"
    log_result="/tmp/${log_name}.result.txt"

    fhir validate "${h}" --fail > "/tmp/${log_name}.txt"
    RESULT=$?
    grep -v \
    -e 'Validating resource' \
    -e "cannot find codesystem 'urn:ietf:bcp:13'" \
    -e 'Result. INVALID' \
    -e '^$' \
    "/tmp/${log_name}.txt" \
    2>&1 > $log_result
            
    length=$(grep -v '^[[:blank:]]*$' $log_result | grep -v 'INVALID' | grep -v 'ERROR' | wc -l)
    if [[ "$length" == '       0' ]]; then
        echo -e "${ORANGE}IGNORED${NC} ${h}"
    else
        # some other error
        echo -e "${RED}ERROR${NC} ${h}"
        cat $log_result
    fi
done
