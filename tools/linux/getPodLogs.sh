#!/bin/bash

function usage() {

    log "Usage: sudo getPodLogs.sh POD_NAME [--monitor|--print]"

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
    
    # Get the mode (optional) 
    if [[ ! -z "${2}" ]]; then
        mode="${2}" 
        if [[ "${mode}" != "--monitor" && "${mode}" != "--print" ]]; then
            log "Unrecognized mode ${mode}. Printing logs..."
            mode="--print"
        fi
    fi

}

init "${@}"

# Get the logs
if [[ "${mode}" == "--monitor" ]]; then
    # Monitor mode (stream current logs to stdout)
    "${kubectl}" logs --namespace "${icNamespace}" --follow "${pod}"
else
    # Non-monitor mode (print current logs to stdout)
    "${kubectl}" logs --namespace "${icNamespace}" "${pod}"

    # Get the container ID so we can see if there are rotated logs
    containerID="$("${scriptDir}/getContainerID.sh" "${pod}")"

    if [[ -d "${dockerContainerDir}/${containerID}" ]]; then
        #log "Current logs are printed above. Check ${dockerContainerDir}/${containerID} for rotated logs."
        rotatedLogs=("$(find "${dockerContainerDir}/${containerID}" -name "*.log*" -exec basename {} \;)")
        log "Current logs are printed above. No output means the logs have been rotated." 
        log "The following rotated logs are available in ${dockerContainerDir}/${containerID}:"
        for rotatedLog in "${rotatedLogs[@]}"; do
            log "${rotatedLog}"
        done
    else
        log "Current logs are printed above. No output means the logs have been rotated." 
        log "This pod's container exists on another node. Be sure to run this command there to check for rotated logs."
    fi
fi
