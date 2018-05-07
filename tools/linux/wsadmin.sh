#! /bin/bash

function init() {

    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Make sure we're on the Deployment Manager
    checkForDmgr

    # Variables
    script="${1}"

    # Clear $1 so the remaining args can be passed to wsadmin
    shift;

    # Change directory to the Deployment Manager bin directory
    cd "${wasDmgrProfile}/bin"

}

init "${@}"

if [ -z "${script}" ]; then
    # No script provided, so just start a wsadmin shell    
    "${wasDmgrProfile}/bin/wsadmin.sh" -lang "jython" -user "${wasAdmin}" -password "${wasAdminPwd}" 
else
    # Run wsadmin with the script as input
    "${wasDmgrProfile}/bin/wsadmin.sh" -lang "jython" -user "${wasAdmin}" -password "${wasAdminPwd}" -f "${script}" "${@}"
fi
