#!/bin/bash

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Process the user arguments
    while [[ ${#} -gt 0 ]]; do
        local key="${1}"
        local value="${2}"
        case "${key}" in
            --profile)
                profile="${value}"
                shift;shift;;
            --server)
                server="${value}"
                shift;shift;;
            *)
                log "Unrecognized argument ${key}"
                shift;;
        esac
    done

}

init "${@}"

# Determine the profile type
profileKey="${wasProfileRoot}/${profile}/properties/profileKey.metadata"
if [[ -f "${profileKey}" ]]; then
    profileType=$(getWASProfileType "${profileKey}")
fi

# Take appropriate action based on profile type
if [[ "${profileType}" == "DEPLOYMENT_MANAGER" ]]; then
    # Deployment manager profiles have no nodeagent, so just start the server directly
    startWASServer "${server}" "${wasProfileRoot}/${profile}"
elif [[ "${profileType}" == "BASE" ]]; then
    if [[ "${server}" == "nodeagent" ]]; then
        # Admin just wants to start the nodeagent, so only do that
        startWASServer "nodeagent" "${wasProfileRoot}/${profile}"
    else
        # Admin wants to start the app server, so start the nodeagent first
        startWASServer "nodeagent" "${wasProfileRoot}/${profile}"
        startWASServer "${server}" "${wasProfileRoot}/${profile}"
    fi
fi
