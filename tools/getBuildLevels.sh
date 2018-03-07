#!/bin/bash

dmgrAppsDir=/var/IBM/websphere/was/profiles/dmgr/config/cells/icCell/applications
excludes=(
    commsvc.ear
    DefaultApplication.ear
    ibmasyncrsp.ear
    isclite.ear
    ivtApp.ear
    OTiS.ear
    query.ear
    WebSphereOauth20SP.ear
    WebSphereWSDM.ear
)
notAvailable='Data missing from manifest'

# Keep track of the EARs as we are processing them
currentEar=''
earCounter=0

# Get all manifest files and loop through them
find ${dmgrAppsDir} -name MANIFEST.MF -print0 | \
while IFS= read -r -d '' file; do

    # Get the EAR file 
    ear=$(echo "${file}" | cut -d / -f12)

    # Get the module path
    module=$(echo "${file}" | cut -d / -f14- | awk -F / '{$1=$NF=$(NF-1)="";print $0}' | tr -d '[:blank:]')

    # Check to see if the current module is in the exclude array (skip if it is)
    skipManifest=false
    for exclude in "${excludes[@]}"; do
        if [ "${exclude}" = "${ear}" ]; then
            skipManifest=true
        fi
    done
    if [ ${skipManifest} = 'true' ]; then
        continue
    fi

    # Update the currentEar, if necessary
    if [ "${ear}" != "${currentEar}" ]; then
        printf '================================================\n'
        currentEar="${ear}"
        earCounter=0
    else
        earCounter=$((++earCounter))
    fi

    # Print the EAR name only if it's the first pass for that EAR
    if [ ${earCounter} -eq 0 ]; then
        printf '%-10s %-s\n' 'EAR:' "${ear}"
    fi

    # Get the title from the manifest
    title=$(grep 'Implementation-Title' "${file}" | awk -F ': ' '{print $2}')
    if [[ -z ${title} ]]; then
        title=${notAvailable}
    fi

    # Get the version from the manifest
    version=$(grep 'Implementation-Version' "${file}" | awk -F ': ' '{print $2}')
    if [[ -z ${version} ]]; then
        version=${notAvailable}
    fi

    # Print the module name
    if [[ -z ${module} ]]; then
        printf '\n%-10s %-s\n' 'Module:' "${ear}"
    else
        printf '\n%-10s %-s\n' 'Module:' "${module}"
    fi
    
    # Print the title 
    printf '%-10s %-s\n' 'Title:' "${title}"

    # Print the version
    printf '%-10s %-s\n' 'Version:' "${version}"

done
