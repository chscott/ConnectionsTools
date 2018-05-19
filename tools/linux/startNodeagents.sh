#!/bin/bash

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

}

init "${@}"

# Build an array of WAS profiles
if [[ "$(directoryExists "${wasProfileRoot}")" == "true" && "$(directoryHasSubDirs "${wasProfileRoot}")" == "true" ]]; then
    cd "${wasProfileRoot}" && profiles=($(ls -d *))
else
    log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
fi

for profile in "${profiles[@]}"; do
    # Deployment Manager profiles have no nodeagent, so skip them
    if [[ "$(isWASBaseProfile "${profile}")" == "true" ]]; then
        # If there is no servers directory or it has no subdirectories, skip this profile 
        if [[ "$(directoryExists "${wasProfileRoot}/${profile}/servers")" == "false" ||
              "$(directoryHasSubDirs "${wasProfileRoot}/${profile}/servers")" == "false" ]]; then 
            continue
        else
            # Find the nodeagent 
            cd "${wasProfileRoot}/${profile}/servers" && server=$(ls -d * | grep --max-count 1 "nodeagent")
            if [[ "$(isServerInWASCell "${server}" "${profile}")" == "true" ]]; then
                # The server is part of the cell, so go ahead and start it
                startWASServer "${server}" "${wasProfileRoot}/${profile}"
            fi 
        fi
    fi
done
