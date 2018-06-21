#!/bin/bash

function usage() {

    log "Usage: sudo setPodLogLevels.sh POD_TYPE LOG_LEVEL"
    log "Valid log levels (increasing verbosity): fatal, error, warn, info, debug, trace, verbose, silly"

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

    # Verify ictools.conf data is available
    if [[ -z "${icNamespace}" ]]; then
        log "The icNamespace variable must be set in /etc/ictools.conf"
        exit 1
    fi 

    # Valid log levels
    logLevels=("fatal" "error" "warn" "info" "debug" "trace" "verbose" "silly") 

    # Get the pod type and new log level
    if [[ -z "${1}" || -z "${2}" ]]; then
        usage
        exit 1
    else
        deployment="${1}"
        # container name should be the same as the deployment
        container="${deployment}"
        newLogLevel="${2}"
        # Verify that the user provided a valid log level
        validLogLevel="false"
        for logLevel in "${logLevels[@]}"; do
            if [[ "${logLevel}" == "${newLogLevel}" ]]; then
                validLogLevel="true"
            fi
        done
        if [[ "${validLogLevel}" == "false" ]]; then
            log "${newLogLevel} is not a valid log level"
            usage
            exit 1
        fi
    fi

    # Build the patch string
    patch=""
    patch+='{ '
    patch+='"spec": { '
    patch+='"template": { '
    patch+='"spec": { '
    patch+='"containers": [{ '
    patch+="\"name\": \"${container}\", "
    patch+='"env": [{ '
    patch+="\"name\": \"LOG_LEVEL\", \"value\":\"${newLogLevel}\" "
    patch+=' }]'
    patch+=' }]'
    patch+=' }'
    patch+=' }'
    patch+=' }'
    patch+=' }'

}

init "${@}"

output="$("${kubectl}" --namespace "${icNamespace}" patch deployment "${deployment}" -p "${patch}" 2>&1)"

if [[ ${?} == 0 ]]; then
    log "Log level changed to ${newLogLevel} in ${deployment}. The pods will now restart. Use getPodInfo.sh --all to monitor status."
else
    log "Failed to change log level in ${deployment}. Error message:"
    log "Output: ${output}"
fi
