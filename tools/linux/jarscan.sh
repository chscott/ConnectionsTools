#! /bin/bash

function init() {

    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # If one argument is provided, it is the string to search for (in the current directory). If two, it is the directory ($1) and string ($2)
    if [[ ${#} == 1 ]]; then
        path=$(pwd)
        string="${1}"
    elif [[ ${#} == 2 ]]; then
        path="${1}"
        string="${2}"
    fi

}

init "${@}"

if [ -z "${string}" ]; then
    log "No search string supplied. Exiting."
    exit 1
else
    log "Searching JARs in ${path} for '${string}'..."
    find -H "${path}" -name '*.jar' -printf "test ! -d \"%p\" && unzip -c \"%p\" | grep -q \"${string}\" && echo %p\n" | sh
fi
