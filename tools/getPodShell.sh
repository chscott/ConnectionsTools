#!/bin/bash
# getPodShell.sh: Run a shell in the specified pod

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {

    checkForRoot
    checkForK8s

    # Get the pod name (required)
    if [[ -z "${1}" ]]; then
        log "Usage: sudo getPodShell.sh POD_NAME"
        exit 1
    else
        pod="${1}"
    fi

}

init "${@}"

"${kubectl}" exec --namespace "${icNamespace}" -it "${pod}" -- /bin/sh
