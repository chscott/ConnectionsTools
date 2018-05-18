#!/bin/bash

function init() {

    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot
    
}

init "${@}" 

# Check status for DB2
getDB2ServerStatus

# Check status for IHS
getIHSServerStatus

# Check status for Solr
getSolrServerStatus

# Check status for WAS servers
# Build an array of WAS profiles
if [[ -d "${wasProfileRoot}" ]]; then
    cd "${wasProfileRoot}" 2>/dev/null
    profiles=($(ls -d * 2>/dev/null))
fi

# For each profile...
for profile in "${profiles[@]}"; do

    # Test if the servers directory exists and contains at least one subdirectory 
    cd "${wasProfileRoot}/${profile}/servers" 2>/dev/null && ls -d * >/dev/null 2>&1

    # If there is no servers directory or there are no subdirectories, skip this profile 
    if [[ ${?} != 0 ]]; then
        continue
    else
        # Get an array of servers
        servers=($(ls -d * 2>/dev/null)) 
        # For each server
        for server in "${servers[@]}"; do
            # Verify that this server exists in the cell
            if [[ "$(isServerInWASCell "${server}" "${profile}")" == "true" ]]; then
                # The server is part of the cell, so go ahead and check its status
                getWASServerStatus "${server}" "${wasProfileRoot}/${profile}"
            fi
        done
    fi

done

# Check status for Pink components 
