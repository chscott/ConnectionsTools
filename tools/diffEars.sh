#!/bin/bash
# diffEars.sh <EAR1> <EAR2>

# Source prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

# Print the help text
function usage() {

    log "Usage: sudo diffEars.sh <EAR1> <EAR2> [--details]"

}

# Verify the script has the prereqs needed to run
function init() {
    
    # Make sure we're running as root
    checkForRoot

    # Verify commands are available
    type -a diff > /dev/null 2>&1; result=${?}
    if [[ ${result} != 0 ]]; then
        log "The diff command is required to run this script"
        exit 1
    fi 

    # Verify user input is available 
    if [[ ! -e "${1}" || ! -e "${2}" ]]; then
        usage
        exit 1
    else
        ear1="${1}"
        ear2="${2}"
    fi
    
    # Set script variables
    expander="${wasInstallDir}/bin/EARExpander.sh"
    ear1ExpandDir="/tmp/expand_ear1"
    ear2ExpandDir="/tmp/expand_ear2"

}

# Report status
function getStatus() {

    local rc=${1}

    if [[ ${rc} == 0 ]]; then
        log "${ear1} and ${ear2} are identical"
    elif [[ ${rc} == 1 ]]; then
        log "${ear1} and ${ear2} are different"
    else
        log "The diff tool encountered an error"
    fi

}

# Just print the EAR files (apps) that differ
function briefMode() {

    # Just report if the EARs are different
    diff --brief <(unzip -p "${ear1}") <(unzip -p "${ear2}") >/dev/null 2>&1

    getStatus ${?} 

}

# Print all files that differ
function detailsMode() {

    # Make sure we have the EARExpander tool on this system
    if [[ ! -x "${expander}" ]]; then
        log "The --details option requires the "${expander}" script, which was not found on this system. Exiting."
        exit 1 
    fi

    # If the expand directories already exist, exit now and let the admin take appropriate action
    if [[ -d "${ear1ExpandDir}" || -d "${ear2ExpandDir}" ]]; then
        log "At least one expand directory already exists. Please ensure ${ear1ExpandDir} and ${ear2ExpandDir} are deleted before continuing"
        exit 1
    fi

    # Expand the two EAR files
    log "Expanding ${ear1} into ${ear1ExpandDir}..."
    "${expander}" -ear "${ear1}" -operation expand -operationDir "${ear1ExpandDir}" -expansionFlags all >/dev/null 2>&1 
    log "Expanding ${ear2} into ${ear2ExpandDir}..."
    "${expander}" -ear "${ear2}" -operation expand -operationDir "${ear2ExpandDir}" -expansionFlags all >/dev/null 2>&1 

    # Generate the list of files that differ
    log "Generating list of differing files..."
    diff --brief --recursive --new-file "${ear1ExpandDir}" "${ear2ExpandDir}"

    getStatus ${?}

    # Clean up
    log "Deleting ${ear1ExpandDir} and ${ear2ExpandDir}..."
    rm -f -r "${ear1ExpandDir}" "${ear2ExpandDir}"

}

init "${1}" "${2}"

# Invoke the appropriate mode, based on the optional $3 argument
if [[ -z "${3}" ]]; then
    briefMode
elif [[ "${3}" == "--details" ]]; then
    detailsMode
else
    usage
fi
