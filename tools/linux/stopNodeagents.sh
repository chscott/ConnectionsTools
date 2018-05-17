#!/bin/bash

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

}

init "${@}"

# Build an array of WAS profiles
cd "${wasProfileRoot}"
profiles=($(ls -d *))

# For each profile...
for profile in "${profiles[@]}"; do

    # Determine the profile type
    profileKey="${wasProfileRoot}/${profile}/properties/profileKey.metadata"
    if [[ -f "${profileKey}" ]]; then
        profileType=$(getWASProfileType "${profileKey}")
    fi

    # Only need to continue if the profile type is BASE
    if [[ "${profileType}" == "BASE" ]]; then

        # Build an array of servers known to this cell
        cellServers=($( \
            find "${wasProfileRoot}/${profile}/config/cells/${wasCellName}/nodes" -name "serverindex.xml" -print 2>/dev/null | \
            xargs grep "serverName" | \
            awk -F 'serverName=' '{print $2}' | \
            awk '{print $1}' | \
            tr -d '"' | \
            sort | \
            uniq \
        )) 

        # Change to the servers directory so we can get an array of servers that exist in this profile
        cd "${wasProfileRoot}/${profile}/servers" 2>/dev/null

        # If there is no servers directory, skip it 
        if [[ ${?} == 0 ]]; then
            # Get an array of servers (only named "nodeagent")
            profileServers=($(ls -d * | grep "nodeagent")) 
            # Loop through the profile servers
            for profileServer in "${profileServers[@]}"; do
                # Verify that this server exists in the cell
                for cellServer in "${cellServers[@]}"; do
                    if [[ "${cellServer}" == "${profileServer}" ]]; then
                        # We have a match, so go ahead and stop it
                        stopWASServer "${profileServer}" "${wasProfileRoot}/${profile}"
                    fi
                done
            done
        fi

    fi

done
