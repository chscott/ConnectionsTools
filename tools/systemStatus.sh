#!/bin/bash
# systemStatus.sh: Get the status for all Connections server components on the system

# Source prereqs
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

# Check status for WAS servers
for profile in "${profiles[@]}"; do

    # Get an array of servers
    cd "${wasProfileRoot}/${profile}/servers" >/dev/null 2>&1

    # If the profile directory has no servers directory, skip it
    if [[ ${?} == 0 ]]; then
        servers=($(ls -d *)) 
        # Get the server status
        for server in "${servers[@]}"; do
            getWASServerStatus "${server}" "${wasProfileRoot}/${profile}"
        done
    fi

done

# Check status for IHS
getIHSServerStatus

# Check status for Solr
getSolrServerStatus

# Check status for Pink components 
