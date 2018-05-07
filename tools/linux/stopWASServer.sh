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

# Stop WAS server
stopWASServer "${server}" "${wasProfileRoot}/${profile}"
