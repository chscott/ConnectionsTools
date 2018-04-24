#!/bin/bash
# getPodInfo.sh: Print pod information with optional format

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function usage() {

    log "Usage: sudo getPodInfo.sh POD_NAME|--all [--json|--wide]"
    log ""
    log "Examples:"
    log ""
    log "Get the info for all pods:"
    log "$ sudo getPodInfo.sh --all"
    log ""
    log "Get the info for all pods in JSON format:"
    log "$ sudo getPodInfo.sh --all --json"
    log ""
    log "Get the info for a pod named foo:"
    log "$ sudo getPodInfo.sh foo"
    log ""
    log "Get the info for a pod named foo in JSON format:"
    log "$ sudo getPodInfo.sh foo --json"

}

function init() {

    checkForRoot
    checkForK8s

    # Verify ictools.conf data is available
    if [[ -z "${icNamespace}" ]]; then
        log "The icNamespace variable must be set in /etc/ictools.conf"
        exit 1
    fi 

    # Get the pod name or the special '--all' (required)
    if [[ -z "${1}" ]]; then
        usage
        exit 1
    else
        pod="${1}"
    fi

    # Get the format (optional) 
    if [[ ! -z "${2}" ]]; then
        format="${2}" 
        if [[ "${format}" != "--json" && "${format}" != "--wide" ]]; then
            log "Unrecognized format ${format}. Using wide format..."
            format="--wide"
        fi
        format=$(echo ${format} | tr -d "-")
    fi

}

init "${@}"

# Get the pod info
if [[ "${pod}" == "--all" ]]; then
    "${kubectl}" get pods --namespace "${icNamespace}" --output "${format}"
else
    "${kubectl}" get pod --namespace "${icNamespace}" --output "${format}" "${pod}"
fi
