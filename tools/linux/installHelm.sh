#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installHelm.log"
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
    checkRequirements="false"

    while [[ ${#} > 0 ]]; do
        local key="${1}"
        case "${key}" in
            --help)
                usage
                exit 0
                shift;;
            --check)
                checkRequirements="true"
                shift;;
            *)
                outputToTerminal "Unrecognized argument ${key}"
                exit 1
        esac
    done

}

# Print the usage text to the terminal
function usage() {

    outputToTerminal "Usage: installHelm.sh [OPTIONS]"
    outputToTerminal ""
    outputToTerminal "Options:"
    outputToTerminal ""
    outputToTerminal "--check"
    outputToTerminal "  Checks the system to see if meets the requirement to install Component Pack components."

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

    outputCPRequirementsTable "${file}"

}

# Test prereqs for install. Any checks that do not pass exit immediately
function checkForPrereqs() {

    # Check the platform requirements
    outputOperation "Verifying platform meets requirements to install Component Pack..."
    if [[ "$(isCPSupportedPlatform)" == "true" ]]; then pass; else fail; fi
    
    # Verify Kubernetes is installed
    outputOperation "Verifying Kubernetes ${CP_K8S_SUPPORTED_RELEASE} is installed..."
    if [[ "$(getK8sComponentVersion "kubeadm")" == "${CP_K8S_SUPPORTED_RELEASE}" &&
          "$(getK8sComponentVersion "kubectl")" == "${CP_K8S_SUPPORTED_RELEASE}" &&
          "$(getK8sComponentVersion "kubelet")" == "${CP_K8S_SUPPORTED_RELEASE}" ]]; then pass; else fail; fi 
        
    # TODO: See if Helm is already installed
    outputOperation "Checking to see if Helm is already installed..." && pass

}

# Install the client
function installClient() {

    local installUrl="https://storage.googleapis.com/kubernetes-helm/helm-v${CP_HELM_SUPPORTED_RELEASE}-linux-amd64.tar.gz"
    local installPackage="/tmp/helm.tar.gz"
    local installDir="/bin"

    # Download the install package
    outputOperation "Downloading Helm client..."
    curl -L -s -S -f "${installUrl}" >"${installPackage}" && pass || fail

    # Unpack the helm binary (i.e. "install it")
    outputOperation "Installing Helm client..."
    tar --strip-components=1 -xzf "${installPackage}" -C "${installDir}" "linux-amd64/helm" && pass || fail

    # Delete the install package
    rm "${installPackage}"

}

# Install the server
function installServer() {

    local imageBase="gcr.io/kubernetes-helm/tiller"

    # Install tiller into the cluster
    outputOperation "Initializing Helm server..."
    helm init --tiller-image "${imageBase}:v${CP_HELM_SUPPORTED_RELEASE}" && pass || fail

}

# Do the install
function install() {

    installClient
    installServer

}

# Report status
function term() {

    outputToTerminal ""
    outputToTerminal "Helm successfully installed!"

}

init "${@}"

if [[ "${checkRequirements}" == "true" ]]; then
    # Just check requirements
    checkForRequirements "${terminal}"
else
    # Do the install
    checkForRequirements "${logFile}"
    checkForPrereqs
    install
fi 
