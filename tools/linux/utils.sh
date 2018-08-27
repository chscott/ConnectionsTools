#!/bin/bash

# Source prereqs
. "/etc/ictools.conf"

# Section: Operating System ================================================================================================================

# Returns ID value from /etc/os-release or "unknown" if not found 
function getDistro() {

    local distro="unknown"

    if [[ -f "/etc/os-release" ]]; then
        distro="$(grep "^ID=" "/etc/os-release" | awk -F "=" '{print $2}' | tr -d '"')"
    fi

    echo "${distro}"

}

# Determines if the kernel on this system is at the provided level or later
# $1: Release string to check (in format w.x.y-z)
function isKernelAtLeast() {

    local releaseToCheck="${1}"
    local kernelAtLeastAsRecent="false"

    let releaseToCheckW=10#$(echo "${releaseToCheck}" | awk -F "." '{print $1}')
    let releaseToCheckX=10#$(echo "${releaseToCheck}" | awk -F "." '{print $2}')
    let releaseToCheckY=10#$(echo "${releaseToCheck}" | awk -F "." '{print $3}' | awk -F "-" '{print $1}')
    let releaseToCheckZ=10#$(echo "${releaseToCheck}" | awk -F "." '{print $3}' | awk -F "-" '{print $2}')
    let kernelW=10#$(uname -r | awk -F "." '{print $1}')
    let kernelX=10#$(uname -r | awk -F "." '{print $2}')
    let kernelY=10#$(uname -r | awk -F "." '{print $3}' | awk -F "-" '{print $1}')
    let kernelZ=10#$(uname -r | awk -F "." '{print $3}' | awk -F "-" '{print $2}')

    if (( kernelW > releaseToCheckW )); then
        # Kernel W is greater than Release W, so the kernel must be at least as recent
        kernelAtLeastAsRecent="true"
    elif (( kernelW < releaseToCheckW )); then
        # Kernel W is less than Release W, so the kernel cannot be at least as recent
        kernelAtLeastAsRecent="false"
    else
        # Kernel W is the same as Release W, so we need to check X
        if (( kernelX > releaseToCheckX )); then
            # Kernel X is greater than Release X, so the kernel must be at least as recent
            kernelAtLeastAsRecent="true"
        elif (( kernelX < releaseToCheckX )); then
            # Kernel X is less than Release X, so the kernel cannot be at least as recent
            kernelAtLeastAsRecent="false"
        else
            # Kernel X is the same as Release X, so we need to check Y 
            if (( kernelY > releaseToCheckY )); then
                # Kernel Y is greater than Release Y, so the kernel must be at least as recent
                kernelAtLeastAsRecent="true"
            elif (( kernelY < releaseToCheckY )); then
                # Kernel Y is less than Release Y, so the kernel cannot be at least as recent
                kernelAtLeastAsRecent="false"
            else
                # Kernel Y is the same as Release Y, so we need to check Z 
                if (( kernelZ > releaseToCheckZ )); then
                    # Kernel Z is greater than Release Z, so the kernel must be at least as recent
                    kernelAtLeastAsRecent="true"
                elif (( kernelZ < releaseToCheckZ )); then
                    # Kernel Z is less than Release Z, so the kernel cannot be at least as recent
                    kernelAtLeastAsRecent="false"
                else
                    # Kernel Z is the same as Release Z, so this kernel is the same release as the one being tested
                    kernelAtLeastAsRecent="true"
                fi
            fi
        fi
    fi

    echo "${kernelAtLeastAsRecent}"

}

# Returns VERSION_ID major number from /etc/os-release or -1 if not found
function getOSMajorVersion() {

    local majorVersion=-1

    if [[ -f "/etc/os-release" ]]; then
        let majorVersion=$(grep "^VERSION_ID=" "/etc/os-release" | awk -F "=" '{print $2}' | tr -d '"' | awk -F "." '{print $1}')
    fi

    echo ${majorVersion}

}

# Returns VERSION_ID minor number from /etc/os-release or -1 if not found
# This function is used for numeric comparison and must regard 16.04 as minor version 4 and not "04"
function getOSMinorVersion() {

    local minorVersion=-1

    if [[ "$(getDistro)" == "centos" ]]; then
        # CentOS uses /etc/system-release to store the RHEL equivalent version, including minor version. This is handy for equivalence operations.
        if [[ -f "/etc/system-release" ]]; then
            # Coerce to decimal
            let minorVersion=10#$(awk -F "." '{print $2}' "/etc/system-release")
        fi 
    else
        if [[ -f "/etc/os-release" ]]; then
            # Coerce to decimal
            let minorVersion=10#$(grep "^VERSION_ID=" "/etc/os-release" | awk -F "=" '{print $2}' | tr -d '"' | awk -F "." '{print $2}')
        fi
    fi

    echo ${minorVersion}

}

# Returns VERSION_ID minor number from /etc/os-release or -1 if not found
# This function is used for display and must regard 16.04 as minor version "04" and not 4
function getOSMinorVersionDisplay() {

    local minorVersion="-1"

    if [[ "$(getDistro)" == "centos" ]]; then
        # CentOS uses /etc/system-release to store the RHEL equivalent version, including minor version. This is handy for equivalence operations.
        if [[ -f "/etc/system-release" ]]; then
            minorVersion=$(awk -F "." '{print $2}' "/etc/system-release")
        fi 
    else
        if [[ -f "/etc/os-release" ]]; then
            minorVersion=$(grep "^VERSION_ID=" "/etc/os-release" | awk -F "=" '{print $2}' | tr -d '"' | awk -F "." '{print $2}')
        fi
    fi

    echo ${minorVersion}

}

# Returns the machine architecture
function getMachineArchitecture() {

    local machineArchitecture="$(uname -m)"

    echo "${machineArchitecture}"

}

# Returns the number of logical cores
function getLogicalCores() {

    local logicalCores=$(grep -c "^processor" "/proc/cpuinfo")

    echo ${logicalCores}

}

# Returns the amount of available memory
function getAvailableMemory() {

    local availableMemory=$(grep "MemAvailable:" "/proc/meminfo" | awk '{print $2}')
    
    echo ${availableMemory} 

}

# Returns the amount of total swap memory
function getSwapMemory() {

    local swapMemory=$(grep "SwapTotal:" "/proc/meminfo" | awk '{print $2}')
    
    echo ${swapMemory} 

}

# Returns the file system type for the given directory. If directory doesn't exist, returns the file system type for closest parent
function getFSTypeForDirectory() {

    local directory="${1}"
    local fsType="unknown"

    # Try running df on all directories in path, starting at the leaf and working backward. Use the first directory with FS info
    until df "${directory}" >/dev/null 2>&1; do
        directory="$(dirname "${directory}")"
    done
    # Get the FS type of the directory
    fsType=$(df --output=fstype "${directory}" | grep -v "^Type")

    echo "${fsType}"

}

# Returns whether or not d-type is enabled for xfs directory. If directory doesn't exist, returns the file system type for closest parent
function isDTypeEnabledForDirectory() {

    local directory="${1}"
    local dType="false"
    
    # Return false if xfs_info isn't available
    if [[ "$(commandExists "xfs_info")" == "true" ]]; then
        # Try running xfs_info on all directories in path, starting at the leaf and working backward. Use the first directory with XFS info
        until xfs_info "${directory}" >/dev/null 2>&1; do
            directory="$(dirname "${directory}")"
        done
        # Get the d-type of the directory
        dType=$(xfs_info "${directory}" | grep "ftype" | awk -F "ftype=" '{print $2}')
        if (( ${dType} == 1 )); then
            dType="true"
        else
            dType="false"
        fi
    fi

    echo "${dType}"

}

# Verify that a given directory exists
function directoryExists() {

    local directory="${1}"

    if [[ -d "${directory}" ]]; then
        echo "true"
    else
        echo "false"
    fi

}

# Verify that a given directory has subdirectories
function directoryHasSubDirs() {

    local directory="${1}"
    local status="false"

    cd "${directory}" 2>&1

    # No error, so directory exists
    if [[ ${?} == 0 ]]; then
        ls -d * >/dev/null 2>&1 
        # No error, so at least one subdir was found
        if [[ ${?} == 0 ]]; then
            status="true"
        fi
    fi           

    echo "${status}"

}

# Tests to make sure the effective user ID is root
function checkForRoot() {

    local script="$(basename "${0}")"

	if [[ ${EUID} != 0 ]]; then
		log "${script} needs to run as root. Exiting."
		exit 1
	fi

}

# Determine if a command exists on path or as a built-in
function commandExists() {

    local commandToTest="${1}"
    
    if command -v "${commandToTest}" >/dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi

}

# End of Operating System section ==========================================================================================================

# Section: DB2 ===========================================================================================================================+=

# Prints the status of the DB2 server
# $1: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getDB2ServerStatus() {

    local noDisplay="${1}"

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${db2InstallDir}" || ! -d "${db2InstallDir}" ]]; then
        return
    fi

    # Only print info if noDisplay is not true
    if [[ "${noDisplay}" != "true" ]]; then
        printf "${left2Column}" "Server: DB2"
    fi

    # See if the server is running
    if [[ $(ps -ef | grep -v "grep" | grep -c "db2sysc") > 0 ]]; then
        # If we found a match, the server is started
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STARTED"
        else
            printf "${right2Column}" "${greenText}STARTED${normalText}"
        fi
    else 
        # If we did not find a match, the server is stopped
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STOPPED"
        else
            printf "${right2Column}" "${redText}STOPPED${normalText}"
        fi
    fi

}

# Start DB2 
function startDB2Server() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${db2InstallDir}" || ! -d "${db2InstallDir}" ]]; then
        log "DB2 does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Starting DB2..."

    if [[ "$(getDB2ServerStatus "true")" == "STOPPED" ]]; then
        # If the server is stopped, start it 
        status=$(sudo -i -u "${db2InstanceUser}" "db2start")
        # Check to see if the server is started
        if [[ "$(getDB2ServerStatus "true")" == "STARTED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already started, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# Stop DB2
function stopDB2Server() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${db2InstallDir}" || ! -d "${db2InstallDir}" ]]; then
        log "DB2 does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Stopping DB2..."

    if [[ "$(getDB2ServerStatus "true")" == "STARTED" ]]; then
        # If the server is started, stop it 
        status=$(sudo -i -u "${db2InstanceUser}" "db2stop")
        if [[ "${status}" =~ "SQL1064N" || "${status}" =~ "SQL1032N" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}" 
        elif [[ "${status}" =~ "SQL1025N" ]]; then
            printf "${right2Column}" "${redText}FAILURE${normalText} (active connections)"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}" 
        fi
    else
        # The server is already stopped, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# End of DB2 section =======================================================================================================================

# Section: TDI =============================================================================================================================

# Tests to make sure TDI is installed on this system
function checkForTDI() {

    local script="$(basename "${0}")"

    if [[ ! -d "${tdiSolutionDir}" ]]; then
        log "${script} can only run on TDI nodes. Exiting."
        exit 1
    fi

}

# End of TDI section =======================================================================================================================

# Section: Component Pack ==================================================================================================================

CP_SUPPORTED_RELEASE="6.0.0.6"
CP_DOCKER_SUPPORTED_RELEASE="17.03"
CP_K8S_SUPPORTED_RELEASE="1.11"
CP_HELM_SUPPORTED_RELEASE="2.9.1"
CP_CENTOS_SUPPORTED_RELEASE="7.x"
CP_RHEL_SUPPORTED_RELEASE="7.x"
CP_FEDORA_SUPPORTED_RELEASE="25"
CP_DEBIAN_SUPPORTED_RELEASE="9"
CP_UBUNTU_SUPPORTED_RELEASE="16.04"

# Output a table of requirements for installing Component Pack
function outputCPRequirementsTable() {

    local file="${1}"
    local distro="$(getDistro)"
    local format="%-20s\t%-20s\t%-20s\n"

    output "Component Pack ${CP_SUPPORTED_RELEASE} requirements:" "${file}"
    output "" "${file}"
    output3ColumnTableRow "Requirement" "Found" "Requires" "${format}" "${file}"
    output3ColumnTableRow "-----------" "-----" "--------" "${format}" "${file}"
    output3ColumnTableRow "Distro:" "${distro}" "centos, rhel*, fedora, debian or ubuntu" "${format}" "${file}"
    if [[ "${distro}" == "centos" ]]; then
        output3ColumnTableRow "Version:" "$(getOSMajorVersion).$(getOSMinorVersionDisplay)" "${CP_CENTOS_SUPPORTED_RELEASE}" "${format}" "${file}"
    elif [[ "${distro}" == "rhel" ]]; then
        output3ColumnTableRow "Version:" "$(getOSMajorVersion).$(getOSMinorVersionDisplay)" "${CP_RHEL_SUPPORTED_RELEASE}" "${format}" "${file}"
    elif [[ "${distro}" == "fedora" ]]; then
        output3ColumnTableRow "Version:" "$(getOSMajorVersion)" "${CP_FEDORA_SUPPORTED_RELEASE}" "${format}" "${file}"
    elif [[ "${distro}" == "debian" ]]; then
        output3ColumnTableRow "Version:" "$(getOSMajorVersion)" "${CP_DEBIAN_SUPPORTED_RELEASE}" "${format}" "${file}"
    elif [[ "${distro}" == "ubuntu" ]]; then
        output3ColumnTableRow "Version:" "$(getOSMajorVersion).$(getOSMinorVersionDisplay)" "${CP_UBUNTU_SUPPORTED_RELEASE}" "${format}" "${file}"
    fi
    output3ColumnTableRow "Machine architecture:" "$(getMachineArchitecture)" "x86_64" "${format}" "${file}"
    output3ColumnTableRow "Logical cores:" "$(getLogicalCores)" "At least 2" "${format}" "${file}"
    output3ColumnTableRow "Available memory:" "$(getAvailableMemory)" "At least 2097152" "${format}" "${file}"
    output3ColumnTableRow "Total swap:" "$(getSwapMemory)" "Must be 0" "${format}" "${file}"
    output "" "${file}"
    if [[ "$(isCPSupportedPlatform)" == "true" ]]; then
        local isSupported="Yes"
    else
        local isSupported="No"
    fi
    output "Supported for Component Pack: ${isSupported}" "${file}"

}

# Determines if this system is supported for Component Pack. Support is the intersection of support for Docker, K8s and Helm.
function isCPSupportedPlatform() {

    # Support is explicit
    local isSupported="false"
    local distro="$(getDistro)"
    local majorVersion=$(getOSMajorVersion)
    local minorVersion=$(getOSMinorVersion)

    # Centos (7)
    if [[ "${distro}" == "centos" ]]; then
        if (( ${majorVersion} == 7 )); then 
            isSupported="true"
        fi
    # RHEL (7)
    elif [[ "${distro}" == "rhel" ]]; then
        if (( ${majorVersion} == 7 )); then 
            isSupported="true"
        fi
    # Fedora (25)
    elif [[ "${distro}" == "fedora" ]]; then
        if (( ${majorVersion} == 25 )); then 
            isSupported="true"
        fi
    # Debian (9)
    elif [[ "${distro}" == "debian" ]]; then
        if (( ${majorVersion} == 9 )); then 
            isSupported="true"
        fi
    # Ubuntu (16.04)
    elif [[ "${distro}" == "ubuntu" ]]; then
        if (( ${majorVersion} == 16 && ${minorVersion} == 4 )); then
            isSupported="true"
        fi
    fi 

    # Machine architecture must be x86_64
    if [[ "$(getMachineArchitecture)" != "x86_64" ]]; then
        isSupported="false"
    fi

    # Must have at least 2 CPUs (kubeadm requirement...treating this as logical cores)
    if (( $(getLogicalCores) < 2 )); then
        isSupported="false"
    fi

    # Must have at least 2 GB available memory (kubeadm requirement)
    if (( $(getAvailableMemory) < (2 * 1024 * 1024) )); then
        isSupported="false"
    fi

    # Swap must be disabled (kubeadm requirement)
    if (( $(getSwapMemory) > 0 )); then
        isSupported="false"
    fi

    echo "${isSupported}"

}

# End of Component Pack section ============================================================================================================

# Section: Docker ========================================================================================================================+=

# Checks to see if Docker CE is installed
function isDockerCEInstalled() {

    local distro="$(getDistro)"
    local isInstalled="false"

    # CentOS/RHEL
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if (( $(yum list installed "docker-ce" | grep -c "docker-ce") > 0 )) ; then isInstalled="true"; fi 
    # Fedora
    elif [[ "${distro}" == "fedora" ]]; then
        if (( $(dnf list installed "docker-ce" | grep -c "docker-ce") > 0 )) ; then isInstalled="true"; fi 
    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if (( $(dpkg-query --list | grep -c "docker-ce") > 0 )); then isInstalled="true"; fi 
    fi

    echo "${isInstalled}"

}

# Returns the version of Docker CE installed
function getDockerCEVersion() {

    local distro="$(getDistro)"
    local installedVersion=""

    if [[ "$(isDockerCEInstalled)" == "true" ]]; then
        # CentOS/RHEL
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            installedVersion="$(yum -q list installed "docker-ce" | grep "docker-ce" | awk '{print $2}' | awk -F '.' '{print $1"."$2}')"
        # Fedora
        elif [[ "${distro}" == "fedora" ]]; then
            installedVersion="$(dnf -q list installed "docker-ce" | grep "docker-ce" | awk '{print $2}' | awk -F '.' '{print $1"."$2}')"
        # Debian/Ubuntu
        elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
            installedVersion="$(dpkg-query --list | grep "docker-ce" | awk '{print $3}' | awk -F '.' '{print $1"."$2}')"
        fi
    else
        installedVersion="not installed"
    fi

    echo "${installedVersion}"

}

# End of Docker section ====================================================================================================================

# Section: Kubernetes ======================================================================================================================

# This is will be set any time utils.sh is sourced, allowing use of Kubernetes commands without needing to jump through hoops
export KUBECONFIG="/etc/kubernetes/admin.conf"

# Checks to see if specified Kubernetes component is installed
# $1: component (kubeadm, kubectl, kubelet)
function isK8sComponentInstalled() {

    local component="${1}"
    local distro="$(getDistro)"
    local isInstalled="false"

    if [[ -n "${component}" ]]; then
        # CentOS/RHEL
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            if (( $(yum list installed "${component}" | grep -c "${component}") > 0 )) ; then isInstalled="true"; fi 
        # Fedora
        elif [[ "${distro}" == "fedora" ]]; then
            if (( $(dnf list installed "${component}" | grep -c "${component}") > 0 )) ; then isInstalled="true"; fi 
        # Debian/Ubuntu
        elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
            if (( $(dpkg-query --list | grep -c "${component}") > 0 )); then isInstalled="true"; fi 
        fi
    fi

    echo "${isInstalled}"

}

# Returns the version of the specified Kubernetes component
# $1: component (kubeadm, kubectl, kubelet)
function getK8sComponentVersion() {

    local component="${1}"
    local distro="$(getDistro)"
    local installedVersion=""

    if [[ -n "${component}" ]]; then
        if [[ "$(isK8sComponentInstalled "${component}")" == "true" ]]; then
            # CentOS/RHEL
            if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
                installedVersion="$(yum -q list installed "${component}" | grep "${component}" | awk '{print $2}' | awk -F '.' '{print $1"."$2}')"
            # Fedora
            elif [[ "${distro}" == "fedora" ]]; then
                installedVersion="$(dnf -q list installed "${component}" | grep "${component}" | awk '{print $2}' | awk -F '.' '{print $1"."$2}')"
            # Debian/Ubuntu
            elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
                installedVersion="$(dpkg-query --list | grep "${component}" | awk '{print $3}' | awk -F '.' '{print $1"."$2}')"
            fi
        else
            installedVersion="not installed"
        fi
    fi

    echo "${installedVersion}"

}

# Tests to make sure Kubernetes is available on this system (obsoleted by isK8sComponentInstalled)
function checkForK8s() {

    local script="$(basename "${0}")"

    if [[ ! -x "${kubectl}" ]]; then
        log "${script} can only run on Component Pack nodes. Exiting."
        exit 1
    fi

}
# Return number of K8s master node ports in use (6443, 2379, 2380, 10250-10252, 10255)
function checkForK8sMasterNodePortsInUse() {

    local activePorts=$(
        netstat --tcp --listen --numeric | \
        awk '{print $4}' | \
        awk -F ':' '{print $NF}' | \
        grep -c -E "^6443$|^2379$|^2380$|^1025[0-2]$|^10255$" \
    )

    echo ${activePorts}

}

# Return number of K8s worker node ports in use (10250, 10255, 30000-32767)
function checkForK8sWorkerNodePortsInUse() {

    local activePorts=$(
        netstat --tcp --listen --numeric | \
        awk '{print $4}' | \
        awk -F ':' '{print $NF}' | \
        grep -c -E "^10250$|^10255$|3[0-2][0-7[0-6][0-7]" \
    )

    echo ${activePorts}

}

# Return whether or not a given node in the Kubernetes cluster
function isNodeInK8sCluster() {

    local nodeName="${1}"
    local isInCluster="false"

    if [[ -n "${nodeName}" && ("$(commandExists kubectl)" == "true") ]]; then
        if (( $(kubectl get nodes | grep -c "${nodeName}") > 0 )); then
            isInCluster="true" 
        fi
    fi

    echo "${isInCluster}"

}

# Return the node type
function getK8sNodeType() {

    local nodeName="${1}"
    local nodeType="N/A" 
    
    if [[ "$(commandExists "kubectl")" == "true" ]]; then
        nodeType="$(kubectl get nodes | grep "${nodeName}" | awk '{print $3}')"
    fi

    echo "${nodeType}"

}

# Returns the count of non-master nodes
function getK8sNonMasterNodeCount() {

    local nonMasterNodeCount="-1"

    if [[ "$(commandExists "kubectl")" == "true" ]]; then
        nonMasterNodeCount="$(kubectl get nodes --no-headers | grep -v -c "master")"
    fi

    echo "${nonMasterNodeCount}"

}

# End of Kubernetes section ================================================================================================================

# Section: WAS =============================================================================================================================

# Tests to make sure the WAS Deployment Manager is available on this system
function checkForDmgr() {

    local script="$(basename "${0}")"

    if [[ ! -d "${wasDmgrProfile}" ]]; then
        log "${script} can only run on the Deployment Manager node. Exiting."
        exit 1
    fi

}

# Check to see if Deployment Manager is available
function isDmgrAvailable() {

    local status="$(nmap "${wasDmgrHost}" -p ${wasDmgrSoapPort})"

    if [[ "${status}" =~ "open" ]]; then
        echo 0
    else
        echo 1
    fi

}

# Given a profileKey.metadata file, return the profile type
function getWASProfileType() {

    local profileKeyFile="${1}"
    local profileType=""

    profileType="$(grep "com.ibm.ws.profile.type" "${profileKeyFile}" | awk -F "=" '{print $2}')"
    
    if [[ ${?} == 0 ]]; then
        echo "${profileType}"
    else
        echo "INVALID"
    fi

}

# Determine if a given profile is of type DEPLOYMENT_MANAGER
function isWASDmgrProfile() {

    local profile="${1}"

    # Determine the profile type
    local profileKey="${wasProfileRoot}/${profile}/properties/profileKey.metadata"
    if [[ -f "${profileKey}" ]]; then
        profileType=$(getWASProfileType "${profileKey}")
    fi

    if [[ "${profileType}" == "DEPLOYMENT_MANAGER" ]]; then
        echo "true"
    else
        echo "false"
    fi

}

# Determine if a given profile is of type BASE
function isWASBaseProfile() {

    local profile="${1}"

    # Determine the profile type
    local profileKey="${wasProfileRoot}/${profile}/properties/profileKey.metadata"
    if [[ -f "${profileKey}" ]]; then
        profileType=$(getWASProfileType "${profileKey}")
    fi

    if [[ "${profileType}" == "BASE" ]]; then
        echo "true"
    else
        echo "false"
    fi

}

# Determine if this server is a managed webserver
function isWASWebserver() {

    # Get all server.xml files in the cell, find the one for this server, and see if it's a webserver
    if [[ $(find "${wasProfileRoot}/${profile}/config/cells/${wasCellName}/nodes" -name "server.xml" -print 2>/dev/null | \
        xargs grep "name=\""${server}"\"" | \
        grep -c "xmi:type=\"webserver:WebServer\"") > 0 ]]; then
        echo "true"
    else
        echo "false"
    fi      

}

# Determine if a given server is part of the WAS cell
function isServerInWASCell() {

        local server="${1}"
        local profile="${2}"
        local isInCell="false"

        # Build an array of servers known to this cell
        local cellServers=($( \
            find "${wasProfileRoot}/${profile}/config/cells/${wasCellName}/nodes" -name "serverindex.xml" -print 2>/dev/null | \
            xargs grep "serverName" | \
            awk -F 'serverName=' '{print $2}' | \
            awk '{print $1}' | \
            tr -d '"' | \
            sort | \
            uniq \
        )) 

        # Verify that the server exists in the cell
        for cellServer in "${cellServers[@]}"; do
            if [[ "${cellServer}" == "${server}" ]]; then
                isInCell="true"
            fi
        done

        echo "${isInCell}"

}

# Prints the status of the specified WAS server
# $1: server to check
# $2: profile root
# $3: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getWASServerStatus() {

    local server="${1}"
    local profile="${2}"
    local noDisplay="${3}"

    # Get the basename of the profile directory
    local profileBasename=$(basename "${profile}")

    # If no WAS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${wasInstallDir}" || ! -d "${wasInstallDir}" ]]; then
        return
    fi

    # Only print info if noDisplay is not true
    if [[ "${noDisplay}" != "true" ]]; then
        printf "${left2Column}" "Server: ${profileBasename}.${server}"
    fi

    # This approach is much faster than using serverStatus.sh and unlikely to yield false positives
    if [[ $(ps -ef | grep -v "grep" | grep "${profile}" | awk '{print $NF}' | grep -c "${server}") > 0 ]]; then 
        # If we found a match, the server is started
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STARTED"
        else
            printf "${right2Column}" "${greenText}STARTED${normalText}"
        fi
    else 
        # If we did not find a match, the server is stopped
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STOPPED"
        else
            printf "${right2Column}" "${redText}STOPPED${normalText}"
        fi
    fi

}

# Start the specified WAS server
# $1: server
# $2: profile path
function startWASServer() {

    local server="${1}"
    local profile="${2}"

    # Get the basename of the profile directory
    local profileBasename=$(basename "${profile}")

    printf "${left2Column}" "Starting server ${server} in profile ${profileBasename}..."

    if [[ "$(getWASServerStatus "${server}" "${profile}" "true")" == "STOPPED" ]]; then
        # If the server is stopped, start it
        local status="$("${profile}/bin/startServer.sh" "${server}")"
        if [[ "${status}" =~ "ADMU3027E" || "${status}" =~ "ADMU3000I" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi
    else
        # The server is already started, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# Stop the specified WAS server
# $1: server
# $2: profile path
function stopWASServer() {

    local server="${1}"
    local profile="${2}"

    # Get the basename of the profile directory
    local profileBasename=$(basename "${profile}")

    printf "${left2Column}" "Stopping server ${server} in profile ${profileBasename}..."

    if [[ "$(getWASServerStatus "${server}" "${profile}" "true")" == "STARTED" ]]; then
        # If the server is started, stop it
        local status="$("${profile}/bin/stopServer.sh" "${server}" -username "${wasAdmin}" -password "${wasAdminPwd}")"
        if [[ "${status}" =~ "ADMU0509I" || "${status}" =~ "ADMU4000I" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi
    else
        # The server is already stopped, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# End of WAS section =======================================================================================================================

# Section: IHS =============================================================================================================================

# Prints the status of the IHS server
# $1: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getIHSServerStatus() {

    local noDisplay="${1}"

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        return
    fi

    # Only print info if noDisplay is not true
    if [[ "${noDisplay}" != "true" ]]; then
        printf "${left2Column}" "Server: IHS"
    fi

    # See if the server is running
    if [[ $(ps -ef | grep "${ihsInstallDir}/bin/httpd" | grep -v "grep" | grep -c -v "admin.conf") > 0 ]]; then
        # If we found a match, the server is started
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STARTED"
        else
            printf "${right2Column}" "${greenText}STARTED${normalText}"
        fi
    else 
        # If we did not find a match, the server is stopped
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STOPPED"
        else
            printf "${right2Column}" "${redText}STOPPED${normalText}"
        fi
    fi

}

# Start IHS server
function startIHSServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Starting IHS server..."

    if [[ "$(getIHSServerStatus "true")" == "STOPPED" ]]; then
        # If the server is stopped, start it 
        "${ihsInstallDir}/bin/apachectl" "start" >/dev/null 2>&1
        # Check to see if the server is started
        if [[ "$(getIHSServerStatus "true")" == "STARTED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already started, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# Stop IHS server
function stopIHSServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Stopping IHS server..."

    if [[ "$(getIHSServerStatus "true")" == "STARTED" ]]; then
        # If the server is started, stop it
        "${ihsInstallDir}/bin/apachectl" "stop" >/dev/null 2>&1
        # Wait a few seconds for process termination 
        sleep ${serviceDelaySeconds} 
        # Kill any remaining processes
        ps -ef | grep "${ihsInstallDir}/bin" | grep -v "admin.conf" | grep -v "grep" | awk '{print $2}' | xargs -r kill -9 >/dev/null 2>&1
        # Check to see if server is stopped
        if [[ "$(getIHSServerStatus "true")" == "STOPPED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already stopped, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# Prints the status of the IHS admin server
# $1: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getIHSAdminServerStatus() {

    local noDisplay="${1}"

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        return
    fi

    # Only print info if noDisplay is not true
    if [[ "${noDisplay}" != "true" ]]; then
        printf "${left2Column}" "Server: IHS Admin"
    fi

    # See if the server is running
    if [[ $(ps -ef | grep "${ihsInstallDir}/bin/httpd" | grep -v "grep" | grep -c "admin.conf") > 0 ]]; then
        # If we found a match, the server is started
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STARTED"
        else
            printf "${right2Column}" "${greenText}STARTED${normalText}"
        fi
    else 
        # If we did not find a match, the server is stopped
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STOPPED"
        else
            printf "${right2Column}" "${redText}STOPPED${normalText}"
        fi
    fi

}

# Start IHS admin server
function startIHSAdminServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Starting IHS Admin server..."
    
    if [[ "$(getIHSAdminServerStatus "true")" == "STOPPED" ]]; then
        # If the server is stopped, start it 
        "${ihsInstallDir}/bin/adminctl" "start" >/dev/null 2>&1
        # Check to see if server is started
        if [[ "$(getIHSAdminServerStatus "true")" == "STARTED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already started, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi
 
}

# Stop IHS admin server
function stopIHSAdminServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Stopping IHS Admin server..."

    if [[ "$(getIHSAdminServerStatus "true")" == "STARTED" ]]; then
        # If the server is started, stop it
        "${ihsInstallDir}/bin/adminctl" "stop" >/dev/null 2>&1
        # Wait a few seconds for process termination 
        sleep ${serviceDelaySeconds} 
        # Kill any remaining processes
        ps -ef | grep "${ihsInstallDir}/bin" | grep "admin.conf" | grep -v "grep" | awk '{print $2}' | xargs -r kill -9 >/dev/null 2>&1
        # Check to see if server is stopped
        if [[ "$(getIHSAdminServerStatus "true")" == "STOPPED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already stopped, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# End of IHS section =======================================================================================================================

# Section: NGINX ===========================================================================================================================

# Prints the status of the NGINX server
# $1: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getNGINXServerStatus() {

    local noDisplay="${1}"

    # If the NGINX binary doesn't exist, do nothing 
    local nginx="$(which nginx)"
    if [[ ${?} != 0 ]]; then
        return
    fi

    # Only print info if noDisplay is not true
    if [[ "${noDisplay}" != "true" ]]; then
        printf "${left2Column}" "Server: NGINX"
    fi

    # See if the server is running
    if [[ $(ps -ef | grep -v "grep" | grep -c "nginx") > 0 ]]; then
        # If we found a match, the server is started
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STARTED"
        else
            printf "${right2Column}" "${greenText}STARTED${normalText}"
        fi
    else 
        # If we did not find a match, the server is stopped
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STOPPED"
        else
            printf "${right2Column}" "${redText}STOPPED${normalText}"
        fi
    fi

}

# Start NGINX server
function startNGINXServer() {

    # If the NGINX binary doesn't exist, do nothing 
    local nginx="$(which nginx)"
    if [[ ${?} != 0 ]]; then
        return
    fi

    printf "${left2Column}" "Starting NGINX server..."

    if [[ "$(getNGINXServerStatus "true")" == "STOPPED" ]]; then
        # If the server is stopped, start it 
        "${nginx}" >/dev/null 2>&1
        # Check to see if the server is started
        if [[ "$(getNGINXServerStatus "true")" == "STARTED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already started, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi
    
}
# Stop NGINX server
function stopNGINXServer() {

    # If the NGINX binary doesn't exist, do nothing 
    local nginx="$(which nginx)"
    if [[ ${?} != 0 ]]; then
        return
    fi

    printf "${left2Column}" "Stopping NGINX server..."

    if [[ "$(getNGINXServerStatus "true")" == "STARTED" ]]; then
        # If the server is started, stop it
        "${nginx}" -s stop >/dev/null 2>&1
        # Wait a few seconds for process termination 
        sleep ${serviceDelaySeconds} 
        # Kill any remaining processes
        ps -ef | grep "nginx" | grep -v "grep" | awk '{print $2}' | xargs -r kill -9 >/dev/null 2>&1
        # Check to see if server is stopped
        if [[ "$(getNGINXServerStatus "true")" == "STOPPED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already stopped, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# End of NGINX section =====================================================================================================================

# Section: Solr ============================================================================================================================

# Prints the status of the Solr server
# $1: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getSolrServerStatus() {

    local noDisplay="${1}"

    # If no Solr installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${solrInstallDir}" || ! -d "${solrInstallDir}" ]]; then
        return
    fi

    # Only print info if noDisplay is not true
    if [[ "${noDisplay}" != "true" ]]; then
        printf "${left2Column}" "Server: Solr"
    fi

    # See if the server is running
    if [[ $(ps -ef | grep -v "grep" | grep -c "solr/quick-results-collection") > 0 ]]; then
        # If we found a match, the server is started
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STARTED"
        else
            printf "${right2Column}" "${greenText}STARTED${normalText}"
        fi
    else 
        # If we did not find a match, the server is stopped
        if [[ "${noDisplay}" == "true" ]]; then
            echo "STOPPED"
        else
            printf "${right2Column}" "${redText}STOPPED${normalText}"
        fi
    fi

}

# Start Solr server
function startSolrServer() {

    # If no Solr installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${solrInstallDir}" || ! -d "${solrInstallDir}" ]]; then
        log "Solr does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Starting Solr server..."

    # See if Java is installed
    local java="$(which java)"
    if [[ ${?} != 0 ]]; then
        printf "${right2Column}" "${redText}FAILURE${normalText}" "(Could not find Java)"
        exit 1
    fi

    if [[ "$(getSolrServerStatus "true")" == "STOPPED" ]]; then
        # If the server is stopped, start it 
        cd "${solrInstallDir}/node1" 2>/dev/null
        nohup "${java}" \
            -jar "${solrInstallDir}/node1/start.jar" \
            "-DSTOP.PORT=${solrPort}" \
            "-DSTOP.KEY=${solrKey}" \
            "-Djetty.ssl.clientAuth=true" \
            "-Dhost=$(hostname --fqdn)" \
            "-Dcollection.configName=myConf" \
            "-DzkRun" \
            "-DnumShards=1" \
            "-Dbootstrap_confdir=${solrInstallDir}/node1/solr/quick-results-collection/conf" \
            >/dev/null 2>&1 &
        # Wait a few seconds for the server to start
        sleep ${serviceDelaySeconds} 
        # Check to see if the server is started
        if [[ "$(getSolrServerStatus "true")" == "STARTED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already started, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# Stop Solr server
function stopSolrServer() {

    # If no Solr installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${solrInstallDir}" || ! -d "${solrInstallDir}" ]]; then
        log "Solr does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Stopping Solr server..."

    # See if Java is installed
    local java="$(which java)"
    if [[ ${?} != 0 ]]; then
        printf "${right2Column}" "${redText}FAILURE${normalText}" "(Could not find Java)"
        exit 1
    fi

    if [[ "$(getSolrServerStatus "true")" == "STARTED" ]]; then
        # If the server is started, stop it 
        "${java}" \
            -jar "${solrInstallDir}/node1/start.jar" \
            "-DSTOP.PORT=${solrPort}" \
            "-DSTOP.KEY=${solrKey}" \
            "--stop" \
            >/dev/null 2>&1
        # Wait a few seconds for the server to stop
        sleep ${serviceDelaySeconds} 
        # Check to see if the server is stopped
        if [[ "$(getSolrServerStatus "true")" == "STOPPED" ]]; then
            printf "${right2Column}" "${greenText}SUCCESS${normalText}"
        else
            printf "${right2Column}" "${redText}FAILURE${normalText}"
        fi 
    else
        # The server is already stopped, so report success
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi

}

# End of Solr section ======================================================================================================================

# Section: Connections =====================================================================================================================

# Tests to make sure Connections is installed on this system
function checkForIC() {

    local script="$(basename "${0}")"

    if [[ ! -d "${icInstallDir}" ]]; then
        log "${script} can only run on Connections nodes. Exiting."
        exit 1
    fi

}

# End of Connections section ===============================================================================================================

# Section: Misc ============================================================================================================================

# Log message to stdout
function log() {

    local message="${1}"

	printf "%s\n" "${message}"

}

# Write a message to output file
function output() {

    local message="${1}"
    local file="${2}"

    if [[ -n "${file}" && -w "${file}" ]]; then
        printf "%s\n" "${message}" >>"${file}"
    fi

}

# Write a formatted message to output file
function outputFormatted() {

    local message="${1}"
    local format="${2}"
    local file="${3}"

    if [[ -n "${file}" && -w "${file}" ]]; then
        printf "${format}" "${message}" >>"${file}"
    fi

}

# Write a message with timestamp to output file
function outputTS() {

    local message="${1}"
    local file="${2}"
    local now="$(date '+%F %T')"

    if [[ -n "${file}" && -w "${file}" ]]; then
        printf "%s\n" "${now} ${message}" >>"${file}"
    fi

}

# Write a formatted message with timestamp to output file
function outputFormattedTS() {

    local message="${1}"
    local format="${2}"
    local file="${3}"
    local now="$(date '+%F %T')"

    if [[ -n "${file}" && -w "${file}" ]]; then
        printf "${format}" "${now} ${message}" >>"${file}"
    fi

}

# Write a message to two files
function teeOutput() {

    local message="${1}"
    local file1="${2}"
    local file2="${3}"

    if [[ -n "${file1}" && -w "${file1}" ]]; then
        printf "%s\n" "${message}" >>"${file1}"
    fi

    if [[ -n "${file2}" && -w "${file2}" ]]; then
        printf "%s\n" "${message}" >>"${file2}"
    fi

}

# Write a formatted message to two files
function teeOutputFormatted() {

    local message="${1}"
    local format1="${2}"
    local file1="${3}"
    local format2="${4}"
    local file2="${5}"

    if [[ -n "${file1}" && -w "${file1}" ]]; then
        printf "${format1}" "${message}" >>"${file1}"
    fi

    if [[ -n "${file2}" && -w "${file2}" ]]; then
        printf "${format2}" "${message}" >>"${file2}"
    fi

}

# Write a message with timestamp to two files
function teeOutputTS() {

    local message="${1}"
    local file1="${2}"
    local file2="${3}"
    local now="$(date '+%F %T')"

    if [[ -n "${file1}" && -w "${file1}" ]]; then
        printf "%s\n" "${now} ${message}" >>"${file1}"
    fi

    if [[ -n "${file2}" && -w "${file2}" ]]; then
        printf "%s\n" "${now} ${message}" >>"${file2}"
    fi

}

# Write a formatted message with timestamp to two files
function teeOutputFormattedTS() {

    local message="${1}"
    local format1="${2}"
    local file1="${3}"
    local format2="${4}"
    local file2="${5}"
    local now="$(date '+%F %T')"

    if [[ -n "${file1}" && -w "${file1}" ]]; then
        printf "${format1}" "${now} ${message}" >>"${file1}"
    fi

    if [[ -n "${file2}" && -w "${file2}" ]]; then
        printf "${format2}" "${now} ${message}" >>"${file2}"
    fi

}

# Print a two-column table row to the provided file
function output2ColumnTableRow() {

    local column1="${1}"
    local column2="${2}"
    local format="${3}"
    local file="${4}"

    if [[ -n "${column1}" && -n "${column2}" && -n "${format}" ]]; then
        printf "${format}" "${column1}" "${column2}" >>"${file}"
    fi

}

# Print a two-column table row to two files
function teeOutput2ColumnTableRow() {

    local column1="${1}"
    local column2="${2}"
    local format="${3}"
    local file1="${4}"
    local file2="${5}"

    if [[ -n "${column1}" && -n "${column2}" && -n "${format}" ]]; then
        if [[ -w "${file1}" ]]; then
            printf "${format}" "${column1}" "${column2}" >>"${file1}"
        fi
        if [[ -w "${file2}" ]]; then
            printf "${format}" "${column1}" "${column2}" >>"${file2}"
        fi
    fi

}

# Print a three-column table row to the provided file
function output3ColumnTableRow() {

    local column1="${1}"
    local column2="${2}"
    local column3="${3}"
    local format="${4}"
    local file="${5}"

    if [[ -n "${column1}" && -n "${column2}" && -n "${column3}" && -n "${format}" ]]; then
        printf "${format}" "${column1}" "${column2}" "${column3}" >>"${file}"
    fi

}

# Print a three-column table row to two files
function teeOutput3ColumnTableRow() {

    local column1="${1}"
    local column2="${2}"
    local column3="${3}"
    local format="${4}"
    local file1="${5}"
    local file2="${6}"

    if [[ -n "${column1}" && -n "${column2}" && -n "${column3}" && -n "${format}" ]]; then
        if [[ -w "${file1}" ]]; then
            printf "${format}" "${column1}" "${column2}" "${column3}" >>"${file1}"
        fi
        if [[ -w "${file2}" ]]; then
            printf "${format}" "${column1}" "${column2}" "${column3}" >>"${file2}"
        fi
    fi

}

# End of Misc section ======================================================================================================================
