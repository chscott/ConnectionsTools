#!/bin/bash
# getPodName.sh: Return the pod name for the Nth pod matching the provided string 

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {

    checkForRoot

    # Make sure the user provided a string to match pods
    if [[ -z "${1}" ]]; then
        log "Usage: getPodName.sh POD_STRING [POD_NUMBER]"
        exit 1
    else
        podString="${1}"
    fi 

    # See if the user wants a particular pod
    if [[ ! -z ${2} && ${2} =~ ^[0-9]+$ ]]; then
        podNumber=${2} 
    else
        podNumber=1
    fi

}

init "${@}"

"${scriptDir}/listPods.sh" | \
    grep -m ${podNumber} "${podString}" | \
    tail -n 1 | \
    awk '{print $1}' 
