#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallKubernetes.log"
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
    distro="$(getDistro)"
    let osMajorVersion=$(getOSMajorVersion)
    let osMinorVersion=$(getOSMinorVersion)
    printToLog "Distro: ${distro}"
    printToLog "Major version: ${osMajorVersion}"
    printToLog "Minor version: ${osMinorVersion}"

}

# Print the usage text to the console
function usage() {

    printToConsole "Usage: uninstallKubernetes.sh [OPTIONS]"
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

# Uninstall the specified package. Current behavior relies on package managers not returning error codes if packages are simply not found
function uninstallPackage() {

    local package="${1}"
    local distro="$(getDistro)"

    # yum
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if yum list installed "${package}"; then 
            yum versionlock delete "${package}"
            yum remove -y "${package}" || exitWithError "Error uninstalling Kubernetes components"
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            dnf versionlock delete "${package}"
            dnf remove -y "${package}" || exitWithError "Error uninstalling Kubernetes components"
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}"; then 
            apt-mark unhold "${package}"
            apt-get purge -y "${package}" || exitWithError "Error uninstalling Kubernetes components"
        fi
    fi

}

# Do the uninstall
function uninstall() {

    local packages=( 
        "kubeadm"
        "kubectl" 
        "kubelet"
    )
         
    printToConsole "Uninstalling Kubernetes..."

    for package in "${packages[@]}"; do
        printToLog "Uninstalling package ${package}..."
        uninstallPackage "${package}"
    done

    printToConsole "Successfully uninstalled Kubernetes"

}

# Delete additional Kubernetes config/data (not yet implemented)
function makeClean() {

    printToConsole "The makeCleaner function is not yet implemented"

}

init "${@}"

if [[ "${clean}" == "true" ]]; then
    # Since this is destructive, ask for confirmation
    printToConsole "WARNING! The --clean option will delete <fill in later>, removing all configuration and data"
    printToConsole ""
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>&101
    if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
        uninstall
        makeClean
    else
        printToConsole "Aborting Kubernetes uninstall"
    fi
else
    uninstall
fi
