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

}

function logToConsole() {

    local message="${1}"

	printf "%s\n" "${message}" >&101

}

function exitWithError() {

    local message="${1}"

    logToConsole "${message}. Review ${logFile} for additional details"
    exit 1

}

function uninstallPackage() {

    local package="${1}"

    # yum
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if yum list installed "${package}"; then 
            log "***** Uninstalling package ${package}..."
            yum remove -y "${package}" || exitWithError "Error uninstalling Docker components"
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            log "***** Uninstalling package ${package}..."
            dnf remove -y "${package}" || exitWithError "Error uninstalling Docker components"
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}"; then 
            log "***** Uninstalling package ${package}..."
            apt-get purge -y "${package}" || exitWithError "Error uninstalling Docker comonents"
        fi
    fi

}

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
        uninstallPackage "${package}"
    done

    logToConsole "Successfully uninstalled Docker"

}

function makeClean() {

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

function makeCleaner() {

    logToConsole "Removing /var/lib/docker..."
    rm -f -r "/var/lib/docker"

}

init "${@}"

distro="$(getDistro)"
let majorVersion=$(getMajorVersion)
let minorVersion=$(getMinorVersion)

log "***** Distro: ${distro}"
log "***** Major version: ${majorVersion}"
log "***** Minor version: ${minorVersion}"

# If --clean was specified, uninstall and remove orphaned packages
if [[ ! -z "${1}" && "${1}" == "--clean" ]]; then
    uninstall
    makeClean
# If --cleaner was specified, uninstall, remove orphaned packages, and delete /var/lib/docker. Ask for confirmation first!
elif [[ ! -z "${1}" && "${1}" == "--cleaner" ]]; then
    # Since this is destructive, ask for confirmation
    read -p "The --cleaner option deletes /var/lib/docker. If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>&101
    if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
        uninstall
        makeClean
        makeCleaner
    fi
# Just uninstall
else
    uninstall
fi
