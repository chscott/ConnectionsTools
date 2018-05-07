#! /bin/bash

function init() {

    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Variables
    string="${1}"

}

init "${@}"

if [ -z "${string}" ]; then
    log "No search string supplied. Exiting."
    exit 1
else
    log "Searching JARs in $(pwd) for '${string}'..."
    find . -name '*.jar' -printf "test ! -d \"%p\" && unzip -c \"%p\" | grep -q \"${string}\" && echo %p\n" | sh
fi
