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
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Process the user arguments
    while [[ ${#} > 0 ]]; do
        local key="${1}"
        local value="${2}"
        case "${key}" in
            --check)
                checkRequirements="true"
                shift;;
            --force)
                forceInstall="true"
                shift;;
            --direct-lvm-device)
                directLvmDevice="${value}"
                shift;shift;;
            *)
                log "Unrecognized argument ${key}"
                exit 1
        esac
    done

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

# Print a table of requirements if the user requested it via the --check option
function checkForRequirements() {

    printf "%-20s\t%-20s\t%-20s\n" "Requirement" "Found" "Requires" >&101
    printf "%-20s\t%-20s\t%-20s\n" "-----------" "-----" "--------" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Distro:" "${distro}" "centos, rhel*, fedora, debian or ubuntu" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Version:" "${osMajorVersion}.${osMinorVersion}" \
           "7.x (centos and rhel), 25.x (fedora), 9.x (debian) or 16.04/16.10 (ubuntu)" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Machine architecture:" "$(getMachineArchitecture)" "x86_64" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Logical cores:" "$(getLogicalCores)" "At least 2" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Available memory:" "$(getAvailableMemory)" "At least 2097152" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Total swap:" "$(getSwapMemory)" "Must be 0" >&101
    printf "\n" >&101
    if [[ "${distro}" == "rhel" ]]; then
        printf "*RHEL is not supported with Docker CE. You can install it anyway using the --force option\n" >&101
        printf "\n" >&101
    fi
    if [[ "$(isCPSupportedPlatform)" == "true" ]]; then
        local isSupported="Yes"
    else
        local isSupported="No"
    fi
    printf "%s %s\n" "Supported for Component Pack:" "${isSupported}" >&101

}

# Test prereqs for install. Any checks that do not pass exit immediately
function checkPrereqs() {

    # Check the platform requirements
    log "***** Checking to see if system meets requirements to install Docker..."
    if [[ "$(isCPSupportedPlatform)" == "false" ]]; then 
        exitWithError "Requirements not met to install Component Pack. Use the --check option to print requirements"
    fi
    
    # Verify Docker is not already installed
    log "***** Checking to see if Docker CE is already installed..."
    if [[ "$(isDockerCEInstalled)" == "true" ]]; then 
        exitWithError "Docker CE is already installed"
    fi

    # If a direct-lvm device was provided, verify its requirements
    if [[ ! -z "${directLvmDevice}" ]]; then
        # Only for CentOS and RHEL. Other distros use overlay2, which is preferred
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            # If lsblk isn't available, don't try to configure direct-lvm
            if command -v lsblk; then
                # Get the number of devices returned by the lsblk command for this device (includes dependent devices like partitions)
                local deviceCount=$(lsblk --noheadings --output NAME "${directLvmDevice}" | wc -l)
                # Get the type for this device
                local deviceType="$(lsblk --noheadings --nodeps --output TYPE "${directLvmDevice}")"
                # Get the filesystem type for this device
                local deviceFSType="$(lsblk --noheadings --nodeps --output FSTYPE "${directLvmDevice}")"
                # This helps with reporting
                if [[ "${deviceFSType}" == "" ]]; then
                    deviceFSType="<null>"
                fi
                # Allow configuration if device is a disk or partition with no dependent devices and no filesystem
                if [[ ("${deviceType}" == "disk" || "${deviceType}" == "part") && "${deviceCount}" == 1 && "${deviceFSType}" == "<null>" ]]; then
                    # Since this is destructive, ask for confirmation. The checks should ensure not data is lost, but ask anyway, just in case
                    logToConsole "WARNING! The --direct-lvm-device option will destroy all existing data on ${directLvmDevice}."
                    logToConsole "Setting up a new block device for devicemapper also requires deleting /var/lib/docker, which"
                    logToConsole "will delete all of your Docker data (e.g. images and containers)."
                    logToConsole ""
                    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer1 2>&101
                    if [[ ! -z "${answer1}" && "${answer1}" == "yes" ]]; then
                        log "***** Allowing direct-lvm configuration for device ${directLvmDevice}..."
                    else
                        exitWithoutError "Aborting Docker CE install"
                    fi
                else
                    log "***** The --direct-lvm-device ${directLvmDevice} does not meet requirements for configuration"
                    printf "%-20s\t%-20s\t%-20s\n" "Requirement" "Found" "Requires"
                    printf "%-20s\t%-20s\t%-20s\n" "-----------" "-----" "--------"
                    printf "%-20s\t%-20s\t%-20s\n" "Type:" "${deviceType}" "disk or part"
                    printf "%-20s\t%-20s\t%-20s\n" "FS Type:" "${deviceFSType}" "<null>" 
                    printf "%-20s\t%-20s\t%-20s\n" "Device count:" "${deviceCount}" "1" 
                    exitWithError "Device ${directLvmDevice} cannot be configured for direct-lvm"
                fi
            else
                exitWithError "--direct-lvm-device was specified, but the lsblk command is not available. Install lsblk and try again"
            fi
        else
            logToConsole "--direct-lvm-device was specified but is not applicable for this platform. Ignoring..."
        fi
    else
        # If --direct-lvm-device was not provided and this is CentOS or RHEL, warn that loop-lvm may be used 
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            logToConsole "WARNING! Attempting to install on ${distro} without using the --direct-lvm-device <block device> option."
            logToConsole "This will result in loop-lvm mode being used. Docker strongly discourages using loop-lvm for production workloads."
            logToConsole ""
            read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer2 2>&101
            if [[ ! -z "${answer2}" && "${answer2}" == "yes" ]]; then
                log "***** Allowing loop-lvm configuration..."
            else
                exitWithoutError "Aborting Docker CE install"
            fi
        fi
    fi

}

# See if any obsolete packages are installed. If any are found, exit with direction to run uninstallDocker.sh
function checkForObsoletePackages() {

    local obsoletePackages=( 
        "container-selinux"
        "docker" 
        "docker.io"
        "docker-client" 
        "docker-client-latest" 
        "docker-common" 
        "docker-engine"
        "docker-latest" 
        "docker-latest-logrotate" 
        "docker-logrotate"
        "docker-selinux" 
        "docker-engine-selinux" 
        "docker-engine" 
    )

    logToConsole "Removing obsolete Docker packages..."

    for obsoletePackage in "${obsoletePackages[@]}"; do
        log "***** Checking to see if obsolete package ${obsoletePackage} is installed..."
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

# Configure direct-lvm for devicemapper
function configDirectLvm() {

    # Create the Physical Volume
    log "***** Creating PV ${directLvmDevice}..."
    pvcreate -y "${directLvmDevice}" || exitWithError "Failed to create ${directLvmDevice} PV"

    # Create the Volume Group
    log "***** Creating VG docker..."
    vgcreate -y "docker" "${directLvmDevice}" || exitWithError "Failed to create docker VG"

    # Create the Logical Volumes
    log "***** Creating LV thinpool..."
    lvcreate -y --wipesignatures "y" --name "thinpool" --extents "95%VG" "docker" || exitWithError "Failed to create thinpool LV"
    log "***** Creating LV thinpoolmeta..."
    lvcreate -y --wipesignatures "y" --name "thinpoolmeta" --extents "1%VG" "docker" || exitWithError "Failed to create thinpoolmeta LV"

    # Convert the Logical Volumes to thin pools
    log "***** Converting LVs to thin pool..."
    lvconvert -y --zero "n" --chunksize "512K" --thinpool "docker/thinpool" --poolmetadata "docker/thinpoolmeta" ||
        exitWithError "Failed to convert LVs to thin pool"

    # Create the LVM profile
    log "***** Creating LVM profile..."
    local lvmProfile="/etc/lvm/profile/docker-thinpool.profile"
    local lvmProfileConfig="activation {\n\tthin_pool_autoextend_threshold=80\n\tthin_pool_autoextend_percent=20\n}\n"
    if [[ ! -f "${lvmProfile}" ]]; then
       printf "${lvmProfileConfig}" >"${lvmProfile}" 
    else
        # If the file already exists, create a backup
        local tmpLvmProfile=$(mktemp /etc/lvm/profile/docker-thinpool.profile.XXX)
        logToConsole "An existing ${lvmProfile} was found. Backing it up as ${tmpLvmProfile} and creating a new one..." 
        mv "${lvmProfile}" "${tmpLvmProfile}"
        printf "${lvmProfileConfig}" >"${lvmProfile}" 
    fi

    # Apply the LVM profile
    log "***** Applying LVM profile..."
    lvchange -y --metadataprofile "docker-thinpool" "docker/thinpool" || exitWithError "Failed to apply LVM profile"

    # Enable monitoring for Logical Volumes
    log "***** Enabling monitoring for LVs..."
    lvs -y --options "+seg_monitor" || exitWithError "Failed to enable LVs for monitoring"

    # Delete /var/lib/docker
    log "***** Deleting /var/lib/docker..."
    if [[ -d "/var/lib/docker" ]]; then
        rm -f -r "/var/lib/docker"
    fi

    # Configure devicemapper for direct-lvm mode
    log "***** Configuring devicemapper storage driver for direct-lvm..."
    local configFile="/etc/docker/daemon.json"
    local configFileConfig=""
    configFileConfig+="{\n"
    configFileConfig+="\t\"storage-driver\": \"devicemapper\",\n"
    configFileConfig+="\t\"storage-opts\": [\n"
    configFileConfig+="\t\t\"dm.thinpooldev=/dev/mapper/docker-thinpool\",\n"
    configFileConfig+="\t\t\"dm.use_deferred_removal=true\"\n"
    configFileConfig+="\t]\n"
    configFileConfig+="}\n"
    # In some cases /etc/docker doesn't exist at this point, so create it
    if [[ ! -d "/etc/docker" ]]; then 
        mkdir "/etc/docker"
    fi
    if [[ ! -f "${configFile}" ]]; then
       printf "${configFileConfig}" >"${configFile}"
    else
        # If the file already exists, create a backup
        local tmpConfigFile=$(mktemp /etc/docker/daemon.json.XXX)
        logToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure loop-lvm for devicemapper
function configLoopLvm() {

    # Delete /var/lib/docker
    log "***** Deleting /var/lib/docker..."
    if [[ -d "/var/lib/docker" ]]; then
        rm -f -r "/var/lib/docker"
    fi

    # Configure devicemapper for direct-lvm mode
    log "***** Configuring devicemapper storage driver for loop-lvm..."
    local configFile="/etc/docker/daemon.json"
    local configFileConfig=""
    configFileConfig+="{\n"
    configFileConfig+="\t\"storage-driver\": \"devicemapper\"\n"
    configFileConfig+="}\n"
    # In some cases /etc/docker doesn't exist at this point, so create it
    if [[ ! -d "/etc/docker" ]]; then 
        mkdir "/etc/docker"
    fi
    if [[ ! -f "${configFile}" ]]; then
       printf "${configFileConfig}" >"${configFile}"
    else
        # If the file already exists, create a backup
        local tmpConfigFile=$(mktemp /etc/docker/daemon.json.XXX)
        logToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Do the install
function install() {

    local target="17.03"
    local version=""

    logToConsole "Installing Docker CE..."

    # CentOS/RHEL
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then

        # Only the repo names differ between CentOS and RHEL
        if [[ "${distro}" == "centos" ]]; then
            local baseRepo="base"
            local extrasRepo="extras"
        elif [[ "${distro}" == "rhel" ]]; then
            local baseRepo="rhel-7-server-rpms"
            local extrasRepo="rhel-7-server-extras-rpms"
        fi

        # Install prereqs
        log "***** Installing prerequisite packages..."
        yum -y --enablerepo "${baseRepo}" install "yum-utils" "device-mapper-persistent-data" "lvm2" || 
            exitWithError "Failed to install prerequisite packages"

        # Add Docker CE repo
        log "***** Adding Docker CE repo..."
        yum-config-manager --add-repo "https://download.docker.com/linux/centos/docker-ce.repo" || exitWithError "Failed to add docker-ce repo"

        # Update the package index
        log "***** Updating package index..."
        yum -y makecache fast || exitWithError "Failed to update the package index"

        # Get the latest version of docker target
        log "***** Getting the latest version of Docker CE target installation version ${target}..."
        version="$(yum -y list "docker-ce.x86_64" --showduplicates | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 
        log "***** Latest version available: ${version}"

        # Install Docker CE
        log "***** Performing Docker CE install..."
        yum -y --enablerepo "${extrasRepo}" --setopt=obsoletes=0 install "docker-ce-${version}" || exitWithError "Failed to install Docker CE components"

        # Configure direct-lvm, if requested (will use loop-lvm otherwise)
        log "***** Configuring direct-lvm..."
        if [[ -n "${directLvmDevice}" ]]; then
            configDirectLvm
        else
            configLoopLvm
        fi

    # Fedora
    elif [[ "${distro}" == "fedora" ]]; then

        # Install prereqs
        log "***** Installing prerequisite packages..."
        dnf -y --enablerepo "fedora" install "dnf-plugins-core" || exitWithError "Failed to install prerequisite packages"

        # Add Docker CE repo
        log "***** Adding Docker CE repo..."
        dnf -y config-manager --add-repo "https://download.docker.com/linux/fedora/docker-ce.repo" || exitWithError "Failed to add docker-ce repo"

        # Update the yum package index
        log "***** Updating package index..."
        dnf -y makecache fast || exitWithError "Failed to update the package index"

        # Get the latest version of docker target
        log "***** Getting the latest version of Docker CE target installation version ${target}..."
        version="$(dnf -y list "docker-ce" --showduplicates | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 
        log "***** Latest version available: ${version}"

        # Install Docker CE
        log "***** Performing Docker CE install..."
        dnf -y install "docker-ce-${version}" || exitWithError "Failed to install Docker CE components"

    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then

        # Install prereqs
        log "***** Installing prerequisite packages..."
        apt-get -y install "apt-transport-https" "ca-certificates" "curl" "gnupg2" "software-properties-common" ||
            exitWithError "Failed to install prerequisite packages"

        # Add Docker GPG key
        log "***** Adding Docker GPG key to apt..."
        curl -fsSL "https://download.docker.com/linux/${distro}/gpg" | apt-key add - || exitWithError "Failed to add Docker GPG key"

        # Add Docker repo
        log "***** Adding Docker CE repo..."
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${distro} $(lsb_release -cs) stable" ||
            exitWithError "Failed to add Docker repo"

        # Update the apt package index
        log "***** Updating package index..."
        apt-get -y update || exitWithError "Failed to update the package index"

        # Get the latest version of docker target
        log "***** Getting the latest version of Docker CE target installation version ${target}..."
        version="$(apt-cache madison "docker-ce" | \
            grep "${target}" | \
            sort -r | \
            head -1 | \
            awk -F '\\| ' '{print $2}' | \
            tr -d ' ')" 
        log "***** Latest version available: ${version}"

        # Install Docker CE
        log "***** Performing Docker CE install..."
        apt-get install -y "docker-ce=${version}" || exitWithError "Failed to install Docker CE components"

    fi

    logToConsole "Docker CE successfully installed"

}

# Configure systemd to automatically start docker
function configAutoStart() {

    if command -v systemctl; then
        systemctl enable "docker" || logToConsole "Failed to enable docker for auto-start. Manual configuration required"
        systemctl start "docker" || logToConsole "Failed to start docker. Manual start required"
    else
        logToConsole "This system does not use systemd. Manually configure docker to start"
    fi

}

init "${@}"

distro="$(getDistro)"
let osMajorVersion=$(getOSMajorVersion)
let osMinorVersion=$(getOSMinorVersion)

if [[ "${checkRequirements}" == "true" ]]; then
    # User just wants to check requirements and not do the install
    checkForRequirements
else
    # User wants to try the install
    log "***** Distro: ${distro}"
    log "***** Major version: ${osMajorVersion}"
    log "***** Minor version: ${osMinorVersion}"
    # If RHEL, --force must be provided to install
    if [[ "${distro}" == "rhel" ]]; then
        if [[ "${forceInstall}" != "true" ]]; then
            exitWithoutError "Docker CE is not officially supported on RHEL. To force installation anyway, use the --force option"
        fi
    fi
    checkPrereqs
    checkForObsoletePackages
    install
    configAutoStart
    # Run docker info to dump the config to the log
    log "***** Printing Docker configuration..."
    docker info
    logToConsole "Run 'sudo docker run hello-world' to confirm Docker is working normally"
fi 
