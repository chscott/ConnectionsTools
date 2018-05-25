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

# Only start servers that are in the cell but not of type webserver (since webservers aren't started the same way)
if [[ "$(isServerInWASCell "${server}" "${profile}")" == "true" && "$(isWASWebserver "${server}" "${profile}")" == "false" ]]; then
    if [[ "$(isWASDmgrProfile "${profile}")" == "true" ]]; then
        startWASServer "${server}" "${wasProfileRoot}/${profile}"
    elif [[ "$(isWASBaseProfile "${profile}")" == "true" ]]; then
        if [[ "${server}" == "nodeagent" ]]; then
            startWASServer "nodeagent" "${wasProfileRoot}/${profile}"
        else
            # Admin wants to start the app server, so start the nodeagent first
            startWASServer "nodeagent" "${wasProfileRoot}/${profile}"
            startWASServer "${server}" "${wasProfileRoot}/${profile}"
        fi
    fi
elif [[ "$(isServerInWASCell "${server}" "${profile}")" == "false" ]]; then
    log "Error: ${server} is not in WAS cell ${wasCellName}"
elif [[ "$(isWASWebserver "${server}" "${profile}")" == "true" ]]; then
    log "Error: ${server} is a webserver. Start IHS using startIHS.sh"
fi
