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
"${scriptDir}/stopAppServers.sh"

# Stop WAS nodeagents
"${scriptDir}/stopNodeagents.sh"

# Stop WAS Deployment Manager
"${scriptDir}/stopDmgr.sh"

# Stop IHS
"${scriptDir}/stopIHS.sh"

# Stop Solr
"${scriptDir}/stopSolr.sh"

# Stop DB2
"${scriptDir}/stopDB2.sh"

# Stop Pink components
