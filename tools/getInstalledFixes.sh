#!/bin/bash

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"
    . "${wasDmgrProfile}/bin/setupCmdLine.sh"

    # Make sure we're running as root
    checkForRoot

    # Make sure this is a Deployment Manager node
    checkForDmgr

    # Must change to the updateInstall directory or WAS_HOME will be reset
    cd "${icInstallDir}/updateInstaller"

}

init "${@}"

# Get an array of installed fixes 
installedFixes=($( \
    "./updateSilent.sh" "-fix" "-installDir" "${icInstallDir}" | \
    grep "Fix name:" | \
    awk -F ": " '{print $2}' | \
    sort \
)) 

log "Installed Connections fixes:"

# For each installed fix, get details from the Connections efix files
for fix in "${installedFixes[@]}"; do
    description=$(grep "short-description" "${icInstallDir}/version/${fix}.efix" | awk -F = '{print $2}' | tr -d "[<>\"]") 
    version=$(grep "build-version" "${icInstallDir}/version/${fix}.efix" | awk -F = '{print $2}' | tr -d "[<>\"]") 
    date=$(grep "build-date" "${icInstallDir}/version/${fix}.efix" | awk -F = '{print $2}' | tr -d "[<>\"]") 
    log "${separator}"
    printf "%-12s %-s\n" "Fix ID:" "${fix}"
    printf "%-12s %-s\n" "Description:" "${description}"
    printf "%-12s %-s\n" "Version:" "${version}"
    printf "%-12s %-s\n" "Date:" "${date}"
done

log "${separator}"
