#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installDocker.log"
    >|"${logFile}"

    # Redirect output to the log. Point 101 to the original 1 so some output can be sent to the terminal
    exec 101>&1
    exec 1>>"${logFile}" 2>&1
    terminal="/proc/${BASHPID}/fd/101"

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
    isRegistryNode="false"
    warnings="false"

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
            --registry-node)
                isRegistryNode="true"
                shift;;
            --direct-lvm-device)
                directLvmDevice="${value}"
                shift;shift;;
            *)
                outputToTerminal "Unrecognized argument ${key}"
                exit 1
        esac
    done

    # Can't have both --force-devicemapper and --force-aufs
    if [[ "${forceDMStorageDriver}" == "true" && "${forceAufsStorageDriver}" == "true" ]]; then
        exitWithError "The --force-devicemapper and --force-aufs options cannot be used together"
    fi

}

# Print the usage text to the terminal
function usage() {

    outputToTerminal "Usage: installDocker.sh [OPTIONS]"
    outputToTerminal ""
    outputToTerminal "Options:"
    outputToTerminal ""
    outputToTerminal "--check"
    outputToTerminal "  Checks the system to see if meets the requirement to install Component Pack components."
    outputToTerminal ""
    outputToTerminal "--force-rhel-install"
    outputToTerminal "  RHEL is not supported with docker-ce. Use this option to install anyway."
    outputToTerminal ""
    outputToTerminal "--force-aufs"
    outputToTerminal "  Override check for best storage driver and force the use of aufs."
    outputToTerminal ""
    outputToTerminal "--force-devicemapper"
    outputToTerminal "  Override check for best storage driver and force the use of devicemapper."
    outputToTerminal ""
    outputToTerminal "--direct-lvm-device <block device>"
    outputToTerminal "  Provide a block device to use for configuring devicemapper in the direct-lvm mode."
    outputToTerminal "  Include with --check to see if the system supports devicemapper with direct-lvm."
    outputToTerminal ""
    outputToTerminal "--registry-node"
    outputToTerminal "  Deploy a local Docker registry on this node."

}

# Write a message to the log file
function outputToLog() {
    
    local message="${1}"
    
    outputTS "${message}" "${logFile}"

}

# Write a message to the terminal
function outputToTerminal() {

    local message="${1}"
    
    output "${message}" "${terminal}"

}

# Write operation message to log and terminal
function outputOperation() {

    local message="${1}"
    local leftColumnTerminal="%-120.120s"
    local leftColumnLog="%-120.120s\n"

    outputFormattedTS "${message}" "${leftColumnTerminal}" "${terminal}"
    outputFormattedTS "${message}" "${leftColumnLog}" "${logFile}"

}

# Print a failure message
function fail() {

    local redText=$'\e[1;31m'
    local normalText=$'\e[0m'
    local rightAlign="%-6s\n\n"

    # To terminal
    outputFormatted "${redText}Failed${normalText}" "${rightAlign}" "${terminal}"
    outputToTerminal "Review ${logFile} for additional details"

    # To log
    outputTS "The previous operation failed" "${logFile}"
    
    exit 1

}

# Print a warning message
function warn() {

    local yellowText=$'\e[1;33m'
    local normalText=$'\e[0m'
    local rightAlign="%-7s\n"

    # Remember that a warning was generated
    warnings="true"

    # To terminal
    outputFormatted "${yellowText}Warning${normalText}" "${rightAlign}" "${terminal}"

    # To log
    outputTS "The previous operation completed with warnings" "${logFile}"

}

# Print a success message
function pass() {

    local greenText=$'\e[1;32m'
    local normalText=$'\e[0m'
    local rightAlign="%-9s\n"

    # To terminal
    outputFormatted "${greenText}Completed${normalText}" "${rightAlign}" "${terminal}"

    # To log
    outputTS "The previous operation completed successfully" "${logFile}"

}

# Exit with error code and the supplied error message
function exitWithError() {

    local message="${1}"

    outputToTerminal "${message}"
    outputToTerminal "Review ${logFile} for additional details"
    outputToLog "${message}"

    exit 1

}

# Exit without error code and with the supplied message 
function exitWithoutError() {

    local message="${1}"

    outputToTerminal "${message}"
    outputToLog "${message}"

    exit 0

}

# Print a table of requirements if the user requested it via the --check option
function checkForRequirements() {

    local file="${1}"
    local distro="$(getDistro)"
    local canUseOverlay2="$(canUseOverlay2StorageDriver)"
    local canUseAufs="$(canUseAufsStorageDriver)"
    local canUseDMDirect="$(canUseDMDirectStorageDriver)"
    local format="%-20s\t%-20s\n"

    # Format values for nicer output
    if [[ "${canUseOverlay2}" == "true" ]]; then canUseOverlay2="Yes"; else canUseOverlay2="No"; fi
    if [[ "${canUseAufs}" == "true" ]]; then canUseAufs="Yes"; else canUseAufs="No"; fi
    if [[ "${canUseDMDirect}" == "true" ]]; then canUseDMDirect="Yes"; else canUseDMDirect="No"; fi

    outputCPRequirementsTable "${file}"

    output "" "${file}" 
    output2ColumnTableRow "Storage driver" "Available" "${format}" "${file}"
    output2ColumnTableRow "--------------" "---------" "${format}" "${file}"
    output2ColumnTableRow "overlay2" "${canUseOverlay2}" "${format}" "${file}"
    output2ColumnTableRow "aufs" "${canUseAufs}" "${format}" "${file}"
    output2ColumnTableRow "devicemapper-direct" "${canUseDMDirect}" "${format}" "${file}"
    output2ColumnTableRow "devicemapper-loop" "Yes" "${format}" "${file}"
    output "" "${file}"

    if [[ "${distro}" == "rhel" ]]; then
        output "*RHEL is not supported with docker-ce. You can install it anyway using the --force-rhel-install option." "${file}"
    fi

}

# Test prereqs for install. Any checks that do not pass exit immediately
function checkForPrereqs() {

    # Check the platform requirements
    outputOperation "Verifying platform meets requirements to install Component Pack..."
    if [[ "$(isCPSupportedPlatform)" == "true" ]]; then pass; else fail; fi
    
    # Verify docker-ce is not already installed
    outputOperation "Verifying Docker is not already installed..."
    if [[ "$(isDockerCEInstalled)" == "false" ]]; then pass; else fail; fi

    # Verify ${dockerDataDir} does not exist
    outputOperation "Verifying ${dockerDataDir} does not exist..."
    if [[ ! -d "${dockerDataDir}" ]]; then pass; else fail; fi

}

# See if any obsolete packages are installed. If any are found, exit with direction to run uninstallDocker.sh
function checkForObsoletePackages() {

    local distro="$(getDistro)"
    local foundObsoletePackage="false"
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

    outputOperation "Verifying no obsolete Docker packages are installed..."

    for obsoletePackage in "${obsoletePackages[@]}"; do
        outputToLog "Checking package ${obsoletePackage}..."
        # yum
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            if yum list installed "${obsoletePackage}"; then foundObsoletePackage="true"; fi
        # dnf
        elif [[ "${distro}" == "fedora" ]]; then
            if dnf list installed "${obsoletePackage}"; then foundObsoletePackage="true"; fi
        # apt
        elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
            if dpkg-query --list "${obsoletePackage}" | grep "^.i"; then foundObsoletePackage="true"; fi
        fi
    done

    if [[ "${foundObsoletePackage}" == "true" ]]; then fail; else pass; fi

}

# Determine if this system can use overlay2
function canUseOverlay2StorageDriver() {

    local canUseOverlay2="false"
    local distro="$(getDistro)"
    local osMajorVersion=$(getOSMajorVersion)
    local osMinorVersion=$(getOSMinorVersion)
    local fsType="$(getFSTypeForDirectory "${dockerDataDir}")"

    outputToLog "Checking to see if overlay2 storage driver can be used on this system..."

    # CentOS/RHEL
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if [[ "$(isKernelAtLeast "3.10.0-514")" == "true" ]]; then 
            if (( ${osMajorVersion} >= 7 && ${osMinorVersion} >= 2 )); then
                if [[ "${fsType}" == "xfs" ]]; then 
                    if [[ "$(isDTypeEnabledForDirectory "${dockerDataDir}")" == "true" ]]; then
                        canUseOverlay2="true"
                    fi
                fi
            elif (( ${osMajorVersion} == 7 && ${osMinorVersion} == 1 )); then
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
        outputToLog "System does not meet requirements to use overlay2 storage driver"
        output3ColumnTableRow "Requirement" "Found" "Requires" "%-20s\t%-20s\t%-20s\n" "${logFile}"
        output3ColumnTableRow "-----------" "-----" "--------" "%-20s\t%-20s\t%-20s\n" "${logFile}"
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            output3ColumnTableRow "Kernel:" "$(uname -r)" "3.10.0-514 or later" "%-20s\t%-20s\t%-20s\n" "${logFile}"
        else
            output3ColumnTableRow "Kernel:" "$(uname -r)" "4.0.0-000 or later" "%-20s\t%-20s\t%-20s\n" "${logFile}"
        fi
        if (( ${osMajorVersion} >= 7 && ${osMinorVersion} >= 2 )); then
            # Get D-Type now to use in table
            if [[ "${fsType}" == "xfs" ]]; then
                local dtypeEnabled="$(isDTypeEnabledForDirectory "${dockerDataDir}")"
            else
                local dtypeEnabled="N/A"
            fi
            output3ColumnTableRow "FS Type:" "${fsType}" "xfs" "%-20s\t%-20s\t%-20s\n" "${logFile}" 
            output3ColumnTableRow "D-Type enabled:" "${dtypeEnabled}" "true" "%-20s\t%-20s\t%-20s\n" "${logFile}" 
        elif (( ${osMajorVersion} == 7 && ${osMinorVersion} == 1 )); then
            output3ColumnTableRow "FS Type:" "${fsType}" "ext4" "%-20s\t%-20s\t%-20s\n" "${logFile}" 
        fi
    else
        outputToLog "System meets requirements to use overlay2 storage driver"
    fi

    echo "${canUseOverlay2}"

}

# Determine if this system can use devicemapper-direct
function canUseDMDirectStorageDriver() {

    local canUseDMDirect="false"

    outputToLog "Checking to see if devicemapper-direct storage driver can be used on this system..."

    # A --direct-lvm-device device must have been provided
    if [[ -n "${directLvmDevice}" ]]; then
        # If lsblk isn't available, we can't continue checking, so devicemapper-direct can't be used
        if [[ "$(commandExists "lsblk")" == "true" ]]; then
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
                if [[ "$(commandExists "pvdisplay")" == "true" && 
                      "$(commandExists "vgdisplay")" == "true" &&
                      "$(commandExists "lvdisplay")" == "true" ]]; then
                    outputToLog "Checking to see if there are any physical volumes named ${directLvmDevice}..."
                    if ! pvdisplay "${directLvmDevice}"; then
                        outputToLog "Checking to see if there are any volume groups named 'docker'..."
                        if ! vgdisplay "docker"; then
                            outputToLog "Checking to see if there are any logical volumes in the 'docker' volume group..."
                            if ! lvdisplay "docker" | grep "docker"; then
                                outputToLog "System meets requirements to use devicemapper-direct (Device: ${directLvmDevice})"
                                canUseDMDirect="true"
                            else
                                outputToLog "Unable to use devicemapper-direct due to logical volume conflict"
                            fi
                        else
                            outputToLog "Unable to use devicemapper-direct due to volume group conflict"
                        fi
                    else
                        outputToLog "Unable to use devicemapper-direct due to physical volume conflict"
                    fi
                else
                    # lvm commands don't exist, so there can't be any PV/VG/LV conflicts 
                    outputToLog "System meets requirements to use devicemapper-direct (Device: ${directLvmDevice})"
                    canUseDMDirect="true"
                fi
            else
                # Print a report if the device does not meet requirements for devicemapper-direct
                outputToLog "Device ${directLvmDevice} does not meet requirements to use devicemapper-direct storage driver"
                output3ColumnTableRow "Requirement" "Found" "Requires" "%-20s\t%-20s\t%-20s\n" "${logFile}"
                output3ColumnTableRow "-----------" "-----" "--------" "%-20s\t%-20s\t%-20s\n" "${logFile}"
                output3ColumnTableRow "Type:" "${deviceType}" "disk or part" "%-20s\t%-20s\t%-20s\n" "${logFile}"
                output3ColumnTableRow "FS Type:" "${deviceFSType}" "<null>" "%-20s\t%-20s\t%-20s\n" "${logFile}" 
                output3ColumnTableRow "Device count:" "${deviceCount}" "1" "%-20s\t%-20s\t%-20s\n" "${logFile}" 
            fi
        else
            outputToLog "Unable to determine if system can use devicemapper-direct storage driver because lslbk command is missing"
        fi
    else
        outputToLog "The --direct-lvm-device <block device> option was not provided, so devicemapper-direct cannot be used"
    fi

    echo "${canUseDMDirect}"

}

# Determine if this system can use aufs
function canUseAufsStorageDriver() {

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

    outputToLog "Checking to see if aufs storage driver can be used on this system..."

    # Only for Debian/Ubuntu
    if [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if [[ "${fsType}" == "xfs" || "${fsType}" == "ext4" ]]; then
            if grep aufs /proc/filesystems >/dev/null 2>&1; then
                outputToLog "System meets requirements to use aufs storage driver"
                canUseAufs="true"
            fi
        fi
    else
        # Print a report if the system does not meet requirements for aufs
        outputToLog "System does not meet requirements to use aufs storage driver"
        output3ColumnTableRow "Requirement" "Found" "Requires" "%-20s\t%-20s\t%-20s\n" "${logFile}"
        output3ColumnTableRow "-----------" "-----" "--------" "%-20s\t%-20s\t%-20s\n" "${logFile}"
        output3ColumnTableRow "Distro:" "${distro}" "debian or ubuntu" "%-20s\t%-20s\t%-20s\n" "${logFile}"
        output3ColumnTableRow "FS Type:" "${fsType}" "xfs or ext4" "%-20s\t%-20s\t%-20s\n" "${logFile}" 
        output3ColumnTableRow "Kernel aufs driver:" "${kernelDriver}" "true" "%-20s\t%-20s\t%-20s\n" "${logFile}" 
    fi

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

    outputToLog "Selected storage driver ${selectedStorageDriver}"

    # Handle user confirmation
    local answer=""

    # --force-devicemapper was specified but devicemapper-direct cannot be configured
    if [[ "${forceDMStorageDriver}" == "true" && "${canUseDMDirect}" == "false" ]]; then
        outputToTerminal ""
        outputToTerminal "WARNING! The --force-devicemapper option was provided, but devicemapper-direct cannot be configured."
        if [[ "${selectedStorageDriver}" == "devicemapper-loop" ]]; then
            outputToTerminal "Docker strongly discourages using devicemapper-loop for production workloads."
        fi
        outputToTerminal ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>>"${terminal}"
        outputToTerminal ""
        if [[ -z "${answer}" || "${answer}" != "yes" ]]; then
            exitWithoutError "Aborting docker-ce install"
        fi

    # --force-aufs was specified but is not supported
    elif [[ "${forceAufsStorageDriver}" == "true" && "${canUseAufs}" == "false" ]]; then
        outputToTerminal ""
        outputToTerminal "WARNING! The --force-aufs option was provided, but aufs is not supported on this system."
        outputToTerminal ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>>"${terminal}"
        outputToTerminal ""
        if [[ -z "${answer}" || "${answer}" != "yes" ]]; then
            exitWithoutError "Aborting docker-ce install"
        fi

    # --direct-lvm-device was specified, it can be configured, but overlay2 or aufs were selected
    elif [[ -n "${directLvmDevice}" && "${canUseDMDirect}" == "true" && 
              ("${selectedStorageDriver}" == "overlay2" || "${selectedStorageDriver}" == "aufs")  ]]; then
        outputToTerminal ""
        outputToTerminal "WARNING! The ${selectedStorageDriver} driver has been selected because it is recommended by Docker."
        outputToTerminal "However, this system can also be configured with devicemapper-direct. To force the"
        outputToTerminal "use of devicemapper-direct, add the --force-devicemapper option."
        outputToTerminal ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>>"${terminal}"
        outputToTerminal ""
        if [[ -z "${answer}" || "${answer}" != "yes" ]]; then
            exitWithoutError "Aborting docker-ce install"
        fi

    # --direct-lvm-device was specified, it cannot be configured, and overlay2 or aufs were selected
    elif [[ -n "${directLvmDevice}" && "${canUseDMDirect}" == "false" &&
              ("${selectedStorageDriver}" == "overlay2" || "${selectedStorageDriver}" == "aufs") ]]; then
        outputToTerminal ""
        outputToTerminal "WARNING! This system cannot be configured with devicemapper-direct. The ${selectedStorageDriver}"
        outputToTerminal "has been selected instead." 
        outputToTerminal ""
        read -p "To continue installation with ${selectedStorageDriver}, type 'yes' and press Enter: " answer 2>>"${terminal}"
        outputToTerminal ""
        if [[ -z "${answer}" || "${answer}" != "yes" ]]; then
            exitWithoutError "Aborting docker-ce install"
        fi

    # --direct-lvm-device was specified, it can be configured, and devicemapper-direct was selected
    elif [[ -n "${directLvmDevice}" && "${canUseDMDirect}" == "true" && "${selectedStorageDriver}" == "devicemapper-direct" ]]; then
        outputToTerminal ""
        outputToTerminal "WARNING! The devicemapper-direct driver has been selected."
        outputToTerminal "All existing data on ${directLvmDevice} will be destroyed!"
        outputToTerminal ""
        read -p "To continue installation with devicemapper-direct, type 'yes' and press Enter: " answer 2>>"${terminal}"
        outputToTerminal ""
        if [[ -z "${answer}" || "${answer}" != "yes" ]]; then
            exitWithoutError "Aborting docker-ce install"
        fi

    # --direct-lvm-device was specified, it cannot be configured, and devicemapper-loop was selected
    elif [[ -n "${directLvmDevice}" && "${canUseDMDirect}" == "false" && "${selectedStorageDriver}" == "devicemapper-loop" ]]; then
        outputToTerminal ""
        outputToTerminal "WARNING! The devicemapper-loop driver has been selected because this system"
        outputToTerminal "cannot be configured with devicemapper-direct. Docker strongly discourages"
        outputToTerminal "using devicemapper-loop for production workloads."
        outputToTerminal ""
        read -p "To continue installation with devicemapper-loop, type 'yes' and press Enter: " answer 2>>"${terminal}"
        outputToTerminal ""
        if [[ -z "${answer}" || "${answer}" != "yes" ]]; then
            exitWithoutError "Aborting docker-ce install"
        fi

    # Do a final confirmation if we get this far and devicemapper-loop is the selected driver
    elif [[ "${selectedStorageDriver}" == "devicemapper-loop" ]]; then
        outputToTerminal ""
        outputToTerminal "WARNING! The devicemapper-loop driver has been selected. Docker strongly discourages"
        outputToTerminal "using devicemapper-loop for production workloads."
        outputToTerminal ""
        read -p "To continue installation with devicemapper-loop, type 'yes' and press Enter: " answer 2>>"${terminal}"
        outputToTerminal ""
        if [[ -z "${answer}" || "${answer}" != "yes" ]]; then
            exitWithoutError "Aborting docker-ce install"
        fi
    fi

}

# Do the install
function install() {

    local distro="$(getDistro)"
    local version=""

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
        outputOperation "Installing prerequisite packages..."
        yum -y --enablerepo "${baseRepo}" install \
            "device-mapper-persistent-data" \
            "lvm2" \
            "yum-plugin-versionlock" \
            "yum-utils" \
            && pass || fail

        # Add docker-ce repo
        outputOperation "Adding docker-ce repo..."
        yum-config-manager --add-repo "https://download.docker.com/linux/centos/docker-ce.repo" && pass || fail

        # Update the package index
        outputOperation "Updating package index..."
        yum -y makecache fast && pass || fail

        # Get the latest version of docker target
        outputToLog "Getting the latest version of docker-ce target installation version ${CP_DOCKER_SUPPORTED_RELEASE}..."
        version="$(yum -y list "docker-ce.x86_64" --showduplicates | \
            grep "${CP_DOCKER_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 
        outputToLog "Latest version available: ${version}"

        # Install docker-ce 
        outputOperation "Performing docker-ce install..."
        yum -y --enablerepo "${extrasRepo}" --setopt=obsoletes=0 install "docker-ce-${version}" && pass || fail

        # Lock the docker-ce package
        outputOperation "Locking the docker-ce package to prevent auto-update..."
        yum versionlock add "docker-ce" && pass || fail

    # Fedora
    elif [[ "${distro}" == "fedora" ]]; then

        # Install prereqs
        outputOperation "Installing prerequisite packages..."
        dnf -y --enablerepo "fedora" install \
            "device-mapper-persistent-data" \
            "dnf-plugins-core" \
            "lvm2" \
            "dnf-plugins-extras-versionlock" \
            && pass || fail

        # Add docker-ce repo
        outputOperation "Adding docker-ce repo..."
        dnf -y config-manager --add-repo "https://download.docker.com/linux/fedora/docker-ce.repo" && pass || fail

        # Update the yum package index
        outputOperation "Updating package index..."
        dnf -y makecache fast && pass || fail

        # Get the latest version of docker target
        outputToLog "Getting the latest version of docker-ce target installation version ${CP_DOCKER_SUPPORTED_RELEASE}..."
        version="$(dnf -y list "docker-ce" --showduplicates | \
            grep "${CP_DOCKER_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}' | \
            awk -F "-" '{print $1}')" 
        outputToLog "Latest version available: ${version}"

        # Install docker-ce
        outputOperation "Performing docker-ce install..."
        dnf -y install "docker-ce-${version}" && pass || fail

        # Lock the docker-ce package
        outputOperation "Locking the docker-ce package to prevent auto-update..."
        dnf versionlock add "docker-ce" && pass || fail

    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then

        # Install prereqs
        outputOperation "Installing prerequisite packages..."
        apt-get -y install \
            "apt-transport-https" \
            "ca-certificates" \
            "curl" \
            "gnupg2" \
            "lvm2" \
            "software-properties-common" \
            "thin-provisioning-tools" \
            && pass || fail

        # Add Docker GPG key
        outputOperation "Adding Docker GPG key to apt..."
        curl -fsSL "https://download.docker.com/linux/${distro}/gpg" | apt-key add - && pass || fail

        # Add docker-ce repo
        outputOperation "Adding docker-ce repo..."
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${distro} $(lsb_release -cs) stable" && pass || fail

        # Update the apt package index
        outputOperation "Updating package index..."
        apt-get -y update && pass || fail

        # Get the latest version of docker target
        outputToLog "Getting the latest version of docker-ce target installation version ${CP_DOCKER_SUPPORTED_RELEASE}..."
        version="$(apt-cache madison "docker-ce" | \
            grep "${CP_DOCKER_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk -F '\\| ' '{print $2}' | \
            tr -d ' ')" 
        outputToLog "Latest version available: ${version}"

        # Install docker-ce
        outputOperation "Performing docker-ce install..."
        apt-get install -y "docker-ce=${version}" && pass || fail

        # Lock the docker-ce package
        outputOperation "Locking the docker-ce package to prevent auto-update..."
        apt-mark hold "docker-ce" && pass || fail

    fi

    # Stop Docker if it was started automatically following installed (happens on Debian, for example). Needs to be stopped to config storage driver
    outputOperation "Stopping Docker to configure storage driver..."
    systemctl stop "docker" && pass || fail

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

    outputToLog "Configuring overlay2 storage driver..."

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
        outputToLog "WARNING: An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..."
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure aufs
function configAufs() {

    local configFile="${dockerConfigDir}/daemon.json"
    local configFileConfig=""

    configFileConfig+="{\n"
    configFileConfig+="\t\"storage-driver\": \"aufs\"\n"
    configFileConfig+="}\n"

    outputToLog "Configuring aufs storage driver..."

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
        outputToLog "WARNING: An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..."
        mv "${configFile}" "${tmpConfigFile}"
        printf "${configFileConfig}" >"${configFile}"
    fi

}

# Configure devicemapper-direct
function configDirectLvm() {

    outputToLog "Configuring devicemapper-direct storage driver..."

    # Create the Physical Volume
    outputOperation "Creating Physical Volume ${directLvmDevice}..."
    pvcreate -y "${directLvmDevice}" && pass || fail

    # Create the Volume Group
    outputOperation "Creating Volume Group docker..."
    vgcreate -y "docker" "${directLvmDevice}" && pass || fail

    # Create the Logical Volumes
    outputOperation "Creating Logical Volume thinpool..."
    lvcreate -y --wipesignatures "y" --name "thinpool" --extents "95%VG" "docker" && pass || fail
    outputOperation "Creating Logical Volume thinpoolmeta..."
    lvcreate -y --wipesignatures "y" --name "thinpoolmeta" --extents "1%VG" "docker" && pass || fail

    # Convert the Logical Volumes to thin pools
    outputOperation "Converting Logical Volumes to thin pools..."
    lvconvert -y --zero "n" --chunksize "512K" --thinpool "docker/thinpool" --poolmetadata "docker/thinpoolmeta" && pass || fail

    # Create the LVM profile
    outputToLog "Creating LVM profile..."
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
        outputToLog "WARNING: An existing ${lvmProfile} was found. Backing it up as ${tmpLvmProfile} and creating a new one..."
        mv "${lvmProfile}" "${tmpLvmProfile}"
        printf "${lvmProfileConfig}" >"${lvmProfile}" 
    fi

    # Apply the LVM profile
    outputOperation "Applying LVM profile..."
    lvchange -y --metadataprofile "docker-thinpool" "docker/thinpool" && pass || fail

    # Enable monitoring for Logical Volumes
    outputOperation "Enabling monitoring for Logical Volumes..."
    lvs -y --options "+seg_monitor" && pass || fail

    # Configure Docker to use devicemapper-direct
    outputToLog "Configuring devicemapper-direct storage driver..."
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
        outputToLog "WARNING: An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..."
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

    outputToLog "Configuring devicemapper-loop storage driver..."

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
        outputToLog "WARNING: An existing ${configFile} was found. Backing it up as ${tmpConfigFile} and creating a new one..."
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

    outputOperation "Enabling auto-start for Docker..."
    systemctl enable "docker" && pass || fail
    outputOperation "Starting Docker..."
    systemctl start "docker" && pass || fail

}

# Deploy a Docker registry on this node
function configRegistry() {

    local distro="$(getDistro)"
    local registryPort="5000"

    # Configure the firewall
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        outputOperation "Opening port ${registryPort}..."
        firewall-cmd "--add-port=${registryPort}/tcp" --permanent && pass || warn
        outputOperation "Reloading firewall rules..."
        firewall-cmd --reload && pass || warn
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        outputOperation "Opening port ${registryPort}..."
        ufw allow "${registryPort}/tcp" && pass || warn
        outputOperation "Reloading firewall rules..."
        ufw reload && pass || warn
    fi

    # Run the registry image
    outputOperation "Creating local image registry..."
    docker run --detach --publish "5000:5000" --restart=always --name "registry" "registry:2" && pass || fail

}

# Report status
function term() {

    outputToLog "Printing Docker configuration..."
    docker info

    outputToTerminal ""
    if [[ "${warnings}" == "false" ]]; then
        outputToTerminal "Docker has been installed successfully! Run 'sudo docker run hello-world' to confirm normal operation."
    else
        outputToTerminal "Docker has been installed with warnings. Review ${logFile} for additional details."
    fi

}

init "${@}"

if [[ "${checkRequirements}" == "true" ]]; then
    # Just check requirements
    checkForRequirements "${terminal}"
else
    # Do the install
    # If RHEL, --force-rhel-install must be provided to install
    if [[ "$(getDistro)" == "rhel" ]]; then
        if [[ "${forceRHELInstall}" != "true" ]]; then
            exitWithoutError "The docker-ce package is not officially supported on RHEL. Use the --force-rhel-install option to install anyway."
        fi
    fi
    checkForRequirements "${logFile}"
    checkForPrereqs
    checkForObsoletePackages
    determineStorageDriver
    install
    configStorageDriver
    configAutoStart
    if [[ "${isRegistryNode}" == "true" ]]; then
        configRegistry
    fi
    term
fi 
