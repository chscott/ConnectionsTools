#!/bin/bash
# compareApps.sh <profile1> <profile2>

# Source prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

# Print the help text
function usage() {

    log "Usage: ? sudo compareApps.sh <profile1> <profile2> [details]"
    log "Use the profile name only. Path information will be prepended automatically"
    log ""
    log "Examples:" 
    log ""
    log "Print a list of apps that are out of sync between the profiles:"
    log "? sudo compareApps.sh ic1 ic2"
    log ""
    log "Print a list of files that are out of sync between the profiles:"
    log "? sudo compareApps.sh ic1 ic2 details" 

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

    # Verify ictools.conf data is available
    if [[ -z "${wasProfileRoot}" || -z "${wasCellName}" ]]; then
        log "The wasProfileRoot and wasCellName variables must be set in /etc/ictools.conf"
        exit 1
    fi 

    # Verify user input is available 
    if [[ -z "${1}" || -z "${2}" ]]; then
        usage
        exit 1
    else
        profile1="${wasProfileRoot}/${1}"
        profile2="${wasProfileRoot}/${2}"
    fi

    # Verify both directories have deployed applications 
    ls -d "${profile1}/installedApps/"* >/dev/null 2>&1
    profile1HasApps=${?}
    ls -d "${profile2}/installedApps/"* >/dev/null 2>&1
    profile2HasApps=${?} 
   
    if [[ ! -d "${profile1}" && ! -d "${profile2}" ]]; then
        log "${profile1} and ${profile2} do not exist"
        exit 1
    elif [[ ! -d "${profile1}" ]]; then
        log "${profile1} does not exist"
        exit 1 
    elif [[ ! -d "${profile2}" ]]; then
        log "${profile2} does not exist"
        exit 1 
    elif [[ ${profile1HasApps} > 0 && ${profile2HasApps} > 0 ]]; then
        log "${profile1} and ${profile2} have no deployed applications"
        exit 1
    elif [[ ${profile1HasApps} > 0 ]]; then
        log "${profile1} has no deployed applications"
        exit 1
    elif [[ ${profile2HasApps} > 0 ]]; then
        log "${profile2} has no deployed applications"
        exit 1
    fi

}

# Just print the EAR files (apps) that differ
function briefMode() {

    local excludeApps="${1}"
    local dir1="${profile1}/installedApps/${wasCellName}"/
    local dir2="${profile2}/installedApps/${wasCellName}"/

    # Generate the list of apps that are out of sync 
    ifstmp=${IFS}
    IFS=$'\n'
    apps=($(diff --brief --recursive "${dir1}" "${dir2}" | \
        grep -v -E "${excludeApps}" | \
        awk -F "[/:]" '{for(i=0;i<NF;i++)if($i~/.ear/)app=$i; print app}' | \
        sort | \
        uniq))
    IFS=${ifstmp}

    # If there are no remaining apps after removing exclude apps, there's nothing to report
    if [[ -z "${apps}" ]]; then
        log "No applications are out of sync"
        exit 0
    fi

    # Report the apps that are out of sync and are not excluded
    log "The following applications are out of sync:"
    for app in "${apps[@]}"; do
        if [[ ! -z "${app}" ]]; then
            log "${app}"
        fi
    done

}

# Print all files that differ
function detailsMode() {

    local excludeApps="${1}"
    local dir1="${profile1}/installedApps/${wasCellName}"/
    local dir2="${profile2}/installedApps/${wasCellName}"/

    # Generate the list of files that differ
    diff --brief --recursive "${dir1}" "${dir2}" | grep -v -E "${excludeApps}"

    # If no files differ, diff returns 1
    if [[ ${?} == 1 ]]; then
        log "No applications are out of sync"
    fi

}

init "${1}" "${2}"

log "Comparing application files in profiles. This may take several minutes..."

# Filter out any exclude apps (see /etc/ictools.conf)
regexp=""
firstIteration="true"
for excludeApp in "${excludeCompareApps[@]}"; do
    if [[ "${firstIteration}" == "true" ]]; then
        regexp="${excludeApp}"
        firstIteration="false"
    else
        regexp+="|${excludeApp}" 
    fi
done    

# Invoke the appropriate mode, based on the optional $3 argument
if [[ -z "${3}" ]]; then
    briefMode "${regexp}"
elif [[ "${3}" == "details" ]]; then
    detailsMode "${regexp}"
else
    usage
fi
