#!/bin/bash

function init() {

    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # See if the Deployment Manager is available
    status=$(isDmgrAvailable)
    if [[ ${status} != 0 ]]; then
        log "The Deployment Manager must be running to sync nodes" 
        exit 1
    fi

    # Variables
    local mode="${1}"

    # See which mode was requested
    if [[ "${mode}" == "--offline" ]]; then
        doOfflineSync="true"
        # Offline mode requires an array of WAS profiles from the local system
        cd "${wasProfileRoot}"
        profiles=($(ls -d *))
    else
        doOfflineSync="false"
        # Online mode can only run on the Deployment Manager
        checkForDmgr
    fi

}

function onlineSync() {

    printf "${left2Column}" "Synchronizing active nodes..."

    # Call wsadmin with the syncNodes.py script to perform online sync
    "${scriptDir}/wsadmin.sh" "${scriptDir}/wsadmin/syncNodes.py" >/dev/null 2>&1
 
    # Report status
    if [[ ${?} == 0 ]]; then
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    else
        printf "${right2Column}" "${redText}FAILURE${normalText}"
    fi

}

function offlineSync() {

    # Sync the nodes
    for profile in "${profiles[@]}"; do

        # Determine the profile type
        profileKey="${wasProfileRoot}/${profile}/properties/profileKey.metadata"
        if [[ -f "${profileKey}" ]]; then
            profileType=$(getWASProfileType "${profileKey}")
        fi

        if [[ "${profileType}" == "BASE" ]]; then

            # Change to the servers directory so we can get an array of servers from the subdirectories
            cd "${wasProfileRoot}/${profile}/servers" >/dev/null 2>&1

            # If there is no servers directory, skip it 
            if [[ ${?} == 0 ]]; then

                # Get an array of servers
                servers=($(ls -d *)) 

                # Make sure all servers are stopped
                areAllServersStopped="true"
                for server in "${servers[@]}"; do
                    status=$(getWASServerStatus "${server}" "${wasProfileRoot}/${profile}" "true")
                    if [[ "${status}" != "STOPPED" ]]; then
                        areAllServersStopped="false"
                    fi
                done

                printf "${left2Column}" "Synchronizing servers in ${profile} profile..."
            
                # Try the sync if all servers are stopped
                if [[ "${areAllServersStopped}" == "true" ]]; then
                    "${wasProfileRoot}/${profile}/bin/syncNode.sh" "${wasDmgrHost}" "-user" "${wasAdmin}" "-password" "${wasAdminPwd}" >/dev/null 2>&1
                    # Log status
                    if [[ ${?} == 0 ]]; then
                        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
                    else
                        printf "${right2Column}" "${redText}FAILURE${normalText}"
                    fi
                else
                   printf "${right2Column}" "${redText}FAILURE${normalText} (At least one server is still running)"
                fi

            fi

        fi

    done

}

init "${@}"

# Do the requested sync
if [[ "${doOfflineSync}" == true ]]; then
    offlineSync
else
    onlineSync
fi
