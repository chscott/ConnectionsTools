#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installKubernetes.log"
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

function exitWithoutError() {

    local message="${1}"

    logToConsole "${message}"
    exit 0

}

# Exit on any failed checks
function checkPrereqs() {

    local requiredDockerCEVersion="17.03"

    # Check the platform requirements
    if [[ "$(isCPSupportedPlatform)" == "false" ]]; then 
        exitWithError "This platform does not meet the requirements to install Component Pack"
    fi
    
    # Verify Docker is installed at the required level
    if [[ ! "$(getDockerCEVersion)" == "${requiredDockerCEVersion}" ]]; then 
        exitWithError "Docker ${requiredDockerCEVersion} must be installed before installing Kubernetes"
    fi
        
    # See if Kubernetes is already installed

}

function checkForRequirements() {

    printf "%-20s\t%-20s\t%-20s\n" "Check" "Value" "Requirement" >&101
    printf "%-20s\t%-20s\n" "Distro:" "${distro}" >&101
    printf "%-20s\t%-20s\n" "Version:" "${osMajorVersion}.${osMinorVersion}" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Machine architecture:" "$(getMachineArchitecture)" "x86_64" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Available memory:" "$(getAvailableMemory)" ">2097152" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Total swap:" "$(getSwapMemory)" "0" >&101
    printf "\n" >&101
    printf "%s %s\n" "Supported for Component Pack:" "$(isCPSupportedPlatform)" >&101

}

function install() {

    local target="1.11"
    local version=""

    logToConsole "Installing Kubernetes..."

    # Disable SELinux if enabled
    log "***** Disabling SELinux..."
    if command -v setenforce; then setenforce 0; fi

    # CentOS/RHEL/Fedora
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then

        # All three are identical except for the package manager used. Set that to generic "mgr" to avoid duplicate code
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            local mgr="yum"
        elif [[ "${distro}" == "fedora" ]]; then
            local mgr="dnf" 
        fi

        # Add Kubernetes repo 
        log "***** Adding kubernetes repo..."
        local repoFile="/etc/yum.repos.d/kubernetes.repo"
        printf "[kubernetes]\n" >|"${repoFile}"
        printf "name=Kubernetes\n" >>"${repoFile}"
        printf "baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\n" >>"${repoFile}"
        printf "enabled=1\n" >>"${repoFile}"
        printf "gpgcheck=1\n" >>"${repoFile}"
        printf "repo_gpgcheck=1\n" >>"${repoFile}"
        printf "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg " >>"${repoFile}"
        printf "https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg\n" >>"${repoFile}"

        # Update the yum package index
        log "***** Updating package index..."
        "${mgr}" -y makecache fast || exitWithError "Failed to update the yum package index"

        version="$("${mgr}" list "kubeadm" --showduplicates | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}')" 

        # Install Kubernetes
        log "***** Performing Kubernetes install..."
        "${mgr}" -y install "kubelet-${version}" "kubeadm-${version}" "kubectl-${version}" || exitWithError "Failed to install Kubernetes"

        # Prevent Kubernetes from being updated
        log "***** Configuring Kubernetes packages to prevent auto-upgrade..."
        printf "exclude=kube*\n" >>"${repoFile}"

        # Update /etc/sysctl.d/k8s.conf

    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then

        # Install prereqs
        log "***** Installing prerequisite packages..."
        apt-get -y install "apt-transport-https" "ca-certificates" "curl" "gnupg2" "software-properties-common" ||
            exitWithError "Failed to install prerequisite packages" 

        # Add Kubernetes GPG key
        log "***** Adding Kubernetes GPG key to apt..."
        curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | apt-key add - || exitWithError "Failed to add Kubernetes GPG key"

        # Add Kubernetes repo (the doc says to use kubernetes-xenial for all of the supported Debian/Ubuntu releases)
        log "***** Adding Kubernetes repo..."
        add-apt-repository "deb [arch=amd64] http://apt.kubernetes.io kubernetes-xenial main" || exitWithError "Failed to add Kubernetes repo"

        # Update the apt package index
        log "***** Updating package index..."
        apt-get -y update || exitWithError "Failed to update the apt package index"

        # Get the latest version of Kubernetes target
        log "***** Getting the latest version of Kubernetes target installation version ${target}..."
        version="$(apt-cache madison "kubeadm" | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk -F '\\| ' '{print $2}' | \
            tr -d ' ')" 
        log "***** Latest version available: ${version}"

        # Install Kubernetes
        log "***** Performing Kubernetes install..."
        apt-get -y install "kubeadm=${version}" "kubectl=${version}" "kubelet=${version}" || exitWithError "Failed to install Kubernetes"

        # Prevent Kubernetes from being updated
        log "***** Configuring Kubernetes packages to prevent auto-upgrade..."
        apt-mark hold "kubeadm" "kubectl" "kubelet"

    fi

    logToConsole "Kubernetes successfully installed"

}

function configAutoStart() {

    if command -v systemctl; then
        systemctl enable "kubelet" || logToConsole "Failed to enable kubelet for auto-start. Manual configuration required"
        systemctl start "kubelet" || logToConsole "Failed to start kubelet Manual start required"
    else
        logToConsole "This system does not use systemd. Manually configure kubelet to start"
    fi

}

init "${@}"

distro="$(getDistro)"
let osMajorVersion=$(getOSMajorVersion)
let osMinorVersion=$(getOSMinorVersion)

if [[ "${1}" == "--check" ]]; then
    # User just wants to check requirements and not do the install
    checkForRequirements
else
    # User wants to try the install
    log "***** Distro: ${distro}"
    log "***** Major version: ${osMajorVersion}"
    log "***** Minor version: ${osMinorVersion}"
    checkPrereqs
    install
    configAutoStart
fi 
