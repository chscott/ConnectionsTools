#!/bin/bash

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Build an array of WAS profiles
    cd "${wasProfileRoot}"
    profiles=($(ls -d *))

}

init "${@}"

# Stop WAS servers
for profile in "${profiles[@]}"; do

    # Determine the profile type
    profileKey="${wasProfileRoot}/${profile}/properties/profileKey.metadata"
    if [[ -f "${profileKey}" ]]; then
        profileType=$(getWASProfileType "${profileKey}")
    fi

    if [[ "${profileType}" == "BASE" ]]; then

        # Change to the servers directory so we can get an array of servers from the subdirectories
        cd "${wasProfileRoot}/${profile}/servers" >/dev/null 2>&1

        # If there is no servers directory, skip it 
        if [[ ${?} == 0 ]]; then
            # Get an array of servers (omit the nodeagent!)
            servers=($(ls -d * | grep -v "nodeagent")) 
            # Stop the servers
            for server in "${servers[@]}"; do
                stopWASServer "${server}" "${wasProfileRoot}/${profile}"
            done
        fi

    fi

done
