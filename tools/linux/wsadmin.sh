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

    # See if the Deployment Manager is available
    status=$(isDmgrAvailable)
    if [[ ${status} != 0 ]]; then
        log "The Deployment Manager must be running to launch wsadmin" 
        exit 1
    fi

    # Get the full path of the provided file (needed since we cd to the Deployment Manager bin directory later)
    if [[ ! -z "${1}" && -f "${1}" ]]; then
        script="$(cd "$(dirname "${1}")" && pwd)/$(basename "${1}")"
        # Clear $1 so the remaining args can be passed to wsadmin
        shift;
        args=("${@}")
    elif [[ ! -z "${1}" && ! -f "${1}" ]]; then
        log "${1}: No such file or directory"
        exit 1
    fi

    # Change directory to the Deployment Manager bin directory
    cd "${wasDmgrProfile}/bin"

}

init "${@}"

if [[ -z "${script}" ]]; then
    # No script provided, so just start a wsadmin shell    
    "${wasDmgrProfile}/bin/wsadmin.sh" -lang "jython" -user "${wasAdmin}" -password "${wasAdminPwd}" 
elif [[ -z "${args}" ]]; then
    # No argments provided, so just run wsadmin with the script as input
    "${wasDmgrProfile}/bin/wsadmin.sh" -lang "jython" -user "${wasAdmin}" -password "${wasAdminPwd}" -f "${script}"
else
    # Run wsadmin with the script as input and pass the additional arguments
    "${wasDmgrProfile}/bin/wsadmin.sh" -lang "jython" -user "${wasAdmin}" -password "${wasAdminPwd}" -f "${script}" "${args[@]}"
fi
