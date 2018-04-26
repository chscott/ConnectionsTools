#!/bin/bash

function usage() {

    log "Usage: sudo getContainerID.sh POD_NAME"

}

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Make sure this is a Kubernetes node
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
