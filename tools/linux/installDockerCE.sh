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

    # Process the user arguments and set global variables
    dockerDataDir="/var/lib/docker"
    dockerConfigDir="/etc/docker"
    checkRequirements="false"
    forceRHELInstall="false"
    forceDMStorageDriver="false"
    directLvmDevice=""
    selectedStorageDriver=""
    while [[ ${#} > 0 ]]; do
        local key="${1}"
        local value="${2}"
        case "${key}" in
            --check)
                checkRequirements="true"
                shift;;
            --force-rhel-install)
                forceRHELInstall="true"
                shift;;
            --force-devicemapper)
                forceDMStorageDriver="true"
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

    local distro="$(getDistro)"

    printf "%-20s\t%-20s\t%-20s\n" "Requirement" "Found" "Requires" >&101
    printf "%-20s\t%-20s\t%-20s\n" "-----------" "-----" "--------" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Distro:" "${distro}" "centos, rhel*, fedora, debian or ubuntu" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Version:" "$(getOSMajorVersion).$(getOSMinorVersion)" \
           "7.x (centos and rhel), 25.x (fedora), 9.x (debian) or 16.04/16.10 (ubuntu)" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Machine architecture:" "$(getMachineArchitecture)" "x86_64" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Logical cores:" "$(getLogicalCores)" "At least 2" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Available memory:" "$(getAvailableMemory)" "At least 2097152" >&101
    printf "%-20s\t%-20s\t%-20s\n" "Total swap:" "$(getSwapMemory)" "Must be 0" >&101
    printf "\n" >&101
    if [[ "${distro}" == "rhel" ]]; then
        printf "*RHEL is not supported with Docker CE. You can install it anyway using the --force-rhel-install option\n" >&101
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

    logToConsole "Checking system for prereqs..."

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

    # Verify ${dockerDataDir} does not exist
    log "***** Checking to see if ${dockerDataDir} exists..."
    if [[ -d "${dockerDataDir}" ]]; then
        exitWithError "The ${dockerDataDir} directory already exists on this system. Back up and remove it before proceeding with the install"
    fi

}

# See if any obsolete packages are installed. If any are found, exit with direction to run uninstallDocker.sh
function checkForObsoletePackages() {

    local distro="$(getDistro)"
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

# Determine if this system can use overlay2
function canUseOverlay2StorageDriver() {

    # As this function is called in a subshell, need to explictly redirect the output to the log file
    exec 101>&1 && exec 1>>"${logFile}" 2>&1

    local canUseOverlay2="false"
    local distro="$(getDistro)"
    local osMajorVersion=$(getOSMajorVersion)
    local osMinorVersion=$(getOSMinorVersion)
    local fsType="$(getFSTypeForDirectory "${dockerDataDir}")"

    log "***** Checking to see if overlay2 storage driver can be used on this system..."

    # CentOS/RHEL
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if [[ "$(isKernelAtLeast "3.10.0-514")" == "true" ]]; then 
            if (( ${osMajorVersion} >= 7 && ${osMinorVersion} >= 2 )); then
                if [[ "${fsType}" == "xfs" ]]; then 
                    if [[ "$(isDTypeEnabledForDirectory "${dockerDataDir}")" == "true" ]]; then
                        canUseOverlay2="true"
                    fi
                fi
            elif (( ${osMajorVersion}== 7 && ${osMinorVersion} == 1 )); then
                if [[ "${fsType}" == "ext4" ]]; then
                    canUseOverlay2="true"
                fi
            fi
        fi
    # Fedora/Debian/Ubuntu
    else
        if [[ "$(isKernelAtLeast "4.0.0-000")" == "true" ]]; then 
            if [[ "${fsType}" == "xfs" ]]; then 
                if [[ "$(isDTypeEnabledForDirectory "${dockerDataDir}")" == "true" ]]; then
                    canUseOverlay2="true"
                fi
            elif [[ "${fsType}" == "ext4" ]]; then
                canUseOverlay2="true"
            fi
        fi
    fi

    # Print a report if the system does not meet requirements for overlay2
    if [[ "${canUseOverlay2}" == "false" ]]; then
        log "***** System does not meet requirements to use overlay2 storage driver"
        printf "%-20s\t%-20s\t%-20s\n" "Requirement" "Found" "Requires"
        printf "%-20s\t%-20s\t%-20s\n" "-----------" "-----" "--------"
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            printf "%-20s\t%-20s\t%-20s\n" "Kernel:" "$(uname -r)" "3.10.0-514 or later"
        else
            printf "%-20s\t%-20s\t%-20s\n" "Kernel:" "$(uname -r)" "4.0.0-000 or later"
        fi
        if (( ${osMajorVersion} >= 7 && ${osMinorVersion} >= 2 )); then
            # Get D-Type now to use in table
            if [[ "${fsType}" == "xfs" ]]; then
                local dtypeEnabled="$(isDTypeEnabledForDirectory "${dockerDataDir}")"
            else
                local dtypeEnabled="N/A"
            fi
            printf "%-20s\t%-20s\t%-20s\n" "FS Type:" "${fsType}" "xfs" 
            printf "%-20s\t%-20s\t%-20s\n" "D-Type enabled:" "${dtypeEnabled}" "true" 
        elif (( ${osMajorVersion} == 7 && ${osMinorVersion} == 1 )); then
            printf "%-20s\t%-20s\t%-20s\n" "FS Type:" "${fsType}" "ext4" 
        fi
    else
        log "***** System meets requirements to use overlay2 storage driver"
    fi

    # Reset FDs so output is returned to caller and not written to the log
    exec 1>&101 2>&1
    echo "${canUseOverlay2}"

}

# Determine if this system can use devicemapper with direct-lvm
function canUseDMDirectStorageDriver() {

    # As this function is called in a subshell, need to explictly redirect the output to the log file
    exec 101>&1 && exec 1>>"${logFile}" 2>&1

    local canUseDMDirect="false"

    log "***** Checking to see if devicemapper-direct storage driver can be used on this system..."

    # Can we use devicemapper in the direct-lvm configuration?
    if [[ -n "${directLvmDevice}" ]]; then
        # If lsblk isn't available, we can't continue checking
        if command -v lsblk >/dev/null 2>&1; then
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
            # Allow DM-direct if device is a disk or partition with no dependent devices and no filesystem
            if [[ ("${deviceType}" == "disk" || "${deviceType}" == "part") && "${deviceCount}" == 1 && "${deviceFSType}" == "<null>" ]]; then
                log "***** System meets requirements to use devicemapper storage driver with direct-lvm (Device: ${directLvmDevice})"
                canUseDMDirect="true"
            else
                # Print a report if the system does not meet requirements for devicemapper with direct-lvm
                log "***** System does not meet requirements to use devicemapper storage driver with direct-lvm (Device: ${directLvmDevice})"
                printf "%-20s\t%-20s\t%-20s\n" "Requirement" "Found" "Requires"
                printf "%-20s\t%-20s\t%-20s\n" "-----------" "-----" "--------"
                printf "%-20s\t%-20s\t%-20s\n" "Type:" "${deviceType}" "disk or part"
                printf "%-20s\t%-20s\t%-20s\n" "FS Type:" "${deviceFSType}" "<null>" 
                printf "%-20s\t%-20s\t%-20s\n" "Device count:" "${deviceCount}" "1" 
            fi
        else
            log "***** Unable to determine if system can use devicemapper-direct storage driver because lslbk command is missing"
        fi
    else
        log "***** The --direct-lvm-device <block device> option was not provided, so devicemapper-direct cannot be used"
    fi

    # Reset FDs so output is returned to caller and not written to the log
    exec 1>&101 2>&1
    echo "${canUseDMDirect}"

}

# Determine the storage driver to use. If devicemapper (direct-lvm or loop-lvm) are chosen, require user confirmation to proceed
function determineStorageDriver() {

    local canUseOverlay2="$(canUseOverlay2StorageDriver)"
    local canUseDMDirect="$(canUseDMDirectStorageDriver)"

    if [[ "${forceDMStorageDriver}" == "true" && "${canUseDMDirect}" == "true" ]]; then
        selectedStorageDriver="devicemapper-direct"
    elif [[ "${forceDMStorageDriver}" == "true" && "${canUseDMDirect}" == "false" ]]; then
        selectedStorageDriver="devicemapper-loop"
    elif [[ "${canUseOverlay2}" == "true" ]]; then
        selectedStorageDriver="overlay2"
    elif [[ "${canUseDMDirect}" == "true" ]]; then
        selectedStorageDriver="devicemapper-direct"
    else
        selectedStorageDriver="devicemapper-loop"
    fi

    log "***** Selected storage driver ${selectedStorageDriver}"

    # Handle user confirmation
    if [[ "${selectedStorageDriver}" == "overlay2" && "${canUseDMDirect}" == "true" ]]; then
        # Ask for confirmation since user specified a direct-lvm device but overlay2 was chosen (because it is preferred)
        logToConsole "WARNING! This system supports both overlay2 and devicemapper (direct-lvm). The overlay2 driver has been chosen because it is"
        logToConsole "recommended by Docker. However, --direct-lvm-device <block device> was specified on the command line. To force the use"
        logToConsole "of devicemapper (direct-lvm), add the --force-devicemapper option."
        logToConsole ""
        read -p "To continue installation with overlay2, type 'yes' and press Enter: " answer1 2>&101
        if [[ ! -z "${answer1}" && "${answer1}" == "yes" ]]; then
            log "***** Continuing install with overlay2 storage driver..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi
    elif [[ "${selectedStorageDriver}" == "devicemapper-direct" ]]; then
        # Since this is destructive, ask for confirmation. The checks should ensure not data is lost, but ask anyway, just in case
        logToConsole "WARNING! The --direct-lvm-device option will destroy all existing data on ${directLvmDevice}."
        logToConsole ""
        read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer2 2>&101
        if [[ ! -z "${answer2}" && "${answer2}" == "yes" ]]; then
            log "***** Allowing direct-lvm configuration for device ${directLvmDevice}..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi
    elif [[ "${selectedStorageDriver}" == "devicemapper-loop" ]]; then
        # Since this is not recommended, ask for confirmation
        logToConsole "WARNING! Attempting to install with the devicemapper driver in the loop-lvm configuration."
        logToConsole "Docker strongly discourages using loop-lvm for production workloads."
        logToConsole ""
        read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer3 2>&101
        if [[ ! -z "${answer3}" && "${answer3}" == "yes" ]]; then
            log "***** Allowing loop-lvm configuration..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi
    fi

}

# Do the install
function install() {

    local distro="$(getDistro)"
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

# Configure overlay2
function configOverlay2() {

    local configFile="${dockerConfigDir}/daemon.json"
    local configFileConfig=""

    # If kernel is < 4.0.0-000, overlay2.override_kernel_check=true is needed in daemon.json
    if [[ "$(isKernelAtLeast "4.0.0-000")" == "false" ]]; then
        configFileConfig+="{\n"
        configFileConfig+="\t\"storage-driver\": \"overlay2\",\n"
        configFileConfig+="\t\"storage-opts\": [\n"
        configFileConfig+="\t\t\"overlay2.override_kernel_check=true\"\n"
        configFileConfig+="\t]\n"
        configFileConfig+="}\n"
    else
        configFileConfig+="{\n"
        configFileConfig+="\t\"storage-driver\": \"overlay2\"\n"
        configFileConfig+="}\n"
    fi

    log "***** Configuring overlay2 storage driver..."

    # In some cases ${dockerConfigDir} doesn't exist at this point, so create it
    if [[ ! -d "${dockerConfigDir}" ]]; then 
        mkdir "${dockerConfigDir}"
    fi

    # See if the config file already exists
    if [[ ! -f "${configFile}" ]]; then
       printf "${configFileConfig}" >"${configFile}"
    else
        # If the file already exists, create a backup
        local tmpConfigFile=$(mktemp ${dockerConfigDir}/daemon.json.XXX)
        logToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure devicemapper for direct-lvm
function configDirectLvm() {

    log "***** Configuring devicemapper (direct-lvm) storage driver..."

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

    # Configure devicemapper for direct-lvm mode
    log "***** Configuring devicemapper storage driver for direct-lvm..."
    local configFile="${dockerConfigDir}/daemon.json"
    local configFileConfig=""
    configFileConfig+="{\n"
    configFileConfig+="\t\"storage-driver\": \"devicemapper\",\n"
    configFileConfig+="\t\"storage-opts\": [\n"
    configFileConfig+="\t\t\"dm.thinpooldev=/dev/mapper/docker-thinpool\",\n"
    configFileConfig+="\t\t\"dm.use_deferred_removal=true\"\n"
    configFileConfig+="\t]\n"
    configFileConfig+="}\n"
    # In some cases ${dockerConfigDir} doesn't exist at this point, so create it
    if [[ ! -d "${dockerConfigDir}" ]]; then 
        mkdir "${dockerConfigDir}"
    fi
    if [[ ! -f "${configFile}" ]]; then
       printf "${configFileConfig}" >"${configFile}"
    else
        # If the file already exists, create a backup
        local tmpConfigFile=$(mktemp ${dockerConfigDir}/daemon.json.XXX)
        logToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure devicemapper for loop-lvm
function configLoopLvm() {

    local configFile="${dockerConfigDir}/daemon.json"
    local configFileConfig=""
    configFileConfig+="{\n"
    configFileConfig+="\t\"storage-driver\": \"devicemapper\"\n"
    configFileConfig+="}\n"

    log "***** Configuring devicemapper (loop-lvm) storage driver..."

    # In some cases ${dockerConfigDir} doesn't exist at this point, so create it
    if [[ ! -d "${dockerConfigDir}" ]]; then 
        mkdir "${dockerConfigDir}"
    fi
    if [[ ! -f "${configFile}" ]]; then
       printf "${configFileConfig}" >"${configFile}"
    else
        # If the file already exists, create a backup
        local tmpConfigFile=$(mktemp ${dockerConfigDir}/daemon.json.XXX)
        logToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure the storage driver
function configStorageDriver() {

    if [[ "${selectedStorageDriver}" == "overlay2" ]]; then
        configOverlay2
    elif [[ "${selectedStorageDriver}" == "devicemapper-direct" ]]; then
        configDirectLvm
    elif [[ "${selectedStorageDriver}" == "devicemapper-loop" ]]; then
        configLoopLvm
    fi

}

# Configure systemd to automatically start docker
function configAutoStart() {

    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable "docker" || logToConsole "Failed to enable docker for auto-start. Manual configuration required"
        systemctl start "docker" || logToConsole "Failed to start docker. Manual start required"
    else
        logToConsole "This system does not use systemd. Manually configure docker to start"
    fi

}

init "${@}"

distro="$(getDistro)"

if [[ "${checkRequirements}" == "true" ]]; then
    # User just wants to check requirements and not do the install
    checkForRequirements
else
    # User wants to try the install
    log "***** Distro: ${distro}"
    log "***** Major version: $(getOSMajorVersion)"
    log "***** Minor version: $(getOSMinorVersion)"
    # If RHEL, --force-rhel-install must be provided to install
    if [[ "${distro}" == "rhel" ]]; then
        if [[ "${forceRHELInstall}" != "true" ]]; then
            exitWithoutError "Docker CE is not officially supported on RHEL. To force installation anyway, use the --force-rhel-install option"
        fi
    fi
    checkPrereqs
    checkForObsoletePackages
    determineStorageDriver
    install
    configStorageDriver
    configAutoStart
    # Run docker info to dump the config to the log
    log "***** Printing Docker configuration..."
    docker info
    logToConsole "Run 'sudo docker run hello-world' to confirm Docker is working normally"
fi 
