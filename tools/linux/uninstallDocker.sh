#!/bin/bash

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf" 
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Set up the log file
    logFile="/var/log/uninstallDocker.log"
    log "Beginning uninstallation of Docker" >|"${logFile}"

}

function getDistro() {

    # Try /etc/system-release
    if [[ -f "/etc/system-release" ]]; then
        release="$(cat /etc/system-release)"
        log "Contents of /etc/system-release: ${release}" >>"${logFile}"
        if [[ $(echo "${release}" | grep -c "Red Hat") > 0 ]]; then
            distro="redhat"
        elif [[ $(echo "${release}" | grep -c "CentOS") > 0 ]]; then
            distro="centos"
        else
            distro="unsupported"
        fi
    fi

    log "Distro: ${distro}" >>"${logFile}"

}

function getMajorVersion() {

   # Try /etc/system-release 
    if [[ -f "/etc/system-release" ]]; then
        majorVersion="$(cat /etc/system-release | awk '{print $(NF-1)}' | awk -F '.' '{print $1}')"
    else
        majorVersion="unknown"
    fi

    log "Major version: ${majorVersion}" >>"${logFile}"

}

function uninstall() {

    local packageManager="${1}"

    if [[ "${packageManager}" == "yum" ]]; then
        yum remove -y \
            "docker" \
            "docker-ce" \
            "docker-client" \
            "docker-client-latest" \
            "docker-common" \
            "docker-latest" \
            "docker-latest-logrotate" \
            "docker-logrotate" \
            "docker-selinux" \
            "docker-engine-selinux" \
            "docker-engine" \
            >>"${logFile}" 2>&1
        if [[ ${?} != 0 ]]; then
            log "Error uninstalling Docker components. Exiting"
            exit 1
        else
            log "Docker components successfully uninstalled"
        fi
    fi

}

init "${@}"

# Get info about the install target
getDistro
getMajorVersion

# Uninstall Docker
log "Uninstalling Docker..."
if [[ "${distro}" == "centos" || "${distro}" == "redhat" ]]; then
    uninstall "yum"
fi
