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
        key="${1}"
        case "${key}" in
            --profile)
                profile="${2}"
                shift;shift;;
            --server)
                server="${2}"
                shift;shift;;
            *)
                log "Unrecognized argument ${1}"
                shift;;
        esac
    done

}

init "${@}"

# Stop WAS server
stopWASServer "${server}" "${wasProfileRoot}/${profile}"
