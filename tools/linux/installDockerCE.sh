#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installDockerCE.log"
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
    checkRequirements="false"
    forceRHELInstall="false"
    forceDMStorageDriver="false"
    forceAufsStorageDriver="false"    
    directLvmDevice=""
    selectedStorageDriver=""

    while [[ ${#} > 0 ]]; do
        local key="${1}"
        local value="${2}"
        case "${key}" in
            --help)
                usage
                exit 0
                shift;;
            --check)
                checkRequirements="true"
                shift;;
            --force-rhel-install)
                forceRHELInstall="true"
                shift;;
            --force-aufs)
                forceAufsStorageDriver="true"
                shift;;
            --force-devicemapper)
                forceDMStorageDriver="true"
                shift;;
            --direct-lvm-device)
                directLvmDevice="${value}"
                shift;shift;;
            *)
                printToConsole "Unrecognized argument ${key}"
                exit 1
        esac
    done

    # Can't have both --force-devicemapper and --force-aufs
    if [[ "${forceDMStorageDriver}" == "true" && "${forceAufsStorageDriver}" == "true" ]]; then
        exitWithError "The --force-devicemapper and --force-aufs options cannot be used together"
    fi

    # If RHEL, --force-rhel-install must be provided to install
    if [[ "$(getDistro)" == "rhel" ]]; then
        if [[ "${forceRHELInstall}" != "true" ]]; then
            exitWithoutError "Docker CE is not officially supported on RHEL. To force installation anyway, use the --force-rhel-install option"
        fi
    fi

    # Print log header
    printToLog "Distro: $(getDistro)"
    printToLog "Major version: $(getOSMajorVersion)"
    printToLog "Minor version: $(getOSMinorVersion)"

}

# Print the usage text to the console
function usage() {

    printToConsole "Usage: installDockerCE.sh [OPTIONS]"
    printToConsole ""
    printToConsole "Options:"
    printToConsole ""
    printToConsole "--check"
    printToConsole ""
    printToConsole "Checks the system to see if meets the requirement to install Component Pack components."
    printToConsole ""
    printToConsole "--force-rhel-install"
    printToConsole ""
    printToConsole "RHEL is not supported with Docker CE. Use this option to install anyway."
    printToConsole ""
    printToConsole "--force-aufs"
    printToConsole ""
    printToConsole "Override check for best storage driver and force the use of aufs."
    printToConsole ""
    printToConsole "--force-devicemapper"
    printToConsole ""
    printToConsole "Override check for best storage driver and force the use of devicemapper."
    printToConsole ""
    printToConsole "--direct-lvm-device <block device>"
    printToConsole ""
    printToConsole "Provide a block device to use for configuring devicemapper in the direct-lvm mode."
    printToConsole "Include with --check to see if the system supports devicemapper with direct-lvm."

}

# Print to the console (and to the log)
function printToConsole() {

    local message="${1}"

	printf "%s\n" "${message}" >&101
    printToLog "${message}"

}

# Print to the log
function printToLog() {

    local message="${1}"
    local now="$(date '+%F %T')"

	printf "%s %s\n" "${now}" "${message}" >>"${logFile}"

}

# Exit with error code and the supplied error message
function exitWithError() {

    local message="${1}"

    printToConsole "${message}."
    printToConsole "Review ${logFile} for additional details"
    exit 1

}

# Exit without error code and with the supplied message 
function exitWithoutError() {

    local message="${1}"

    printToConsole "${message}"
    exit 0

}

# Print a table of requirements if the user requested it via the --check option
function checkForRequirements() {

    local canUseOverlay2="$(canUseOverlay2StorageDriver)"
    local canUseAufs="$(canUseAufsStorageDriver)"
    local canUseDMDirect="$(canUseDMDirectStorageDriver)"

    # Format for output
    if [[ "${canUseOverlay2}" == "true" ]]; then canUseOverlay2="Yes"; else canUseOverlay2="No"; fi
    if [[ "${canUseAufs}" == "true" ]]; then canUseAufs="Yes"; else canUseAufs="No"; fi
    if [[ "${canUseDMDirect}" == "true" ]]; then canUseDMDirect="Yes"; else canUseDMDirect="No"; fi

    # Pass the file descriptor that points to the terminal
    printCPRequirementsTable "101"

    printf "\n" >&101
    printf "%-20s\t%-20s\n" "Storage driver" "Available" >&101
    printf "%-20s\t%-20s\n" "--------------" "---------" >&101
    printf "%-20s\t%-20s\n" "overlay2" "${canUseOverlay2}" >&101
    printf "%-20s\t%-20s\n" "aufs" "${canUseAufs}" >&101
    printf "%-20s\t%-20s\n" "devicemapper-direct" "${canUseDMDirect}" >&101
    printf "%-20s\t%-20s\n" "devicemapper-loop" "Yes" >&101
    printf "\n" >&101

    if [[ "${distro}" == "rhel" ]]; then
        printf "*RHEL is not supported with Docker CE. You can install it anyway using the --force-rhel-install option.\n" >&101
    fi

}

# Test prereqs for install. Any checks that do not pass exit immediately
function checkForPrereqs() {

    printToConsole "Checking to ensure system has all prerequisites in place to install Docker CE..."

    # Check the platform requirements
    printToLog "Checking to see if platform meets requirements to install Component Pack..."
    if [[ "$(isCPSupportedPlatform)" == "false" ]]; then 
        exitWithError "Requirements not met to install Component Pack. Use the --check option to print requirements"
    fi
    
    # Verify Docker is not already installed
    printToLog "Checking to see if Docker CE is already installed..."
    if [[ "$(isDockerCEInstalled)" == "true" ]]; then 
        exitWithError "Docker CE is already installed"
    fi

    # Verify ${dockerDataDir} does not exist
    printToLog "Checking to see if ${dockerDataDir} exists..."
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
        printToLog "Checking to see if obsolete package ${obsoletePackage} is installed..."
        # yum
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            if yum list installed "${obsoletePackage}"; then 
                exitWithError "Package ${obsoletePackage} is installed. Run uninstallDocker.sh to remove obsolete packages"
            fi
        # dnf
        elif [[ "${distro}" == "fedora" ]]; then
            if dnf list installed "${obsoletePackage}"; then 
                exitWithError "Package ${obsoletePackage} is installed. Run uninstallDocker.sh to remove obsolete packages"
            fi
        # apt
        elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
            if dpkg-query --list "${obsoletePackage}"; then 
                exitWithError "Package ${obsoletePackage} is installed. Run uninstallDocker.sh to remove obsolete packages"
            fi
        fi
    done

}

# Determine if this system can use overlay2. Intended to be called in a subshell only, hence the fds need to be manipulated on enter/exit
function canUseOverlay2StorageDriver() {

    # As this function is called in a subshell, need to explicitly redirect the output to the log file
    exec 101>&1 && exec 1>>"${logFile}" 2>&1

    local canUseOverlay2="false"
    local distro="$(getDistro)"
    local osMajorVersion=$(getOSMajorVersion)
    local osMinorVersion=$(getOSMinorVersion)
    local fsType="$(getFSTypeForDirectory "${dockerDataDir}")"

    printToLog "Checking to see if overlay2 storage driver can be used on this system..."

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
        printToLog "System does not meet requirements to use overlay2 storage driver"
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
        printToLog "System meets requirements to use overlay2 storage driver"
    fi

    # Reset FDs so output is returned to caller and not written to the log
    exec 1>&101 2>&1

    echo "${canUseOverlay2}"

}

# Determine if this system can use devicemapper-direct. Intended to be called in a subshell only, hence the fds need to be manipulated on enter/exit
function canUseDMDirectStorageDriver() {

    # As this function is called in a subshell, need to explicitly redirect the output to the log file
    exec 101>&1 && exec 1>>"${logFile}" 2>&1

    local canUseDMDirect="false"

    printToLog "Checking to see if devicemapper-direct storage driver can be used on this system..."

    # A --direct-lvm-device device must have been provided
    if [[ -n "${directLvmDevice}" ]]; then
        # If lsblk isn't available, we can't continue checking, so devicemapper-direct can't be used
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
            # Device must be a disk or partition with a device count of 1 (no dependent devices) and have no filesystem
            if [[ ("${deviceType}" == "disk" || "${deviceType}" == "part") && "${deviceCount}" == 1 && "${deviceFSType}" == "<null>" ]]; then
                # Make sure there are no lvm PV/VG/LV conflicts
                if command -v pvdisplay >/dev/null 2>&1 && command -v vgdisplay >/dev/null 2>&1 && command -v lvdisplay >/dev/null 2>&1; then
                    printToLog "Checking to see if there are any physical volumes named ${directLvmDevice}..."
                    if ! pvdisplay "${directLvmDevice}"; then
                        printToLog "Checking to see if there are any volume groups named 'docker'..."
                        if ! vgdisplay "docker"; then
                            printToLog "Checking to see if there are any logical volumes in the 'docker' volume group..."
                            if ! lvdisplay "docker" | grep "docker"; then
                                printToLog "System meets requirements to use devicemapper-direct (Device: ${directLvmDevice})"
                                canUseDMDirect="true"
                            else
                                printToLog "Unable to use devicemapper-direct due to logical volume conflict" 
                            fi
                        else
                            printToLog "Unable to use devicemapper-direct due to volume group conflict"
                        fi
                    else
                        printToLog "Unable to use devicemapper-direct due to physical volume conflict"
                    fi
                else
                    # lvm commands don't exist, so there can't be any PV/VG/LV conflicts 
                    printToLog "System meets requirements to use devicemapper-direct (Device: ${directLvmDevice})"
                    canUseDMDirect="true"
                fi
            else
                # Print a report if the device does not meet requirements for devicemapper-direct
                printToLog "Device ${directLvmDevice} does not meet requirements to use devicemapper-direct storage driver"
                printf "%-20s\t%-20s\t%-20s\n" "Requirement" "Found" "Requires"
                printf "%-20s\t%-20s\t%-20s\n" "-----------" "-----" "--------"
                printf "%-20s\t%-20s\t%-20s\n" "Type:" "${deviceType}" "disk or part"
                printf "%-20s\t%-20s\t%-20s\n" "FS Type:" "${deviceFSType}" "<null>" 
                printf "%-20s\t%-20s\t%-20s\n" "Device count:" "${deviceCount}" "1" 
            fi
        else
            printToLog "Unable to determine if system can use devicemapper-direct storage driver because lslbk command is missing"
        fi
    else
        printToLog "The --direct-lvm-device <block device> option was not provided, so devicemapper-direct cannot be used"
    fi

    # Reset FDs so output is returned to caller and not written to the log
    exec 1>&101 2>&1

    echo "${canUseDMDirect}"

}

# Determine if this system can use aufs. Intended to be called in a subshell only, hence the fds need to be manipulated on enter/exit
function canUseAufsStorageDriver() {

    # As this function is called in a subshell, need to explicitly redirect the output to the log file
    exec 101>&1 && exec 1>>"${logFile}" 2>&1

    local canUseAufs="false"
    local distro="$(getDistro)"
    local fsType="$(getFSTypeForDirectory "${dockerDataDir}")"
    local kernelDriver=$(grep -c "aufs" "/proc/filesystems")

    # Convert kernelDriver to "true" or "false"
    if (( ${kernelDriver} == 0 )); then
        kernelDriver="false"
    else
        kernelDriver="true"
    fi

    printToLog "Checking to see if aufs storage driver can be used on this system..."

    # Only for Debian/Ubuntu
    if [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if [[ "${fsType}" == "xfs" || "${fsType}" == "ext4" ]]; then
            if grep aufs /proc/filesystems >/dev/null 2>&1; then
                printToLog "System meets requirements to use aufs storage driver"
                canUseAufs="true"
            fi
        fi
    else
        # Print a report if the system does not meet requirements for aufs
        printToLog "System does not meet requirements to use aufs storage driver"
        printf "%-20s\t%-20s\t%-20s\n" "Requirement" "Found" "Requires"
        printf "%-20s\t%-20s\t%-20s\n" "-----------" "-----" "--------"
        printf "%-20s\t%-20s\t%-20s\n" "Distro:" "${distro}" "debian or ubuntu"
        printf "%-20s\t%-20s\t%-20s\n" "FS Type:" "${fsType}" "xfs or ext4" 
        printf "%-20s\t%-20s\t%-20s\n" "Kernel aufs driver:" "${kernelDriver}" "true" 
    fi

    # Reset FDs so output is returned to caller and not written to the log
    exec 1>&101 2>&1

    echo "${canUseAufs}"

}

# Determine the storage driver to use
function determineStorageDriver() {

    local canUseOverlay2="$(canUseOverlay2StorageDriver)"
    local canUseAufs="$(canUseAufsStorageDriver)"
    local canUseDMDirect="$(canUseDMDirectStorageDriver)"

    if [[ "${forceAufsStorageDriver}" == "true" && "${canUseAufs}" == "true" ]]; then
        selectedStorageDriver="aufs"
    elif [[ "${forceDMStorageDriver}" == "true" && "${canUseDMDirect}" == "true" ]]; then
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

    printToLog "Selected storage driver ${selectedStorageDriver}"

    # Handle user confirmation
    local answer=""

    # --force-devicemapper was specified but devicemapper-direct cannot be configured
    if [[ "${forceDMStorageDriver}" == "true" && "${canUseDMDirect}" == "false" ]]; then
        printToConsole "WARNING! The --force-devicemapper option was provided, but devicemapper-direct cannot be configured. Docker strongly discourages"
        printToConsole "using devicemapper-loop for production workloads."
        printToConsole ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>&101
        if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
            printToLog "Continuing install with ${selectedStorageDriver} driver..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi

    # --force-aufs was specified but is not supported
    elif [[ "${forceAufsStorageDriver}" == "true" && "${canUseAufs}" == "false" ]]; then
        printToConsole "WARNING! The --force-aufs option was provided, but aufs is not supported on this system."
        printToConsole ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>&101
        if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
            printToLog "Continuing install with ${selectedStorageDriver} driver..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi

    # --direct-lvm-device was specified, it can be configured, but overlay2 or aufs were selected
    elif [[ -n "${directLvmDevice}" && "${canUseDMDirect}" == "true" && 
              ("${selectedStorageDriver}" == "overlay2" || "${selectedStorageDriver}" == "aufs")  ]]; then
        printToConsole "WARNING! The ${selectedStorageDriver} driver has been selected because it is recommended by Docker. However, this system can also"
        printToConsole "be configured with devicemapper-direct. To force the use of devicemapper-direct, add the --force-devicemapper option."
        printToConsole ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>&101
        if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
            printToLog "Continuing install with ${selectedStorageDriver} storage driver..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi

    # --direct-lvm-device was specified, it cannot be configured, and overlay2 or aufs were selected
    elif [[ -n "${directLvmDevice}" && "${canUseDMDirect}" == "false" &&
              ("${selectedStorageDriver}" == "overlay2" || "${selectedStorageDriver}" == "aufs") ]]; then
        printToConsole "WARNING! The ${selectedStorageDriver} driver has been selected because it is recommended by Docker and because"
        printToConsole "this system cannot be configured with devicemapper-direct."
        printToConsole ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>&101
        if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
            printToLog "Continuing install with ${selectedStorageDriver} storage driver..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi

    # --direct-lvm-device was specified, it can be configured, and devicemapper-direct was selected
    elif [[ -n "${directLvmDevice}" && "${canUseDMDirect}" == "true" && "${selectedStorageDriver}" == "devicemapper-direct" ]]; then
        printToConsole "WARNING! The ${selectedStorageDriver} driver has been selected. All existing data on ${directLvmDevice} will be destroyed."
        printToConsole ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>&101
        if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
            printToLog "Continuing install with ${selectedStorageDriver} storage driver..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi

    # --direct-lvm-device was specified, it cannot be configured, and devicemapper-loop was selected
    elif [[ -n "${directLvmDevice}" && "${canUseDMDirect}" == "false" && "${selectedStorageDriver}" == "devicemapper-loop" ]]; then
        printToConsole "WARNING! The ${selectedStorageDriver} driver has been selected because this system cannot be configured with"
        printToConsole "devicemapper-direct. Docker strongly discourages using ${selectedStorageDriver} for production workloads."
        printToConsole ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>&101
        if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
            printToLog "Continuing install with ${selectedStorageDriver} storage driver..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi

    # Do a final confirmation if we get this far and devicemapper-loop is the selected driver
    elif [[ "${selectedStorageDriver}" == "devicemapper-loop" ]]; then
        printToConsole "WARNING! The ${selectedStorageDriver} driver has been selected. Docker strongly discourages using ${selectedStorageDriver}"
        printToConsole "for production workloads."
        printToConsole ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>&101
        if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
            printToLog "Continuing install with ${selectedStorageDriver} storage driver..."
        else
            exitWithoutError "Aborting Docker CE install"
        fi
    fi

}

# Do the install
function install() {

    local distro="$(getDistro)"
    local version=""

    printToConsole "Installing Docker CE..."

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
        printToLog "Installing prerequisite packages..."
        yum -y --enablerepo "${baseRepo}" install \
            "device-mapper-persistent-data" \
            "lvm2" \
            "yum-plugin-versionlock" \
            "yum-utils" \
            || exitWithError "Failed to install prerequisite packages"

        # Add Docker CE repo
        printToLog "Adding Docker CE repo..."
        yum-config-manager --add-repo "https://download.docker.com/linux/centos/docker-ce.repo" || exitWithError "Failed to add docker-ce repo"

        # Update the package index
        printToLog "Updating package index..."
        yum -y makecache fast || exitWithError "Failed to update the package index"

        # Get the latest version of docker target
        printToLog "Getting the latest version of Docker CE target installation version ${CP_DOCKER_SUPPORTED_RELEASE}..."
        version="$(yum -y list "docker-ce.x86_64" --showduplicates | \
            grep "${CP_DOCKER_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 
        printToLog "Latest version available: ${version}"

        # Install Docker CE
        printToLog "Performing Docker CE install..."
        yum -y --enablerepo "${extrasRepo}" --setopt=obsoletes=0 install "docker-ce-${version}" || exitWithError "Failed to install Docker CE components"

        # Lock the Docker CE package
        printToLog "Locking the docker-ce package to prevent auto-update..."
        yum versionlock add "docker-ce"

    # Fedora
    elif [[ "${distro}" == "fedora" ]]; then

        # Install prereqs
        printToLog "Installing prerequisite packages..."
        dnf -y --enablerepo "fedora" install \
            "device-mapper-persistent-data" \
            "dnf-plugins-core" \
            "lvm2" \
            "dnf-plugins-extras-versionlock" \
            || exitWithError "Failed to install prerequisite packages"

        # Add Docker CE repo
        printToLog "Adding Docker CE repo..."
        dnf -y config-manager --add-repo "https://download.docker.com/linux/fedora/docker-ce.repo" || exitWithError "Failed to add docker-ce repo"

        # Update the yum package index
        printToLog "Updating package index..."
        dnf -y makecache fast || exitWithError "Failed to update the package index"

        # Get the latest version of docker target
        printToLog "Getting the latest version of Docker CE target installation version ${CP_DOCKER_SUPPORTED_RELEASE}..."
        version="$(dnf -y list "docker-ce" --showduplicates | \
            grep "${CP_DOCKER_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 
        printToLog "Latest version available: ${version}"

        # Install Docker CE
        printToLog "Performing Docker CE install..."
        dnf -y install "docker-ce-${version}" || exitWithError "Failed to install Docker CE components"

        # Lock the Docker CE package
        printToLog "Locking the docker-ce package to prevent auto-update..."
        dnf versionlock add "docker-ce"

    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then

        # Install prereqs
        printToLog "Installing prerequisite packages..."
        apt-get -y install \
            "apt-transport-https" \
            "ca-certificates" \
            "curl" \
            "gnupg2" \
            "lvm2" \
            "software-properties-common" \
            "thin-provisioning-tools" \
            || exitWithError "Failed to install prerequisite packages"

        # Add Docker GPG key
        printToLog "Adding Docker GPG key to apt..."
        curl -fsSL "https://download.docker.com/linux/${distro}/gpg" | apt-key add - || exitWithError "Failed to add Docker GPG key"

        # Add Docker repo
        printToLog "Adding Docker CE repo..."
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${distro} $(lsb_release -cs) stable" ||
            exitWithError "Failed to add Docker repo"

        # Update the apt package index
        printToLog "Updating package index..."
        apt-get -y update || exitWithError "Failed to update the package index"

        # Get the latest version of docker target
        printToLog "Getting the latest version of Docker CE target installation version ${CP_DOCKER_SUPPORTED_RELEASE}..."
        version="$(apt-cache madison "docker-ce" | \
            grep "${CP_DOCKER_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk -F '\\| ' '{print $2}' | \
            tr -d ' ')" 
        printToLog "Latest version available: ${version}"

        # Install Docker CE
        printToLog "Performing Docker CE install..."
        apt-get install -y "docker-ce=${version}" || exitWithError "Failed to install Docker CE components"

        # Lock the Docker CE package
        printToLog "Locking the docker-ce package to prevent auto-update..."
        apt-mark hold "docker-ce"

    fi

    # Stop Docker if it was started automatically following installed (happens on Debian, for example). Needs to be stopped to config storage driver
    printToLog "Stopping Docker..."
    if command -v systemctl >/dev/null 2>&1; then
        systemctl stop "docker"
    fi

    printToConsole "Docker CE successfully installed"

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

    printToLog "Configuring overlay2 storage driver..."

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
        printToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure devicemapper-direct
function configDirectLvm() {

    printToLog "Configuring devicemapper-direct storage driver..."

    # Create the Physical Volume
    printToLog "Creating PV ${directLvmDevice}..."
    pvcreate -y "${directLvmDevice}" || exitWithError "Failed to create ${directLvmDevice} PV"

    # Create the Volume Group
    printToLog "Creating VG docker..."
    vgcreate -y "docker" "${directLvmDevice}" || exitWithError "Failed to create docker VG"

    # Create the Logical Volumes
    printToLog "Creating LV thinpool..."
    lvcreate -y --wipesignatures "y" --name "thinpool" --extents "95%VG" "docker" || exitWithError "Failed to create thinpool LV"
    printToLog "Creating LV thinpoolmeta..."
    lvcreate -y --wipesignatures "y" --name "thinpoolmeta" --extents "1%VG" "docker" || exitWithError "Failed to create thinpoolmeta LV"

    # Convert the Logical Volumes to thin pools
    printToLog "Converting LVs to thin pool..."
    lvconvert -y --zero "n" --chunksize "512K" --thinpool "docker/thinpool" --poolmetadata "docker/thinpoolmeta" ||
        exitWithError "Failed to convert LVs to thin pool"

    # Create the LVM profile
    printToLog "Creating LVM profile..."
    local lvmProfile="/etc/lvm/profile/docker-thinpool.profile"
    local lvmProfileDir="/etc/lvm/profile"
    local lvmProfileConfig="activation {\n\tthin_pool_autoextend_threshold=80\n\tthin_pool_autoextend_percent=20\n}\n"
    # In some cases ${lvmProfileDir} doesn't exist at this point, so create it
    if [[ ! -d "${lvmProfileDir}" ]]; then 
        mkdir "${lvmProfileDir}"
    fi
    if [[ ! -f "${lvmProfile}" ]]; then
       printf "${lvmProfileConfig}" >"${lvmProfile}" 
    else
        # If the file already exists, create a backup
        local tmpLvmProfile=$(mktemp /etc/lvm/profile/docker-thinpool.profile.XXX)
        printToConsole "An existing ${lvmProfile} was found. Backing it up as ${tmpLvmProfile} and creating a new one..." 
        mv "${lvmProfile}" "${tmpLvmProfile}"
        printf "${lvmProfileConfig}" >"${lvmProfile}" 
    fi

    # Apply the LVM profile
    printToLog "Applying LVM profile..."
    lvchange -y --metadataprofile "docker-thinpool" "docker/thinpool" || exitWithError "Failed to apply LVM profile"

    # Enable monitoring for Logical Volumes
    printToLog "Enabling monitoring for LVs..."
    lvs -y --options "+seg_monitor" || exitWithError "Failed to enable LVs for monitoring"

    # Configure Docker to use devicemapper-direct
    printToLog "Configuring devicemapper-direct storage driver..."
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
    # See if the config file already exists
    if [[ ! -f "${configFile}" ]]; then
       printf "${configFileConfig}" >"${configFile}"
    else
        # If the file already exists, create a backup
        local tmpConfigFile=$(mktemp ${dockerConfigDir}/daemon.json.XXX)
        printToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure devicemapper-loop
function configLoopLvm() {

    local configFile="${dockerConfigDir}/daemon.json"
    local configFileConfig=""

    configFileConfig+="{\n"
    configFileConfig+="\t\"storage-driver\": \"devicemapper\"\n"
    configFileConfig+="}\n"

    printToLog "Configuring devicemapper-loop storage driver..."

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
        printToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure aufs (stub function in case configuration is required at some point)
function configAufs() {

    local configFile="${dockerConfigDir}/daemon.json"
    local configFileConfig=""

    configFileConfig+="{\n"
    configFileConfig+="\t\"storage-driver\": \"aufs\"\n"
    configFileConfig+="}\n"

    printToLog "Configuring aufs storage driver..."

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
        printToConsole "An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..." 
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
    elif [[ "${selectedStorageDriver}" == "aufs" ]]; then
        configAufs
    fi

}

# Configure systemd to automatically start docker
function configAutoStart() {

    if command -v systemctl >/dev/null 2>&1; then
        printToLog "Enabling auto-start for docker..."
        systemctl enable "docker" || printToConsole "Failed to enable docker for auto-start. Manual configuration required"
        printToConsole "Starting docker..."
        systemctl start "docker" || printToConsole "Failed to start docker. Manual start required"
    else
        printToConsole "This system does not use systemd. Manually configure docker to start"
    fi

}

init "${@}"

if [[ "${checkRequirements}" == "true" ]]; then
    # Just check requirements
    checkForRequirements
else
    # Do the install
    checkForPrereqs
    checkForObsoletePackages
    determineStorageDriver
    install
    configStorageDriver
    configAutoStart
    printToLog "Printing Docker configuration..."
    docker info
    printToConsole "Run 'sudo docker run hello-world' to confirm Docker is working normally"
fi 
