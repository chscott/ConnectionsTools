#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallDocker.log"
    >|"${logFile}"
    # This is used to give us a file descriptor to print to normal stdout
    exec 101>&1
    # Redirect output to the log
    exec 1>>"${logFile}" 2>&1
    # Give process substitution a moment to complete before main shell continues
    sleep 1

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Global variables
    dockerDataDir="/var/lib/docker"
    dockerConfigDir="/etc/docker"

}

# Print a message to terminal
function logToConsole() {

    local message="${1}"

	printf "%s\n" "${message}" >&101

}

# Print error message and exit
function exitWithError() {

    local message="${1}"

    logToConsole "${message}. Review ${logFile} for additional details"
    exit 1

}

# Uninstall the specified package. Current behavior relies on package managers not returning error codes if packages are simply not found
function uninstallPackage() {

    local distro="$(getDistro)"
    local package="${1}"

    # yum
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if yum list installed "${package}"; then 
            yum remove -y "${package}" || exitWithError "Error uninstalling Docker components"
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            dnf remove -y "${package}" || exitWithError "Error uninstalling Docker components"
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}"; then 
            apt-get purge -y "${package}" || exitWithError "Error uninstalling Docker comonents"
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
         
    logToConsole "Uninstalling Docker..."

    for package in "${packages[@]}"; do
        log "***** Uninstalling package ${package}..."
        uninstallPackage "${package}"
    done

    logToConsole "Successfully uninstalled Docker"

}

# Deleted orphaned packages (Docker and otherwise)
function makeClean() {

    local distro="$(getDistro)"

    logToConsole "Cleaning up orphaned packages..."
    
    # yum
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        yum autoremove -y  || exitWithError "Error cleaning orphaned packages"
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        dnf autoremove -y || exitWithError "Error cleaning orphaned packages"
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        apt-get autoremove -y || exitWithError "Error cleaning orphaned packages"
    fi

}

# Delete the Docker config and data directories
function makeCleaner() {

    rm -f -r "${dockerConfigDir}" "${dockerDataDir}"

}

init "${@}"

distro="$(getDistro)"
let osMajorVersion=$(getOSMajorVersion)
let osMinorVersion=$(getOSMinorVersion)

log "***** Distro: ${distro}"
log "***** Major version: ${osMajorVersion}"
log "***** Minor version: ${osMinorVersion}"

# If --clean was specified, uninstall and remove orphaned packages
if [[ ! -z "${1}" && "${1}" == "--clean" ]]; then
    uninstall
    makeClean
# If --cleaner was specified, uninstall, remove orphaned packages, and delete ${dockerDataDir}. Ask for confirmation first!
elif [[ ! -z "${1}" && "${1}" == "--cleaner" ]]; then
    # Since this is destructive, ask for confirmation
    logToConsole "WARNING! The --cleaner option will delete ${dockerConfigDir} and ${dockerDataDir}, removing all configuration and data"
    logToConsole ""
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>&101
    if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
        uninstall
        makeClean
        makeCleaner
    else
        logToConsole "Aborting Docker uninstall"
    fi
# Just uninstall
else
    uninstall
fi
