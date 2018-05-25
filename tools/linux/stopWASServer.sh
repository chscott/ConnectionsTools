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

# Only stop servers that are in the cell but not of type webserver (since webservers aren't stopped the same way)
if [[ "$(isServerInWASCell "${server}" "${profile}")" == "true" && "$(isWASWebserver "${server}" "${profile}")" == "false" ]]; then
    stopWASServer "${server}" "${wasProfileRoot}/${profile}"
elif [[ "$(isServerInWASCell "${server}" "${profile}")" == "false" ]]; then
    log "Error: ${server} is not in WAS cell ${wasCellName}"
elif [[ "$(isWASWebserver "${server}" "${profile}")" == "true" ]]; then
    log "Error: ${server} is a webserver. Start IHS using startIHS.sh"
fi
