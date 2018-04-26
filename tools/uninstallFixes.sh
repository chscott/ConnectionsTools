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

    # Get the fixes to uninstall
    fixes=""
    while [[ ${#} -gt 0 ]]; do
        fixes="${fixes} ${1}"
        shift
    done

    # Make sure fixes to uninstall were specified
    if [[ -z "${fixes}" ]]; then
        log "No fixes specified"
        log "Usage: uninstallFixes.sh fix1 [fix2] [fixN]..."
        exit 1
    fi

    # See if the Deployment Manager is available
    status=$(isDmgrAvailable)
    if [[ ${status} != 0 ]]; then
        log "The Deployment Manager must be running to install fixes"
        exit 1
    fi

    # Must change to the updateInstall directory or WAS_HOME will be reset
    cd "${icInstallDir}/updateInstaller"

}

init "${@}"

printf "${left2Column}" "Uninstalling Connections fixes..."

# Uninstall the fixes
# The ${fixes} variable must be unquoted or entire string will be considered one fix
"./updateSilent.sh" \
    "-installDir" "${icInstallDir}" \
    "-fix" \
    "-uninstall" \
    "-fixDir" "${icFixesDir}" \
    "-fixes" ${fixes} \
    "-featureCustomizationBackedUp" "yes" \
    "-wasUserId" "${wasAdmin}" \
    "-wasPassword" "${wasAdminPwd}" \
    >/dev/null 2>&1

# Print status
if [[ ${?} == 0 ]]; then
    printf "${right2Column}" "${greenText}SUCCESS${normalText}"
else
    printf "${right2Column}" "${redText}FAILURE${normalText}"
fi
