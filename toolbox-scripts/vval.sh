#!/bin/bash
#
# Validate FHIR resource instance using the official FHIR validator
#

set -e

# Location of the script
ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# assume we are in <root>/scripts
ROOT_DIR="$( dirname "$ME_DIR" )"

vjar=${ROOT_DIR}/../profielen/validator/validator_cli.jar

if [[ "${ME_DIR}" == *'scripts'* || "${ME_DIR}" == *'usr/local/'* ]]; then
  # we are in an ig-toolbox container
  ROOT_DIR='/workspaces'

  vjar='/usr/share/validator_cli.jar'

  TXOPTION_FILE=$HOME/.txoption
  txoption=""
  [[ -f "$TXOPTION_FILE" ]] && txoption=$(<"$TXOPTION_FILE")

else
  txoption=""
fi

# find out the project name

# assume we are in a FSH project
project=$(pwd | grep -oE '/workspaces/projects/[^/]+' | sed 's/\/workspaces\/projects\///')
projectDir="${ROOT_DIR}/projects/${project}"
projectIG="${projectDir}"/fsh-generated/resources

# if we are in a different project, e.g. transformations
if [ "${project}" == "" ]; then
  project=$( basename $( pwd ))
  projectDir='.'
  projectIG=''
fi

echo "project = ${project}"
echo "projectDir = ${projectDir}"

# if [ $# -lt 1 ]; then
#   echo "Usage: validate-fhir.sh <file>"
#   echo "Example: validate-fhir.sh output/package/example.json"
#   exit 1
# fi

# Read the project IGs and fhir version from the package.json
IGs=$(jq -r '[.dependencies | to_entries[] | select(.key | test("hl7.fhir.r4") | not) | "-ig " + .key + "#" + .value] | join(" ")' ${projectDir}/package.json)
FHIR_VERSION=$(jq -r '.fhirVersions[0]' ${projectDir}/package.json)

if [[ ! -d "${projectIG}" && "${projectIG}" != "" ]]; then
  echo "Create the package for ${project} first"
  exit 2
fi

echo "FHIR version: $FHIR_VERSION"
echo "projectIG = ${projectIG}"
echo "other IGs = ${IGs}"

echo
echo "${DT}" '----------------------------------- Validating ' ${project}' resources'
echo

fhir="-version ${FHIR_VERSION}"

if [[ "${projectIG}" != "" ]]; then
	projectIG='-ig '"${projectIG}"
fi

# Set the default path if no arguments are provided
if [[ "$#" -gt 0 ]]; then
    FILES=("$@")
else
    FILES=(${projectDir}/fsh-generated/resources/*.json)
fi

# Define prefixes to filter out (separate multiple prefixes with |)
EXCLUDE_PREFIXES="CodeSystem-|ValueSet-|StructureDefinition-|ConceptMap-|OperationDefinition-|ImplementationGuide-"

# Filter the files and store the result
FILTERED_FILES=()
for file in "${FILES[@]}"; do
    if [[ ! $(basename "$file") =~ ^($EXCLUDE_PREFIXES) ]]; then
        FILTERED_FILES+=("$file")
    fi
done

if [ -f ${projectDir}/fsh-generated/resources/ImplementationGuide*.json ]; then
  # Get the jurisdiction from the ImplementationGuide
  jurisdiction_code=$(jq -r '.jurisdiction[0].coding[0].code // "global"' ${projectDir}/fsh-generated/resources/ImplementationGuide*.json)
  jurisdiction_param="-jurisdiction ${jurisdiction_code}"
else
  jurisdiction_param=''
fi

if [ -f "${ROOT_DIR}"/projects/suppress_warnings.txt ]; then
  advisor_param="-advisor-file ${ROOT_DIR}/projects/suppress_warnings.txt"
else
  advisor_param=''
fi

# Print and use the filtered list
# echo "Filtered files: ${FILTERED_FILES[@]}"

java -jar ${vjar} ${fhir} ${projectIG}  ${IGs} \
  -no-extensible-binding-warnings \
  -show-message-ids \
  ${txoption} \
  ${jurisdiction_param} \
  ${advisor_param} \
  ${FILTERED_FILES[@]} \
  -output-style json \
  -output "${projectDir}/tmp_validate_result.json" 
  >> /dev/null

echo processing with ${ROOT_DIR_DIR}/scripts/filter-validator.jq

cat "${projectDir}/tmp_validate_result.json" | jq -r -f ${ROOT_DIR}/scripts/filter-validator.jq > "${projectDir}/validation_results.json" 

echo "result,file" > "${projectDir}/validation_summary.csv"
cat "${projectDir}/validation_results.json" | jq -r '. | [.result, .file] | @csv' >> "${projectDir}/validation_summary.csv"
cat "${projectDir}/validation_summary.csv"

# ---
# #!/bin/bash

# # test using the official validator_cli.jar

# # Location of the script
# ME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# # assume we are in scripts
# ROOT_DIR="$( dirname "$ME_DIR" )"

# vjar=${ROOT_DIR}/../profielen/validator/validator_cli.jar


# project=${1}

# if [[ "${project}" == '' ]]; then
#   echo "$( basename "${0}" )" '<projectnaam: aof, mitz of nl-vzvz-core> <optional: file/files to validate>'
#   exit 1
# fi

# projectIG="${projectDir}"/fsh-generated/resources
# # coreIG='vzvz.fhir.nl-vzvz-core'
# # nictiz_coreIG='nictiz.fhir.nl.r4.nl-core'
# # nictiz_zibIG='nictiz.fhir.nl.r4.zib2020'

# # IGs=$(jq -r '[.dependencies | keys[] | select(test("hl7.fhir.r4") | not) | "-ig " + .] | join(" ")' ${projectDir}/package.json)
# IGs=$(jq -r '[.dependencies | to_entries[] | select(.key | test("hl7.fhir.r4") | not) | "-ig " + .key + "#" + .value] | join(" ")' ${ROOT_DIR}/${project}/package.json)
# FHIRversion=$(jq -r '.fhirVersions[0]' ${ROOT_DIR}/${project}/package.json)

# echo "projectIG = ${projectIG}"
# echo "other IGs = ${IGs}"

# if [[ ! -d "${projectIG}" ]]; then
#   echo "maak eerst het package voor ${project}"
#   exit 2
# fi

# # date (now)
# DT=$(date +"%Y-%m-%d %H:%M:%S")

# echo
# echo "${DT}" '----------------------------------- Validating ' ${project}' resources'
# echo

# fhir="-version ${FHIRversion}"


# shift 1
# # Set the default path if no arguments are provided
# if [[ "$#" -gt 0 ]]; then
#     FILES=("$@")
# else
#     FILES=(${ROOT_DIR}/${project}/fsh-generated/resources/*.json)
# fi

# # Define prefixes to filter out (separate multiple prefixes with |)
# EXCLUDE_PREFIXES="CodeSystem-|ValueSet-|StructureDefinition-|ConceptMap-|OperationDefinition-|ImplementationGuide-"

# # Filter the files and store the result
# FILTERED_FILES=()
# for file in "${FILES[@]}"; do
#     if [[ ! $(basename "$file") =~ ^($EXCLUDE_PREFIXES) ]]; then
#         FILTERED_FILES+=("$file")
#     fi
# done

# # Print or use the filtered list
# echo "Filtered files: ${FILTERED_FILES[@]}"

# # -ig "${coreIG}" -ig ${nictiz_coreIG} -ig ${nictiz_zibIG}
# java -jar "${vjar}" ${fhir} -ig "${projectIG}"  ${IGs} \
#   -no-extensible-binding-warnings -advisor-file "${ROOT_DIR}"/suppress_warnings.txt \
#   ${FILTERED_FILES[@]} \
#   -output "${ROOT_DIR}/${project}_tmp_validate_result.txt" \
#   -output-style compact 
#   # >> /dev/null

# grep -v \
#         -e 'Information - .* has no Display Names for the language en' \
#         -e 'Information - None of the codings provided are in the value set' \
#         -e 'Information - This element does not match any known slice defined in the profile http://vzvz.nl/fhir/StructureDefinition/nl-vzvz-Device' \
#         -e 'Information - This element does not match any known slice defined in the profile http://nictiz.nl/fhir/StructureDefinition/nl-core-HealthProfessional-Practitioner' \
#         -e 'Information - This element does not match any known slice defined in the profile http://nictiz.nl/fhir/StructureDefinition/nl-core-HealthcareProvider-Organization' \
#         -e 'Information - No types could be determined from the search string, so the types can.t be checked' \
#         -e 'Information - The definition for the Code System with URI .* doesn.t provide any codes so the code cannot be validated' \
#         -e 'Information - A definition for CodeSystem .*aorta-datareference-update-reason.* could not be found, so the code cannot be validated' \
#         -e 'Information - Reference to experimental CodeSystem .*request-intent.*' \
#         -e 'Information - Binding for path Bundle.entry.*resource.*Task.*input.*type has no source, so can.t be checked' \
#         -e 'Information - Binding for path Task.input.*type has no source, so can.t be checked' \
#         -e 'Information - Reference to draft CodeSystem' \
#         -e 'Information - This element does not match any known slice defined in the profile http://nictiz.nl/fhir/StructureDefinition/nl-core-Patient' \
#         -e 'Information - .* is the default display; the code system .* has no Display Names for the language nl-NL' \
#         -e 'Warning - A definition for CodeSystem .* could not be found, so the code cannot be validated' \
#         -e 'Warning - De definitie voor CodeSystem .* is niet gevonden, dus kan de code niet worden gevalideerd' \
#         -e 'Warning - Kan niet controleren of de code in de waardelijst .* staat, omdat het codesysteem .* niet is gevonden' \
#         -e 'Warning - Unable to check whether the code is in the value set .* because the code system .* was not found' \
#         -e 'Warning - Resolved system .*, but the definition doesn.t include any codes, so the code has not been validated' \
#         -e 'Warning - Resolved system urn:ietf:bcp:47, but the definition is not complete, so assuming value set include is correct' \
#         -e 'Warning - ValueSet .*medicationrequest-status.* not found' \
#         -e 'Warning - ValueSet .*medicationrequest-intent.* not found' \
#         -e 'Warning - ValueSet .*administrative-gender.* not found' \
#         -e 'Warning - ValueSet .*name-assembly-order.* not found' \
#         -e 'Warning - ValueSet .*address-use.* not found' \
#         -e 'Warning - ValueSet .*address-type.* not found' \
#         -e 'Warning - ValueSet .*operation-outcome.* not found' \
#         -e 'Warning - ValueSet .*c80-doc-typecodes.* not found' \
#         -e 'Warning - ValueSet .*mimetypes.* not found' \
#         -e 'Warning - Found multiple matching profiles for' \
#         -e 'Warning - Resource has a language (nl-NL), and the XHTML has a' \
#         -e 'Error - Wrong Display Name .* (for the language(s) .en.)' \
#         -e 'Error - None of the codings provided are in the value set .LandCodelijsten' \
#         -e 'Error - None of the codings provided are in the value set .StopTypeCodelijst' \
#         -e '^$' \
#         "${ROOT_DIR}/${project}_tmp_validate_result.txt"
#         # 2>&1 > tmp/"${h}.result.txt"
