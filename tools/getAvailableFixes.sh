#!/bin/bash
# getAvailableFixes.sh: Print a list of available but uninstalled fixes

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {

    checkForRoot
    checkForDmgr

    # Verify ictools.conf data is available
    if [[ -z "${wasDmgrProfile}" || -z "${icInstallDir}" || -z "${icFixesDir}" ]]; then
        log "The wasDmgrProfile, icInstallDir and icFixesDir variables must be set in /etc/ictools.conf"
        exit 1
    fi 

    # Set JAVA_HOME
    . "${wasDmgrProfile}/bin/setupCmdLine.sh"

    # Must change to the updateInstall directory or WAS_HOME will be reset
    cd "${icInstallDir}/updateInstaller"

    log "Getting a list of Connections fixes available to install..."

}

init

# See which fixes have already been installed
installedFixes=($( \
    "./updateSilent.sh" "-fix" "-installDir" "${icInstallDir}" | \
    grep "Fix name:" | \
    awk -F ": " '{print $2}' | \
    sort \
))

# See which fixes are available in the fixes directory
availableFixes=($(
    "./updateSilent.sh" "-fix" "-installDir" "${icInstallDir}" "-fixDir" "${icFixesDir}" | \
    grep -E "^\[[0-9]\]" | \
    awk '{print $2}' | \
    sort | \
    sed "N;s|\n| |" | \
    tr -d "," \
))

# Filter out the fixes that are both available and already installed. The remainder are the ones available to install
availableToInstallFixes=""
for availableFix in "${availableFixes[@]}"; do
    alreadyInstalled="false"
    for installedFix in "${installedFixes[@]}"; do
        if [[ "${installedFix}" == "${availableFix}" ]]; then
            alreadyInstalled="true" 
        fi
    done
    if [[ "${alreadyInstalled}" == "false" ]]; then
    availableToInstallFixes+="${availableFix} "
    fi
done

if [[ -z "${availableToInstallFixes}" ]]; then
    log "There are no fixes available to install"
else
    log "Fixes available to install: ${availableToInstallFixes}"
fi
