#! /bin/bash

function usage() {

    log "Usage: sudo getAppRoles.sh [APP]"

}

function init() {

    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Variables
    local spacesPlusAlnum="[[:blank:]]+[[:alnum:]]"
    app="${1}"
    string=""

    string+="^Application:${spacesPlusAlnum}|"
    string+="^Role:${spacesPlusAlnum}|"
    string+="^Everyone?:${spacesPlusAlnum}|"
    string+="^All authenticated?:${spacesPlusAlnum}|"
    string+="^Mapped users:${spacesPlusAlnum}|"
    string+="^Mapped groups:${spacesPlusAlnum}|"
    string+="^All authenticated in trusted realms?:${spacesPlusAlnum}|"
    string+="^Mapped users access ids:${spacesPlusAlnum}|"
    string+="^Mapped groups access ids:${spacesPlusAlnum}|"
    string+="================================================================================"

}

init "${@}"

if [[ -z "${app}" ]]; then
    # No app was specified, so get all apps
    output=$("${scriptDir}/wsadmin.sh" "${scriptDir}/wsadmin/getAppRoles.py")
else
    # Only get the specified app
    output=$("${scriptDir}/wsadmin.sh" "${scriptDir}/wsadmin/getAppRoles.py" "${app}")
fi

# Extract only the relevant lines
output=$(echo "${output}" | grep -E "${string}")

# If the output only contains the application name, it means that application doesn't exist 
if [[ $(echo "${output}" | wc -l) == 1 ]]; then
    log "$(echo ${output} | tr -d ':') does not exist"
else
    echo "${output}" | sed 's/\(^Everyone*\|^All authenticated*\|^Mapped*\)/       \1/g'
fi
