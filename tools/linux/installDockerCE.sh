#!/bin/bash

function init() {

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf" 
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Set up the log file
    logFile="/var/log/installDockerCE.log"
    log "Beginning installation of Docker CE" >|"${logFile}"

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
        majorVersion=$(cat /etc/system-release | awk '{print $(NF-1)}' | awk -F '.' '{print $1}')
    else
        majorVersion=-1
    fi

    log "Major version: ${majorVersion}" >>"${logFile}"

}

function checkForUnsupportedDistroAndVersion() {

    if [[ "${distro}" == "centos" || "${distro}" == "redhat" ]]; then
        if [[ ${majorVersion} != 7 ]]; then
            log "Version ${majorVersion} of distro ${distro} is not supported. Exiting"
            exit 1
        fi
    else
        log "Version ${majorVersion} of distro ${distro} is not supported. Exiting"
        exit 1
    fi 

}

function checkForDockerCE() {

    local packageManager="${1}"

    if [[ "${packageManager}" == "yum" ]]; then
        if [[ $(yum list installed docker-ce >>"${logFile}" 2>&1; echo ${?}) == 0 ]]; then
            log "Docker CE is already installed. Exiting"
            exit 0
        fi 
    fi

}

function uninstallOldVersions() {

    local packageManager="${1}"

    if [[ "${packageManager}" == "yum" ]]; then
        yum remove -y \
            "docker" \
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
            log "Error uninstalling old versions of Docker components. Exiting"
            exit 1
        fi
    fi

}

function install() {

    # CentOS and RHEL
    if [[ "${distro}" == "centos" || "${distro}" == "redhat" ]]; then
        # Install prereqs
        if [[ "${distro}" == "centos" ]]; then
            local baseRepo="base"
            local extrasRepo="extras"
        elif [[ "${distro}" == "redhat" ]]; then
            local baseRepo="rhel-7-server-rpms"
            local extrasRepo="rhel-7-server-extras-rpms"
        fi
        yum --enablerepo "${baseRepo}" install -y "yum-utils" "device-mapper-persistent-data" "lvm2" >>"${logFile}" || 
            { log "Failed to install prerequisite packages. Exiting"; exit 1; }
        # Add Docker CE repo
        yum-config-manager --add-repo "https://download.docker.com/linux/centos/docker-ce.repo" >>"${logFile}" ||
            { log "Failed to add docker-ce repo. Exiting"; exit 1; }
        # Install Docker CE
        yum --enablerepo "${extrasRepo}" install -y "docker-ce" >>"${logFile}" ||
            { log "Failed to install Docker CE components. Exiting"; exit 1; }
        # Configure auto-start
        if [[ $(which systemctl >>"${logFile}" 2>&1; echo ${?}) != 0 ]]; then
            log "This system does not use systemd. Manually configure Docker to start"
        else
            systemctl enable "docker" >>"${logFile}" 2>&1 || log "Failed to enable docker for auto-start. Manual configuration required"
            systemctl start "docker" >>"${logFile}" 2>&1 || log "Failed to start docker. Manual start required"
        fi
        log "Docker CE successfully installed"
    fi

}

init "${@}"

# Get info about the install target
getDistro
getMajorVersion

# Verify this target is supported
checkForUnsupportedDistroAndVersion

# See if Docker is already installed
log "Checking to see if Docker CE is already installed..."
if [[ "${distro}" == "centos" || "${distro}" == "redhat" ]]; then
    checkForDockerCE "yum"
fi

# Uninstall old versions
log "Uninstalling old versions of Docker components..."
if [[ "${distro}" == "centos" || "${distro}" == "redhat" ]]; then
    uninstallOldVersions "yum"
fi

# Install Docker
log "Installing Docker CE..."
install
