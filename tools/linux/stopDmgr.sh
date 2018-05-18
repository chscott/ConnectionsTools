#!/bin/bash

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf" 
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Make sure this is a Deployment Manager node
    checkForDmgr

}

init "${@}"

# Build an array of WAS profiles
cd "${wasProfileRoot}" 2>/dev/null
profiles=($(ls -d * 2>/dev/null))

# For each profile...
for profile in "${profiles[@]}"; do

    # Only need to continue if the profile type is DEPLOYMENT_MANAGER
    if [[ "$(isWASDmgrProfile "${profile}")" == "true" ]]; then

        # Test if the servers directory exists and contains at least one subdirectory 
        cd "${wasProfileRoot}/${profile}/servers" 2>/dev/null && ls -d * >/dev/null 2>&1

        # If there is no servers directory or there are no subdirectories, skip this profile 
        if [[ ${?} != 0 ]]; then
            continue
        else
            # Get an array of servers
            servers=($(ls -d * 2>/dev/null)) 
            # For each server (should only be one)...
            for server in "${servers[@]}"; do
                # Verify that this server exists in the cell
                if [[ "$(isServerInWASCell "${server}" "${profile}")" == "true" ]]; then
                    # The server is part of the cell, so go ahead and stop it
                    stopWASServer "${server}" "${wasProfileRoot}/${profile}"
                fi
            done
        fi
    fi

done
