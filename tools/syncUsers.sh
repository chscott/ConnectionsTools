#!/bin/bash
# syncUsers.sh: Perform TDI user sync

# Source prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {

    # Make sure we're running as root
    checkForRoot
    
}

init 

printf "%-60.60s" "Synchronizing Profiles with LDAP..."

"${tdiSolutionDir}/sync_all_dns.sh" >/dev/null 2>&1

if [[ ${?} == 0 ]]; then
    printf " %-7s\n" "${greenText}SUCCESS${normalText}"
else
    printf " %-7s\n" "${redText}FAILURE${normalText}"
fi
