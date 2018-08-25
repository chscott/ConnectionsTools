#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallDocker.log"
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

    printToConsole "Usage: uninstallDocker.sh [OPTIONS]"
    printToConsole ""
    printToConsole "Options:"
    printToConsole ""
    printToConsole "--clean"
    printToConsole ""
    printToConsole "In addition to uninstalling Docker, delete the Docker data and configuration directories."

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

# Exit on any failed checks
function checkForPrereqs() {

    printToConsole "Checking to ensure system has all prerequisites in place to uninstall Docker..."

    # See if Kubernetes is installed
    printToLog "Checking to see if Kubernetes components are installed..."
    if [[ "$(isK8sComponentInstalled "kubeadm")" == "true" || 
          "$(isK8sComponentInstalled "kubectl")" == "true" ||
          "$(isK8sComponentInstalled "kubelet")" == "true" ]]; then 
        exitWithError "One or more Kubernetes components is installed. Uninstall Kubernetes before attempting to uninstall Docker"
    fi

}

# Stop any running containers
function stopContainers() {

    if [[ "$(commandExists "docker")" == "true" ]]; then
        if (( $(docker container ls --quiet || wc -l) > 0 )); then
        # There are one or more running containers
            printToConsole "Running containers found. Stopping..."
            docker container stop $(docker container ls --quiet)
        fi
    else
        printToLog "WARNING: Unable to find docker command. Running containers cannot be stopped, which may prevent deleting ${dockerDataDir}."
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
            yum remove -y "${package}" || exitWithError "Error uninstalling Docker components"
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            dnf versionlock delete "${package}"
            dnf remove -y "${package}" || exitWithError "Error uninstalling Docker components"
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}"; then 
            apt-mark unhold "${package}"
            apt-get purge -y "${package}" || exitWithError "Error uninstalling Docker components"
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
         
    printToConsole "Uninstalling Docker..."

    for package in "${packages[@]}"; do
        printToLog "Uninstalling package ${package}..."
        uninstallPackage "${package}"
    done

    printToConsole "Successfully uninstalled Docker"

}

# Delete the Docker config and data directories
function makeClean() {

    printToConsole "Deleting ${dockerConfigDir} and ${dockerDataDir}..."

    rm -f -r "${dockerConfigDir}" "${dockerDataDir}"

}

init "${@}"

if [[ "${clean}" == "true" ]]; then
    # Since this is destructive, ask for confirmation
    printToConsole "WARNING! The --clean option will delete ${dockerConfigDir} and ${dockerDataDir}, removing all configuration, images and containers."
    printToConsole ""
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>&101
    if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
        checkForPrereqs
        stopContainers
        uninstall
        makeClean
    else
        printToConsole "Aborting Docker uninstall"
    fi
else
    checkForPrereqs
    stopContainers
    uninstall
fi
