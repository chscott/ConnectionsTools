#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallKubernetes.log"
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
    kubernetesDirs=(
        "/var/lib/calico"
        "/etc/cni"
        "/var/lib/cni"
        "/var/lib/dockershim"
        "/var/lib/etcd"
        "/var/lib/kubelet"
        "/etc/kubernetes"
    )
    clean="false"

    while [[ ${#} > 0 ]]; do
        local key="${1}"
        case "${key}" in
            --help)
                usage
                exit 0
                shift;;
            --clean)
                clean="true"
                shift;;
            *)
                printToConsole "Unrecognized argument ${key}"
                exit 1
        esac
    done

    # Print log header
    printToLog "Distro: $(getDistro)"
    printToLog "Major version: $(getOSMajorVersion)"
    printToLog "Minor version: $(getOSMinorVersion)"

}

# Print the usage text to the console
function usage() {

    printToConsole "Usage: uninstallKubernetes.sh [OPTIONS]"
    printToConsole ""
    printToConsole "Options:"
    printToConsole ""
    printToConsole "--clean"
    printToConsole ""
    printToConsole "In addition to uninstalling Kubernetes, delete the Kubernetes data and configuration directories."

}

# Print to the console (and to the log)
function printToConsole() {

    local message="${1}"

	printf "%s\n" "${message}" >&101
    printToLog "${message}"

}

# Print to the specified log
function printToLog() {

    local message="${1}"
    local now="$(date '+%F %T')"

	printf "%s %s\n" "${now}" "${message}" >>"${logFile}"

}

# Print error message and exit
function exitWithError() {

    local message="${1}"

    printToConsole "${message}."
    printToConsole "Review ${logFile} for additional details"
    exit 1

}

# Tear down the node prior to uninstalling
function tearDownNode() {

    local thisNode="$(uname -n)"

    if [[ "$(isNodeInK8sCluster "${thisNode}")" == "true" ]]; then
        # This node is part of the cluster
        printToConsole "Removing node ${thisNode} from the Kubernetes cluster..." 
        if [[ "$(commandExists "kubectl")" == "true" ]]; then
            kubectl drain "${thisNode}" --delete-local-data --force --ignore-daemonsets
            kubectl delete node "${thisNode}"
        else
            printToConsole "ERROR! Unable to drain and delete node because kubectl is not installed on this system." 
            exitWithError "Drain and delete this node before attempting to uninstall Kubernetes."
        fi
        if [[ "$(commandExists "kubeadm")" == "true" ]]; then
            kubeadm reset --force --cri-socket "unix:///var/run/dockershim.sock"
        else
            printToConsole "WARNING! Unable to reset installed state because kubeadm is not installed on this system." 
        fi
    else
        # This node is not part of the cluster
        printToLog "This node is not in the Kubernetes cluster. Node name: ${thisNode}"
        
    fi

}

# Uninstall the specified package. Current behavior relies on package managers not returning error codes if packages are simply not found
function uninstallPackage() {

    local package="${1}"
    local distro="$(getDistro)"

    # yum
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if yum list installed "${package}"; then 
            yum versionlock delete "${package}"
            yum remove -y "${package}" || exitWithError "Error uninstalling Kubernetes components"
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            dnf versionlock delete "${package}"
            dnf remove -y "${package}" || exitWithError "Error uninstalling Kubernetes components"
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}"; then 
            apt-mark unhold "${package}"
            apt-get purge -y "${package}" || exitWithError "Error uninstalling Kubernetes components"
        fi
    fi

}

# Do the uninstall
function uninstall() {

    local packages=( 
        "kubeadm"
        "kubectl" 
        "kubelet"
    )
         
    printToConsole "Uninstalling Kubernetes..."

    for package in "${packages[@]}"; do
        printToLog "Uninstalling package ${package}..."
        uninstallPackage "${package}"
    done

    printToConsole "Successfully uninstalled Kubernetes"

}

# Delete additional Kubernetes config/data (not yet implemented)
function makeClean() {

    printToConsole "Deleting Kubernetes directories..."

    for directory in "${kubernetesDirs[@]}"; do
        printToLog "Deleting ${directory}..."
        rm -f -r "${directory}"
    done 

}

init "${@}"

if [[ "${clean}" == "true" ]]; then
    # Since this is destructive, ask for confirmation
    printToConsole "WARNING! The --clean option will delete all Kubernetes directories, removing all configuration and data"
    printToConsole ""
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>&101
    if [[ ! -z "${answer}" && "${answer}" == "yes" ]]; then
        tearDownNode
        uninstall
        makeClean
    else
        printToConsole "Aborting Kubernetes uninstall"
    fi
else
    tearDownNode
    uninstall
fi
