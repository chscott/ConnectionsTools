#!/bin/bash
# startAll.sh: Start all Connections deployment components on the system

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
