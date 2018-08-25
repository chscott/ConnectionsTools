#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installHelm.log"
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
    checkRequirements="false"

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

    printToConsole "Usage: installHelm.sh [OPTIONS]"
    printToConsole ""
    printToConsole "Options:"
    printToConsole ""
    printToConsole "--check"
    printToConsole ""
    printToConsole "Checks the system to see if meets the requirement to install Component Pack components."

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

    # Pass the file descriptor that points to the terminal
    printCPRequirementsTable "101"

}

# Exit on any failed checks
function checkForPrereqs() {

    printToConsole "Checking to ensure system has all prerequisites in place to install Helm..."

    # Check the platform requirements
    printToLog "Checking to see if platform meets requirements to install Component Pack..."
    if [[ "$(isCPSupportedPlatform)" == "false" ]]; then 
        exitWithError "This platform does not meet the requirements to install Component Pack"
    fi
    
    # Verify Kubernetes is installed
    printToLog "Checking to see if Kubernetes is installed..."
        
    # See if Helm is already installed
    printToLog "Checking to see if Helm is already installed..."

}

# Install the client
function installClient() {

    local installUrl="https://storage.googleapis.com/kubernetes-helm/helm-v${CP_HELM_SUPPORTED_RELEASE}-linux-amd64.tar.gz"
    local installPackage="/tmp/helm.tar.gz"
    local installDir="/bin"

    printToLog "Installing Helm client..."

    # Download the install package
    curl -L -s -S -f "${installUrl}" >"${installPackage}" ||  exitWithError "Unable to install Helm client"

    # Unpack the helm binary (i.e. "install it")
    tar --strip-components=1 -xzf "${installPackage}" -C "${installDir}" "linux-amd64/helm" || exitWithError "Unable to install Helm client"

    # Delete the install package
    rm "${installPackage}"

    printToLog "Successfully installed Helm client"

}

# Install the server
function installServer() {

    local imageBase="gcr.io/kubernetes-helm/tiller"

    printToLog "Installing Helm server..."

    # Install tiller into the cluster
    helm init --tiller-image "${imageBase}:v${CP_HELM_SUPPORTED_RELEASE}" || exitWithError "Unable to install Helm server"

    printToLog "Successfully installed Helm client"

}

# Do the install
function install() {

    local distro="$(getDistro)"
    local version=""

    printToConsole "Installing Helm..."

    installClient
    installServer

    printToConsole "Helm successfully installed"

}

init "${@}"

if [[ "${checkRequirements}" == "true" ]]; then
    # Just check requirements
    checkForRequirements
else
    # Do the install
    checkForPrereqs
    install
fi 
