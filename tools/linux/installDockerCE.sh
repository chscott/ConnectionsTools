#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installDockerCE.log"
    >|"${logFile}"
    # This is used to give us a file descriptor to print to normal stdout
    exec 101>&1
    # Redirect output to the log
    exec 1>>"${logFile}" 2>&1
    # Give process substitution a moment to complete before main shell continues
    sleep 1

    # Source the prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf" 
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

function checkForDockerCE() {

    local isInstalled="false"

    logToConsole "Checking to see if Docker CE is already installed..."

    # CentOS/RHEL
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if yum list installed "docker-ce"; then isInstalled="true"; fi 
    # Fedora
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "docker-ce"; then isInstalled="true"; fi 
    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list | grep "docker-ce"; then isInstalled="true"; fi 
    fi

    if [[ "${isInstalled}" == "true" ]]; then
        exitWithoutError "Docker CE is already installed"
    fi

}

function checkForObsoletePackages() {

    local obsoletePackages=( 
        "container-selinux"
        "docker" 
        "docker.io"
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

    logToConsole "Checking for obsolete Docker packages..."

    for obsoletePackage in "${obsoletePackages[@]}"; do
        # yum
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            if yum list installed "${obsoletePackage}"; then 
                exitWithError "Package ${package} is installed. Run uninstallDocker.sh to remove obsolete packages"
            fi
        # dnf
        elif [[ "${distro}" == "fedora" ]]; then
            if dnf list installed "${obsoletePackage}"; then 
                exitWithError "Package ${package} is installed. Run uninstallDocker.sh to remove obsolete packages"
            fi
        # apt
        elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
            if dpkg-query --list "${obsoletePackage}"; then 
                exitWithError "Package ${package} is installed. Run uninstallDocker.sh to remove obsolete packages"
            fi
        fi
    done

}

function install() {

    local target="17.03"
    local version=""

    logToConsole "Installing Docker CE..."

    # CentOS (https://docs.docker.com/install/linux/docker-ce/centos)
    if [[ "${distro}" == "centos" ]]; then

        # Install prereqs
        yum --enablerepo "base" install -y "yum-utils" "device-mapper-persistent-data" "lvm2" || 
            exitWithError "Failed to install prerequisite packages"

        # Add Docker CE repo
        yum-config-manager --add-repo "https://download.docker.com/linux/centos/docker-ce.repo" || 
            exitWithError "Failed to add docker-ce repo"

        # Update the yum package index
        yum makecache -y fast

        # Get the latest version of docker target
        version="$(yum list "docker-ce.x86_64" --showduplicates | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 

        # Install Docker CE
        yum --enablerepo "extras" --setopt=obsoletes=0 install -y "docker-ce-${version}" || 
            exitWithError "Failed to install Docker CE components"

        # Ensure devicemapper is used as the storage driver
        local configFile="/etc/docker/daemon.json"
        if [[ ! -f "${configFile}" ]]; then
           printf "{\n\t\"storage-driver\": \"devicemapper\"\n}\n" >"${configFile}" 
        else
            local tmpConfigFile=$(mktemp /etc/docker/daemon.json.XXX)
            logToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one" 
            mv "${configFile}" "${tmpConfigFile}"
            printf "{\n\t\"storage-driver\": \"devicemapper\"\n}\n" >"${configFile}" 
        fi

    # RHEL (not officially supported, requirements taken from CentOS doc)
    elif [[ "${distro}" == "rhel" ]]; then

        # Install prereqs
        yum -y --enablerepo "rhel-7-server-rpms" install "yum-utils" "device-mapper-persistent-data" "lvm2" || 
            exitWithError "Failed to install prerequisite packages"

        # Add Docker CE repo
        yum-config-manager --add-repo "https://download.docker.com/linux/centos/docker-ce.repo" || 
            exitWithError "Failed to add docker-ce repo"

        # Update the yum package index
        yum -y makecache fast

        # Get the latest version of docker target
        version="$(yum list "docker-ce.x86_64" --showduplicates | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 

        # Install Docker CE
        yum --enablerepo "rhel-7-server-extras-rpms" --setopt=obsoletes=0 install -y "docker-ce-${version}" ||
            exitWithError "Failed to install Docker CE components"

        # Ensure devicemapper is used as the storage driver
        local configFile="/etc/docker/daemon.json"
        if [[ ! -f "${configFile}" ]]; then
           printf "{\n\t\"storage-driver\": \"devicemapper\"\n}\n" >"${configFile}" 
        else
            local tmpConfigFile=$(mktemp /etc/docker/daemon.json.XXX)
            logToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one" 
            mv "${configFile}" "${tmpConfigFile}"
            printf "{\n\t\"storage-driver\": \"devicemapper\"\n}\n" >"${configFile}" 
        fi

    # Fedora (https://docs.docker.com/install/linux/docker-ce/fedora)
    elif [[ "${distro}" == "fedora" ]]; then

        # Install prereqs
        dnf -y --enablerepo "fedora" install "dnf-plugins-core" || 
            exitWithError "Failed to install prerequisite packages"

        # Add Docker CE repo
        dnf config-manager --add-repo "https://download.docker.com/linux/fedora/docker-ce.repo" || 
            exitWithError "Failed to add docker-ce repo"

        # Update the yum package index
        dnf -y makecache fast

        # Get the latest version of docker target
        version="$(dnf list "docker-ce" --showduplicates | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 

        # Install Docker CE
        dnf -y install "docker-ce-${version}" || 
            exitWithError "Failed to install Docker CE components"

    # Debian (https://docs.docker.com/install/linux/docker-ce/debian)
    elif [[ "${distro}" == "debian" ]]; then

        # Install prereqs
        apt-get -y install "apt-transport-https" "ca-certificates" "curl" "gnupg2" "software-properties-common" ||
            exitWithError "Failed to install prerequisite packages"

        # Add Docker GPG key
        curl -fsSL "https://download.docker.com/linux/debian/gpg" | apt-key add - || 
            exitWithError "Failed to add Docker GPG key"

        # Add Docker repo
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" ||
            exitWithError "Failed to add Docker repo"

        # Update the apt package index
        apt-get -y update

        # Get the latest version of docker target
        version="$(apt-cache madison "docker-ce" | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk -F "\| " '{print $2}' | \
            tr -d ' ')" 

        # Install Docker CE
        apt-get install -y "docker-ce=${version}" || 
            exitWithError "Failed to install Docker CE components"

    # Ubuntu (https://docs.docker.com/install/linux/docker-ce/ubuntu)
    elif [[ "${distro}" == "ubuntu" ]]; then

        # Install prereqs
        apt-get -y install "apt-transport-https" "ca-certificates" "curl" "software-properties-common" ||
            exitWithError "Failed to install prerequisite packages"

        # Add Docker GPG key
        curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | apt-key add - || 
            exitWithError "Failed to add Docker GPG key"

        # Add Docker repo
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" ||
            exitWithError "Failed to add Docker repo"

        # Update the apt package index
        apt-get -y update

        # Get the latest version of docker target
        version="$(apt-cache madison "docker-ce" | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk -F "\| " '{print $2}' | \
            tr -d ' ')" 

        # Install Docker CE
        apt-get install -y "docker-ce=${version}" || 
            exitWithError "Failed to install Docker CE components"

    fi

    logToConsole "Docker CE successfully installed"

}

function configAutoStart() {

    if ! which systemctl; then
        logToConsole "This system does not use systemd. Manually configure Docker to start"
    else
        systemctl enable "docker" || logToConsole "Failed to enable docker for auto-start. Manual configuration required"
        systemctl start "docker" || logToConsole "Failed to start docker. Manual start required"
    fi

}

init "${@}"

distro="$(getDistro)"
let majorVersion=$(getMajorVersion)
let minorVersion=$(getMinorVersion)

log "Distro: ${distro}"
log "Major version: ${majorVersion}"
log "Minor version: ${minorVersion}"

if [[ "$(isCPSupportedRelease)" == "true" ]]; then
    # If RHEL, --force must be provided to install
    if [[ "${distro}" == "rhel" ]]; then
        if [[ "${1}" != "--force" ]]; then
            exitWithoutError "Docker CE is not officially supported on RHEL. To force installation anyway, use the --force option"
        fi
    fi
    # See if Docker is already installed
    checkForDockerCE
    # Verify there are no obsolete packages installed
    checkForObsoletePackages
    # Install Docker
    install
    # Configure auto-start
    configAutoStart
else
    exitWithoutError "Major version [$(getMajorVersion)], minor version [$(getMinorVersion)] is not a supported target for [${distro}]"
fi
