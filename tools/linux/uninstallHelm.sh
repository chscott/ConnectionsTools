#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallHelm.log"
    >|"${logFile}"

    # Redirect output to the log. Point 101 to the original 1 so some output can be sent to the terminal
    exec 101>&1
    exec 1>>"${logFile}" 2>&1
    terminal="/proc/${BASHPID}/fd/101"

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Process the user arguments and set global variables

    while [[ ${#} > 0 ]]; do
        local key="${1}"
        case "${key}" in
            --help)
                usage
                exit 0
                shift;;
            *)
                outputToTerminal "Unrecognized argument ${key}"
                exit 1
        esac
    done

}

# Print the usage text to the terminal
function usage() {

    outputToTerminal "Usage: uninstallHelm.sh"

}

# Write a message to the log file
function outputToLog() {
    
    local message="${1}"
    
    outputTS "${message}" "${logFile}"

}

# Write a message to the terminal
function outputToTerminal() {

    local message="${1}"
    
    output "${message}" "${terminal}"

}

# Write operation message to log and terminal
function outputOperation() {

    local message="${1}"
    local leftColumnTerminal="%-120.120s"
    local leftColumnLog="%-120.120s\n"

    outputFormattedTS "${message}" "${leftColumnTerminal}" "${terminal}"
    outputFormattedTS "${message}" "${leftColumnLog}" "${logFile}"

}

# Print a failure message
function fail() {

    local redText=$'\e[1;31m'
    local normalText=$'\e[0m'
    local rightAlign="%-6s\n\n"

    # To terminal
    outputFormatted "${redText}Failed${normalText}" "${rightAlign}" "${terminal}"
    outputToTerminal "Review ${logFile} for additional details"

    # To log
    outputTS "The previous operation failed" "${logFile}"
    
    exit 1

}

# Print a warning message
function warn() {

    local yellowText=$'\e[1;33m'
    local normalText=$'\e[0m'
    local rightAlign="%-7s\n"

    # Remember that a warning was generated
    warnings="true"

    # To terminal
    outputFormatted "${yellowText}Warning${normalText}" "${rightAlign}" "${terminal}"

    # To log
    outputTS "The previous operation completed with warnings" "${logFile}"

}

# Print a success message
function pass() {

    local greenText=$'\e[1;32m'
    local normalText=$'\e[0m'
    local rightAlign="%-9s\n"

    # To terminal
    outputFormatted "${greenText}Completed${normalText}" "${rightAlign}" "${terminal}"

    # To log
    outputTS "The previous operation completed successfully" "${logFile}"

}

# Do the uninstall
function uninstall() {

    local installDir="/bin"
         
    # Uninstall server
    outputOperation "Uninstalling Helm server. This make take a few minutes..."
    helm reset --force && pass || fail

    # Uninstall client
    outputOperation "Uninstalling Helm client..."
    rm -f "${installDir}/helm" && pass || fail

}

# Exit with error code and the supplied error message
function exitWithError() {

    local message="${1}"

    outputToTerminal "${message}"
    outputToTerminal "Review ${logFile} for additional details"
    outputToLog "${message}"

    exit 1

}

# Exit without error code and with the supplied message 
function exitWithoutError() {

    local message="${1}"

    outputToTerminal "${message}"
    outputToLog "${message}"

    exit 0

}

# Report status
function term() {

    outputToTerminal ""
    outputToTerminal "Helm successfully uninstalled!"

}

init "${@}"

uninstall
term
