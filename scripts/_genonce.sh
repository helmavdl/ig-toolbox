#!/bin/bash
#
# run IG publisher
#
# 2025-08-04 Helma van der Linden
#

set -e

# date (now)
DT=$(date +"%Y-%m-%d")


echo "$DT === Running IG Publisher once ==="

java -jar /usr/share/igpublisher/publisher.jar \
  -ig ig.ini "$@"
