#!/bin/bash
# getPodName.sh: Return the pod name for the Nth pod matching the provided string 

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {

    checkForRoot
    checkForK8s

    # Get the pod match string (required)
    if [[ -z "${1}" ]]; then
        log "Usage: getPodName.sh POD_STRING [POD_NUMBER]"
        exit 1
    else
        podString="${1}"
    fi 

    # Get the pod number (optional)
    if [[ ! -z ${2} && ${2} =~ ^[0-9]+$ ]]; then
        podNumber=${2} 
    else
        podNumber=1
    fi

}

init "${@}"

"${scriptDir}/getPodInfo.sh" --all | \
    grep -m ${podNumber} "${podString}" | \
    tail -n 1 | \
    awk '{print $1}' 
