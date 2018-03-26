#!/bin/bash
# getContainerID: Print a pod's container ID

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function usage() {

    log "Usage: ? sudo getContainerID.sh POD_NAME"

}

function init() {

    checkForRoot
    checkForK8s

    # Get the pod name (required)
    if [[ -z "${1}" ]]; then
        usage
        exit 1
    else
        pod="${1}"
    fi
    
}

init "${@}"

# Get the container ID
"${scriptDir}/getPodInfo.sh" "${pod}" --json | \
    grep -m 1 "containerID" | \
    awk -F "docker://" '{print $2}' | \
    tr -d '\",' \
