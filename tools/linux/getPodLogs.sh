#!/bin/bash

function usage() {

    log "Usage: sudo getPodLogs.sh POD_NAME | POD_TYPE [--monitor | --print | --monitorAll | --printAll]"

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

    # Get the pod name/type (required)
    if [[ -z "${1}" ]]; then
        usage
        exit 1
    else
        pod="${1}"
        "${scriptDir}/getPodInfo.sh" --all | grep "${pod}" >/dev/null 2>&1
        if [[ ${?} != 0 ]]; then
            log "${pod} is not a valid pod name or type"
            exit 1
        fi
    fi
    
    # Get the mode (optional) 
    if [[ ! -z "${2}" ]]; then
        mode="${2}" 
        if [[ "${mode}" != "--monitor" && "${mode}" != "--monitorAll" && "${mode}" != "--print" && "${mode}" != "--printAll" ]]; then
            log "Unrecognized mode ${mode}. Printing logs..."
            mode="--print"
        fi
    fi

}

function getRotatedLogs() {

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

}

init "${@}"

# Get the logs
if [[ "${mode}" == "--monitor" ]]; then
    # Monitor mode (stream current logs to stdout for specified pod)
    "${kubectl}" logs --namespace "${icNamespace}" --timestamps=true --follow "${pod}"
elif [[ "${mode}" == "--monitorAll" ]]; then
    # Monitor all mode (stream current logs from all pods to stdout)
    trap 'kill $(jobs -p)' EXIT
    pods=($("${scriptDir}/getPodInfo.sh" --all | grep "${pod}" | awk '{print $1}')) 
    for pod in "${pods[@]}"; do
        log "Monitoring logs in pod ${pod}..."
        "${kubectl}" logs --namespace "${icNamespace}" --timestamps=true --follow "${pod}" &
    done
    wait
elif [[ "${mode}" == "--printAll" ]]; then
    # Non-monitor mode (print current logs from all pods to stdout)
    pods=($("${scriptDir}/getPodInfo.sh" --all | grep "${pod}" | awk '{print $1}')) 
    for pod in "${pods[@]}"; do
        log "Printing logs in pod ${pod}..."
        "${kubectl}" logs --namespace "${icNamespace}" --timestamps=true "${pod}"
        getRotatedLogs
    done
else
    # Default: Non-monitor mode (print current logs to stdout for specified pod)
    log "Printing logs in pod ${pod}"
    "${kubectl}" logs --namespace "${icNamespace}" --timestamps=true "${pod}"
    getRotatedLogs
fi
