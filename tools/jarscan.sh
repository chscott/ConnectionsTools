#! /bin/bash

string="${1}"

if [ -z "${string}" ]; then
    printf "No string supplied. Exiting.\n"
    exit 1
else
    printf "Searching JARs in $(pwd) for '${string}'...\n"
    originalIFS=${IFS}
    IFS=$'\n'
    find . -iname "*.jar" -print | while read -r jar; do
        unzip -c "${jar}" | grep -q -i "${string}"
    done
    IFS=${originalIFS}

fi
