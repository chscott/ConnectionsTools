#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallKubernetes.log"
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
    kubernetesDirs=(
        "/var/lib/calico"
        "/var/lib/cni"
        "/var/lib/dockershim"
        "/var/lib/etcd"
        "/var/lib/kubelet"
        "/etc/cni"
        "/etc/kubernetes"
    )
    clean="false"
    force="false"
    warnings="false"

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
            --force)
                force="true"
                shift;;
            *)
                outputToTerminal "Unrecognized argument ${key}"
                exit 1
        esac
    done

}

# Print the usage text to the terminal
function usage() {

    outputToTerminal "Usage: uninstallKubernetes.sh [OPTIONS]"
    outputToTerminal ""
    outputToTerminal "Options:"
    outputToTerminal ""
    outputToTerminal "--clean"
    outputToTerminal "  In addition to uninstalling Kubernetes, delete the Kubernetes data and configuration directories."
    outputToTerminal ""
    outputToTerminal "--force"
    outputToTerminal "  Ignore failures when tearing down the node."

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

# Tear down the node prior to uninstalling
function tearDownNode() {

    local thisNode="$(uname -n)"

    outputToLog "Tearing down node ${thisNode}..."

    if [[ "$(isNodeInK8sCluster "${thisNode}")" == "true" ]]; then

        # If this is the master node, make sure there are no other nodes in the cluster
        if [[ "$(getK8sNodeType "${thisNode}")" == "master" ]]; then
            outputOperation "Verifying there are no non-master nodes in cluster..."
            local nonMasterNodeCount="$(getK8sNonMasterNodeCount)"
            if (( $(getK8sNonMasterNodeCount) == 0 )); then
                pass
            else
                # Either unable to get node count or there is at least 1 non-master node. Use --force option to continue or abort
                outputToLog "Kubernets nodes:"
                kubectl get nodes --no-headers
                if [[ "${force}" == "true" ]]; then warn; else fail; fi
            fi
        fi
        
        # Clean up the node
        outputOperation "Draining node ${thisNode}..."
        kubectl drain "${thisNode}" --delete-local-data --force --ignore-daemonsets && pass || if [[ "${force}" == "true" ]]; then warn; else fail; fi 
        outputOperation "Deleting node ${thisNode}..."
        kubectl delete node "${thisNode}" && pass || if [[ "${force}" == "true" ]]; then warn; else fail; fi
        outputOperation "Undoing changes made by kubeadm..."
        kubeadm reset --force --cri-socket "unix:///var/run/dockershim.sock" && pass || if [[ "${force}" == "true" ]]; then warn; else fail; fi

    else
        # This node is not part of the cluster
        outputToLog "This node is not in the Kubernetes cluster. Node name: ${thisNode}"
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
            outputOperation "Removing package ${package}..."
            yum remove -y "${package}" && pass || fail
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            dnf versionlock delete "${package}"
            outputOperation "Removing package ${package}..."
            dnf remove -y "${package}" && pass || fail
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}" | grep "^.i"; then 
            apt-mark unhold "${package}"
            outputOperation "Removing package ${package}..."
            apt-get purge -y "${package}" && pass || fail
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
         
    for package in "${packages[@]}"; do
        uninstallPackage "${package}"
    done

}

# Delete additional Kubernetes config/data (not yet implemented)
function makeClean() {

    for directory in "${kubernetesDirs[@]}"; do
        outputOperation "Deleting ${directory}..."
        rm -f -r "${directory}" && pass || fail
    done 

}

# Report status
function term() {

    outputToTerminal ""
    if [[ "${warnings}" == "false" ]]; then
        outputToTerminal "Kubernetes has been uninstalled successfully!"
    else
        outputToTerminal "Kubernetes has been uninstalled with warnings. Review ${logFile} for additional details." 
    fi

}

init "${@}"

if [[ "${clean}" == "true" ]]; then
    # Since this is destructive, ask for confirmation
    outputToTerminal ""
    outputToTerminal "WARNING! The --clean option will remove all Kubernetes directories."
    outputToTerminal "All configuration and data will be deleted!"
    outputToTerminal ""
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>>"${terminal}"
    outputToTerminal ""
    if [[ -n "${answer}" && "${answer}" == "yes" ]]; then
        tearDownNode
        uninstall
        makeClean
        term
    else
        exitWithoutError "Aborting Kubernetes uninstall"
    fi
else
    tearDownNode
    uninstall
    term
fi
