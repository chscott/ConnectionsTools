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

    # Redirect FD 1 to terminal so each line doesn't have to be redirected
    exec 1>>"${terminal}"

    printf "%s\n" "Usage: uninstallDocker.sh [OPTIONS]"
    printf "%s\n" ""
    printf "%s\n" "Options:"
    printf "%s\n" ""
    printf "%s\n" "--clean"
    printf "%s\n" "  In addition to uninstalling docker-ce, delete the Docker data and configuration directories."

    # Redirect FD 1 back to the log file
    exec 1>>"${logFile}"

}

# Print to the log
function printToLog() {

    local message="${1}"
    local now="$(date '+%F %T')"

	printf "%s\n" "${now} ${message}"

}

# Print the operation
function operation() {

    local message="${1}"
    local now="$(date '+%F %T')"
    local leftAlign="%-120.120s"

    # To terminal
    printf "${leftAlign}" "${now} ${message}" >>"${terminal}"

    # To log
    printToLog "${now} ${message}"

}

# Print a failure message
function fail() {

    local redText=$'\e[1;31m'
    local normalText=$'\e[0m'
    local rightAlign="%-6s\n\n"

    # To terminal
    printf "${rightAlign}" "${redText}Failed${normalText}" >>"${terminal}"
    printf "%s\n" "Review ${logFile} for additional details" >>"${terminal}"

    # To log
    printToLog "Operation failed"
    
    exit 1

}

# Print a warning message
function warn() {

    local yellowText=$'\e[1;33m'
    local normalText=$'\e[0m'
    local rightAlign="%-7s\n"

    # To terminal
    printf "${rightAlign}" "${yellowText}Warning${normalText}" >>"${terminal}"
    
    # To log
    printToLog "Operation completed with warnings"

}

# Print a success message
function pass() {

    local greenText=$'\e[1;32m'
    local normalText=$'\e[0m'
    local rightAlign="%-9s\n"

    # To terminal
    printf "${rightAlign}" "${greenText}Completed${normalText}" >>"${terminal}"

    # To log
    printToLog "Operation completed successfully"

}

# Exit with error code and the supplied error message
function exitWithError() {

    local message="${1}"

    printf "%s\n" "${message}" | tee "${terminal}"
    printf "%s\n" "Review ${logFile} for additional details" | tee "${terminal}"
    exit 1

}

# Exit without error code and with the supplied message 
function exitWithoutError() {

    local message="${1}"

    printf "%s\n" "${message}" | tee "${terminal}" 
    exit 0

}

# Test prereqs for uninstall. Any checks that do not pass exit immediately
function checkForPrereqs() {

    # See if Kubernetes is installed
    operation "Verifying Kubernetes is not installed..."
    if [[ "$(isK8sComponentInstalled "kubeadm")" == "true" || 
          "$(isK8sComponentInstalled "kubectl")" == "true" ||
          "$(isK8sComponentInstalled "kubelet")" == "true" ]]; then fail; else pass; fi

}

# Stop any running containers
function stopContainers() {

        if (( $(docker container ls --quiet | wc -l) > 0 )); then
            operation "Stopping running containers..."
            docker container stop $(docker container ls --quiet) && pass || fail
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
            operation "Removing package ${package}..."
            yum remove -y "${package}" && pass || fail
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            dnf versionlock delete "${package}"
            operation "Removing package ${package}..."
            dnf remove -y "${package}" && pass || fail
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}" | grep "^.i"; then 
            apt-mark unhold "${package}"
            operation "Removing package ${package}..."
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

    operation "Deleting ${dockerConfigDir} and ${dockerDataDir}..."

    rm -f -r "${dockerConfigDir}" "${dockerDataDir}" && pass || fail

}

init "${@}"

if [[ "${clean}" == "true" ]]; then
    # Since this is destructive, ask for confirmation
    printf "%s" "WARNING! The --clean option will delete ${dockerConfigDir} and ${dockerDataDir}, " >>"${terminal}"
    printf "%s\n\n" "removing all configuration, images and containers." >>"${terminal}"
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>>"${terminal}"
    printf "\n" >>"${terminal}"
    if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
        checkForPrereqs
        stopContainers
        uninstall
        makeClean
        printf "\n%s\n" "docker-ce has been uninstalled successfully!" >>"${terminal}"
    else
        printf "%s\n" "Aborting docker-ce uninstall" >>"${terminal}"
    fi
else
    checkForPrereqs
    stopContainers
    uninstall
    printf "\n%s\n" "docker-ce has been uninstalled successfully!" >>"${terminal}"
fi
