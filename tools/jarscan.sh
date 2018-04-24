#! /bin/bash

# Source prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

string="${1}"

if [ -z "${string}" ]; then
    log "No search string supplied. Exiting."
    exit 1
else
    log "Searching JARs in $(pwd) for '${string}'..."
    find . -name '*.jar' -printf "test ! -d \"%p\" && unzip -c \"%p\" | grep -q \"${string}\" && echo %p\n" | sh
    #files=($(find . -name '*.jar'))
    #for file in "${files[@]}"; do
    #    if [[ ! -d "${file}" ]]; then
    #        unzip -c "${file}" | grep -q "${string}"
    #    fi
    #done
fi
