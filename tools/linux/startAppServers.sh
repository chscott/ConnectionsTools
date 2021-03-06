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

# First start the nodeagents, as these must be running to start application servers 
"${scriptDir}/startNodeagents.sh"

# Build an array of WAS profiles
if [[ "$(directoryExists "${wasProfileRoot}")" == "true" && "$(directoryHasSubDirs "${wasProfileRoot}")" == "true" ]]; then
    cd "${wasProfileRoot}" && profiles=($(ls -d *))
else
    log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
fi

for profile in "${profiles[@]}"; do
    # Deployment Manager profiles have no application servers, so skip them
    if [[ "$(isWASBaseProfile "${profile}")" == "true" ]]; then
        # If there is no servers directory or it has no subdirectories, skip this profile 
        if [[ "$(directoryExists "${wasProfileRoot}/${profile}/servers")" == "false" ||
              "$(directoryHasSubDirs "${wasProfileRoot}/${profile}/servers")" == "false" ]]; then 
            continue
        else
            # Get an array of servers (not named "nodeagent")
            cd "${wasProfileRoot}/${profile}/servers" && servers=($(ls -d * | grep -v "nodeagent")) 
            for server in "${servers[@]}"; do
                # Only start servers that are in the cell but not of type webserver (since webservers aren't started the same way)
                if [[ "$(isServerInWASCell "${server}" "${profile}")" == "true" && "$(isWASWebserver "${server}" "${profile}")" == "false" ]]; then
                    startWASServer "${server}" "${wasProfileRoot}/${profile}"
                fi
            done
        fi
    fi
done
