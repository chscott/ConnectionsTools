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

# Start DB2
if [[ "$(directoryExists "${db2InstallDir}")" == "true" ]]; then
    "${scriptDir}/startDB2.sh"
fi

# Start Solr
if [[ "$(directoryExists "${solrInstallDir}")" == "true" ]]; then
    "${scriptDir}/startSolr.sh"
fi

# Start IHS
if [[ "$(directoryExists "${ihsInstallDir}")" == "true" ]]; then
    "${scriptDir}/startIHS.sh"
fi

# Start IHS Admin
if [[ "$(directoryExists "${ihsInstallDir}")" == "true" ]]; then
    "${scriptDir}/startIHSAdmin.sh"
fi

# Start WAS Deployment Manager
if [[ "$(directoryExists "${wasDmgrProfile}")" == "true" ]]; then
    "${scriptDir}/startDmgr.sh"
fi

# Start WAS nodeagents and application servers
if [[ "$(directoryExists "${wasInstallDir}")" == "true" ]]; then
    "${scriptDir}/startAppServers.sh"
fi

# Stop Pink components
