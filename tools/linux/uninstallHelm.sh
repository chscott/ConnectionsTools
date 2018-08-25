#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallHelm.log"
    >|"${logFile}"

    # Redirect output to the log. Point 101 to the original 1 so some output can be sent to the terminal
    exec 101>&1
    exec 1>>"${logFile}" 2>&1

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Process the user arguments and set global variables
    clean="false"

    while [[ ${#} > 0 ]]; do
        local key="${1}"
        case "${key}" in
            --help)
                usage
                exit 0
                shift;;
            --clean)
                clean="true"
                shift;;
            *)
                printToConsole "Unrecognized argument ${key}"
                exit 1
        esac
    done

    # Print log header
    printToLog "Distro: $(getDistro)"
    printToLog "Major version: $(getOSMajorVersion)"
    printToLog "Minor version: $(getOSMinorVersion)"

}

# Print the usage text to the console
function usage() {

    printToConsole "Usage: uninstallHelm.sh [OPTIONS]"
    printToConsole ""
    printToConsole "Options:"
    printToConsole ""
    printToConsole "--clean"
    printToConsole ""
    printToConsole "Not yet implemented."

}

# Print to the console (and to the log)
function printToConsole() {

    local message="${1}"

	printf "%s\n" "${message}" >&101
    printToLog "${message}"

}

# Print to the specified log
function printToLog() {

    local message="${1}"
    local now="$(date '+%F %T')"

	printf "%s %s\n" "${now}" "${message}" >>"${logFile}"

}

# Print error message and exit
function exitWithError() {

    local message="${1}"

    printToConsole "${message}."
    printToConsole "Review ${logFile} for additional details"
    exit 1

}

# Do the uninstall
function uninstall() {
         
    printToConsole "Uninstalling Helm..."

    # Reset Helm
    helm reset --force || exitWithError "Unable to uninstall Helm"

    printToConsole "Successfully uninstalled Helm..."

}

# Delete additional Helm config/data (not yet implemented)
function makeClean() {

    # Not sure what is needed here, if anything
    log "makeClean function not yet implemented"

}

init "${@}"

if [[ "${clean}" == "true" ]]; then
    # Since this is destructive, ask for confirmation
    printToConsole "WARNING! The --clean option will delete all Helm configuration and data"
    printToConsole ""
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>&101
    if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
        uninstall
        makeClean
    else
        printToConsole "Aborting Helm uninstall"
    fi
else
    uninstall
fi
