#!/bin/bash
#
# Helper script to inflate Nictiz packages that are missing the snapshots 
#

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# assume we are in support/scripts
ROOT_DIR="$( dirname "$( dirname "$ME_DIR" )" )"

# date (now)
DT=$(date +"%Y-%m-%d")

cd ~/.fhir/packages

ls -al 

for p in $( ls -1d nictiz.fhir* ); do
    echo $p
    # remove old versions of the packages
    if [[ "$p" == *'nictiz.fhir.nl.r4.nl-core#0.5'* ]] ; then
        rm -rf $p
    elif [[ "$p" == 'nictiz.fhir.nl.r4.zib2020#0.5'* ]] ; then
        rm -rf $p
    elif [[ "$p" == 'nictiz.fhir.nl.r4.medicationprocess9#1.0'* ]] ; then
        rm -rf $p
    fi
    cd "$p"/package
    fhir inflate --here
    cd -
done
