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

# Start DB2
"${scriptDir}/startDB2.sh"

# Start Solr
"${scriptDir}/startSolr.sh"

# Start IHS
"${scriptDir}/startIHS.sh"

# Start WAS Deployment Manager
"${scriptDir}/startDmgr.sh"

# Start WAS nodeagents and application servers
"${scriptDir}/startAppServers.sh"

# Stop Pink components
