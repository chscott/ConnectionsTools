#!/bin/bash
# getPodLogs.sh: Print the logs from the pod

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {

    checkForRoot

    # Is this running interactively?
    if [[ -t 0 ]]; then
        # No, so get the pod name from $1 
        if [[ -z "${1}" ]]; then
            log "Usage: sudo getPodLogs.sh POD_NAME"
            exit 1
        else
            pod="${1}"
        fi
    else
        # Yes, so get the pod name from stdin
        pod="$(cat -)"
    fi

}

init "${@}"

"${kubectl}" logs --namespace "${icNamespace}" -it "${pod}"
