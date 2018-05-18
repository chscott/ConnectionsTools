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

    mode="${1}"

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

    # Build an array of WAS profiles
    cd "${wasProfileRoot}" 2>/dev/null
    local profiles=($(ls -d * 2>/dev/null))

    # For each profile... 
    for profile in "${profiles[@]}"; do

        # Only need to continue if the profile type is BASE
        if [[ "$(isWASBaseProfile "${profile}")" == "true" ]]; then

            # Test if the servers directory exists and contains at least one subdirectory 
            cd "${wasProfileRoot}/${profile}/servers" 2>/dev/null && ls -d * >/dev/null 2>&1

            # If there is no servers directory or there are no subdirectories, skip this profile 
            if [[ ${?} != 0 ]]; then
                continue
            else
                # Get an array of servers
                local servers=($(ls -d * 2>/dev/null))

                # Make sure all servers are 1) part of the WAS cell and 2) stopped
                local areAllServersInCell="true"
                local areAllServersStopped="true"
                for server in "${servers[@]}"; do
                    if [[ "$(isServerInWASCell "${server}" "${profile}")" == "false" ]]; then
                        areAllServersInCell="false"
                    fi
                    if [[ "$(getWASServerStatus "${server}" "${wasProfileRoot}/${profile}" "true")" != "STOPPED" ]]; then
                        areAllServersStopped="false"
                    fi
                done
    
                # Silently ignore any servers that are not part of this cell
                if [[ "${areAllServersInCell}" == "true" ]]; then
                    printf "${left2Column}" "Synchronizing servers in ${profile} profile..."
                else
                    printf "${left2Column}" "Servers are not part of cell"
                fi

                # Try the sync if both checks pass
                if [[ "${areAllServersInCell}" == "true" && "${areAllServersStopped}" == "true" ]]; then
                    "${wasProfileRoot}/${profile}/bin/syncNode.sh" "${wasDmgrHost}" "-user" "${wasAdmin}" "-password" "${wasAdminPwd}" >/dev/null 2>&1
                    # Log status
                    if [[ ${?} == 0 ]]; then
                        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
                    else
                        printf "${right2Column}" "${redText}FAILURE${normalText}"
                    fi
                elif [[ "${areAllServersInCell}" == "true" && "${areAllServersStopped}" == "false" ]]; then
                   printf "${right2Column}" "${redText}FAILURE${normalText} (At least one server is still running)"
                fi
            fi

        fi

    done

}

init "${@}"

# See which mode was requested
if [[ "${mode}" == "--offline" ]]; then
    offlineSync
else
    # Online mode can only run on the Deployment Manager
    checkForDmgr
    onlineSync
fi
