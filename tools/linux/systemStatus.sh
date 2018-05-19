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
if [[ "$(directoryExists "${wasProfileRoot}")" == "true" && "$(directoryHasSubDirs "${wasProfileRoot}")" == "true" ]]; then
    cd "${wasProfileRoot}" && profiles=($(ls -d *))
else
    log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
fi

for profile in "${profiles[@]}"; do
    # If there is no servers directory or it has no subdirectories, skip this profile 
    if [[ "$(directoryExists "${wasProfileRoot}/${profile}/servers")" == "false" ||
          "$(directoryHasSubDirs "${wasProfileRoot}/${profile}/servers")" == "false" ]]; then 
        continue
    else
        # Get an array of servers
        cd "${wasProfileRoot}/${profile}/servers" && servers=($(ls -d *)) 
        for server in "${servers[@]}"; do
            if [[ "$(isServerInWASCell "${server}" "${profile}")" == "true" ]]; then
                # The server is part of the cell, so go ahead and check its status
                getWASServerStatus "${server}" "${wasProfileRoot}/${profile}"
            fi
        done
    fi
done

# Check status for Pink components 
