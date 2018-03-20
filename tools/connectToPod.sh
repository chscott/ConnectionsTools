#!/bin/bash

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${scriptDir}/utils.sh"

# Is this running interactively?
if [ -t 0 ]; then
    # No, so get the pod name from $1 
    if [ -z ${1} ]; then
        printf '%s\n' 'No pod specified'
        exit 1
    else
        pod="${1}"
        ${kubectl} attach --namespace ${icNamespace} -it "${pod}"
    fi
else
    # Yes, so get the pod name from stdin
    pod="$(cat -)"
    ${kubectl} attach --namespace ${icNamespace} -it "${pod}"
fi
