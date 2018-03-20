#!/bin/bash
# startDmgr.sh: Start Deployment Manager

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf" 
. "${scriptDir}/utils.sh"

function init() {

    # Make sure we're running as root
    checkForRoot

    # Build an array of WAS profiles
    cd "${wasProfileRoot}"
    profiles=($(ls -d *))

}

init

# Find the Deployment Manager profile
for profile in "${profiles[@]}"; do

    # Determine the profile type
    profileKey="${wasProfileRoot}/${profile}/properties/profileKey.metadata"
    if [[ -f "${profileKey}" ]]; then
        profileType=$(getWasProfileType "${profileKey}")
    fi

    if [[ "${profileType}" == "DEPLOYMENT_MANAGER" ]]; then

        # Change to the servers directory so we can get an array of servers from the subdirectories
        cd "${wasProfileRoot}/${profile}/servers" >/dev/null 2>&1

        # If the profile directory has no servers directory, skip it
        if [[ ${?} == 0 ]]; then
            servers=($(ls -d *)) 
            # Start the server (should only be one for Deployment Manager)
            for server in "${servers[@]}"; do
                startWASServer "${server}" "${wasProfileRoot}/${profile}"
            done
        else
            log "No servers were found in the ${profile} profile"
            exit 1
        fi
    fi

done
