#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallDocker.log"
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
    dockerDataDir="/var/lib/docker"
    dockerConfigDir="/etc/docker"
    dockerDirs=(
        "${dockerDataDir}"
        "${dockerConfigDir}"
    )
    clean="false"
    warnings="false"

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
                outputToTerminal "Unrecognized argument ${key}"
                exit 1
        esac
    done

}

# Print the usage text to the terminal
function usage() {

    outputToTerminal "Usage: uninstallDocker.sh [OPTIONS]"
    outputToTerminal ""
    outputToTerminal "Options:"
    outputToTerminal ""
    outputToTerminal "--clean"
    outputToTerminal "  In addition to uninstalling docker-ce, delete the Docker data and configuration directories."

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

# Test prereqs for uninstall. Any checks that do not pass exit immediately
function checkForPrereqs() {

    # See if Kubernetes is installed
    outputOperation "Verifying Kubernetes is not installed..."
    if [[ "$(isK8sComponentInstalled "kubeadm")" == "false" && 
          "$(isK8sComponentInstalled "kubectl")" == "false" && 
          "$(isK8sComponentInstalled "kubelet")" == "false" ]]; then pass; else fail; fi

}

# Stop any running containers
function stopContainers() {

        if [[ "$(commandExists "docker")" == "true" ]]; then
            if (( $(docker container ls --quiet | wc -l) > 0 )); then
                outputOperation "Stopping running containers..."
                docker container stop $(docker container ls --quiet) && pass || fail
            fi
        fi

}

# Uninstall the specified package. Current behavior relies on package managers not returning error codes if packages are simply not found
function uninstallPackage() {

    local package="${1}"
    local distro="$(getDistro)"

    # yum
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if yum list installed "${package}"; then 
            yum versionlock delete "${package}"
            outputOperation "Removing package ${package}..."
            yum remove -y "${package}" && pass || fail
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            dnf versionlock delete "${package}"
            outputOperation "Removing package ${package}..."
            dnf remove -y "${package}" && pass || fail
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}" | grep "^.i"; then 
            apt-mark unhold "${package}"
            outputOperation "Removing package ${package}..."
            apt-get purge -y "${package}" && pass || fail
        fi
    fi

}

# Do the uninstall
function uninstall() {

    local packages=( 
        "container-selinux"
        "docker" 
        "docker.io"
        "docker-ce"
        "docker-client" 
        "docker-client-latest" 
        "docker-common" 
        "docker-latest" 
        "docker-latest-logrotate" 
        "docker-logrotate"
        "docker-selinux" 
        "docker-engine-selinux" 
        "docker-engine" 
    )
         
    for package in "${packages[@]}"; do
        uninstallPackage "${package}"
    done

}

# Delete the Docker config and data directories
function makeClean() {

    for directory in "${dockerDirs[@]}"; do
        outputOperation "Deleting ${directory}..."
        rm -f -r "${directory}" && pass || fail
    done 

}

# Report status
function term() {

    outputToTerminal ""
    if [[ "${warnings}" == "false" ]]; then
        outputToTerminal "Docker has been uninstalled successfully!"
    else
        outputToTerminal "Docker has been uninstalled with warnings. Review ${logFile} for additional details." 
    fi

}

init "${@}"

if [[ "${clean}" == "true" ]]; then
    # Since this is destructive, ask for confirmation
    outputToTerminal ""
    outputToTerminal "WARNING! The --clean option will remove all Docker directories."
    outputToTerminal "All configuration, images and containers will be deleted!"
    outputToTerminal ""
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>>"${terminal}"
    outputToTerminal ""
    if [[ -n "${answer}" && "${answer}" == "yes" ]]; then
        checkForPrereqs
        stopContainers
        uninstall
        makeClean
        term
    else
        exitWithError "Aborting Docker uninstall"
    fi
else
    checkForPrereqs
    stopContainers
    uninstall
    term
fi
