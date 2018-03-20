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

# Start Solr
startSolrServer

# Stop IHS
startIHSServer

# Start WAS nodeagents
"${scriptDir}/startNodeagents.sh"

# Start WAS application servers
"${scriptDir}/startAppServers.sh"

# Stop Pink components
