#!/bin/bash

function init() {

    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Make sure this is a Deployment Manager node
    checkForDmgr

    # Verify ictools.conf data is available
    if [[ -z "${wasDmgrProfile}" || -z "${wasCellName}" ]]; then
        log "The wasDmgrProfile and wasCellName variables must be set in /etc/ictools.conf"
        exit 1
    fi 

    notAvailable="${redText}Data missing from manifest${normalText}"
    # Add any apps to this list that you want to ignore. Generally, that means non-Connections apps
    excludes=(
        "commsvc"
        "DefaultApplication"
        "ibmasyncrsp"
        "isclite"
        "ivtApp"
        "OTiS"
        "query"
        "WebSphereOauth20SP"
        "WebSphereWSDM"
    )

}

init "${@}"

# Keep track of the Apps as we are processing them
currentApp=""
appCounter=0

# Get all manifest files and loop through them
find "${wasDmgrProfile}/config/cells/${wasCellName}/applications" -name "MANIFEST.MF" -print0 | \
while IFS= read -r -d '' file; do

    # Get the app
    app=$(echo "${file}" | sed -n 's|.*applications\/\(.*\).ear\/deployments.*|\1|p')

    # Check to see if the App is in the exclude array (skip if it is)
    for exclude in "${excludes[@]}"; do
        if [[ "${exclude}" == "${app}" ]]; then
            continue 2
        fi
    done

    # Get the module
    module=$(echo "${file}" | awk -F "/" '{print $(NF-2)}')

    # Check if we found the module for the App itself and give it a more friendly name
    if [[ "${module}" == "${app}" ]]; then
        module="${module}.ear"
    fi

    # Update the currentApp, if necessary
    if [[ "${app}" != "${currentApp}" ]]; then
        log "${separator}"
        currentApp="${app}"
        appCounter=0
    else
        appCounter=$((++appCounter))
    fi

    # Print the App name only if it's the first pass for that App
    if [[ ${appCounter} == 0 ]]; then
        printf '%-10s %-s\n' 'App:' "${app}"
    fi

    # Get the title from the manifest
    title=$(grep "Implementation-Title" "${file}" | awk -F ": " '{print $2}')
    if [[ -z "${title}" ]]; then
        title="${notAvailable}"
    fi

    # Get the version from the manifest
    version=$(grep "Implementation-Version" "${file}" | awk -F ": " '{print $2}')
    if [[ -z "${version}" ]]; then
        version="${notAvailable}"
    fi

    # Print the module name
    if [[ -z "${module}" ]]; then
        printf "\n%-10s %-s\n" "Module:" "${app}"
    else
        printf "\n%-10s %-s\n" "Module:" "${module}"
    fi
    
    # Print the title 
    printf "%-10s %-s\n" "Title:" "${title}"

    # Print the version
    printf "%-10s %-s\n" "Version:" "${version}"

done
