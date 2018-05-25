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

# Stop WAS servers
if [[ "$(directoryExists "${wasInstallDir}")" == "true" ]]; then
    "${scriptDir}/stopAppServers.sh"
fi

# Stop WAS nodeagents
if [[ "$(directoryExists "${wasInstallDir}")" == "true" ]]; then
    "${scriptDir}/stopNodeagents.sh"
fi

# Stop WAS Deployment Manager
if [[ "$(directoryExists "${wasDmgrProfile}")" == "true" ]]; then
    "${scriptDir}/stopDmgr.sh"
fi

# Stop IHS Admin
if [[ "$(directoryExists "${ihsInstallDir}")" == "true" ]]; then
    "${scriptDir}/stopIHSAdmin.sh"
fi

# Stop IHS
if [[ "$(directoryExists "${ihsInstallDir}")" == "true" ]]; then
    "${scriptDir}/stopIHS.sh"
fi

# Stop Solr
if [[ "$(directoryExists "${solrInstallDir}")" == "true" ]]; then
    "${scriptDir}/stopSolr.sh"
fi

# Stop DB2
if [[ "$(directoryExists "${db2InstallDir}")" == "true" ]]; then
    "${scriptDir}/stopDB2.sh"
fi

# Stop Pink components
