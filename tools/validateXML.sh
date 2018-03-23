#!/bin/bash
# validateXML.sh: Validate Connections XML files against their corresponding XSDs

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {

    # Make sure we're running as root
    checkForRoot

    # Verify commands are available
    type -a xmllint > /dev/null 2>&1; result=${?}
    if [[ ${result} != 0 ]]; then
        log "The xmllint command is required to run this script"
        exit 1
    fi 

    # Ensure the user supplied the file to validate
    xmlFile="${1}"
    if [[ -z "${xmlFile}" ]]; then
        log "Usage: sudo validateXML.sh XML_FILE"
        exit 1
    else
        directory="$(dirname "${xmlFile}")"
        file="$(basename "${xmlFile}")"
        base="${file%.*}"
        xsdFile="${directory}/${base}.xsd"
    fi 
}

init "${1}"

xmllint -schema "${xsdFile}" "${xmlFile}" --noout
