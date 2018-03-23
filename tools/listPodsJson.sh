#!/bin/bash
# listPodsJson.sh: Print the pod info in JSON format

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {
    
    checkForRoot

}

init

"${kubectl}" get pods --namespace "${icNamespace}" --output json
