#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installNFS.log"
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
    exportRoot="/var/exports"
    exportPVRoot="/pv-connections"
    volumes=(
    "/mongo-node-0/data/db"
    "/mongo-node-1/data/db"
    "/mongo-node-2/data/db"
    "/solr-data-solr-0"
    "/solr-data-solr-1"
    "/solr-data-solr-2"
    "/zookeeper-data-zookeeper-0"
    "/zookeeper-data-zookeeper-1"
    "/zookeeper-data-zookeeper-2"
    "/esbackup"
    "/esdata-0"
    "/esdata-1"
    "/esdata-2"
    "/customizations"
    )

    while [[ ${#} > 0 ]]; do
        local key="${1}"
        local value="${2}"
        case "${key}" in
            --help)
                usage
                exit 0
                shift;;
            --export-root)
                exportRoot="${value}"
                # Setting exportRoot to '/' results in a path of //pv-connections. Address that here by setting exportRoot to null in that case
                if [[ "${exportRoot}" == "/" ]]; then
                    exportRoot=""
                fi
                shift;shift;;
            *)
                outputToTerminal "Unrecognized argument ${key}"
                exit 1
        esac
    done

}

# Print the usage text to the terminal
function usage() {

    outputToTerminal "Usage: configureNFS.sh [OPTIONS]"
    outputToTerminal ""
    outputToTerminal "Options:"
    outputToTerminal ""
    outputToTerminal "--export-root <directory>"
    outputToTerminal "  Set the root directory at which NFS exports will be created."

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

# Create export directories
function createExportDirectories() {

    for volume in "${volumes[@]}"; do
        outputOperation "Creating export directory ${exportRoot}${exportPVRoot}${volume}..." 
        mkdir -p "${exportRoot}${exportPVRoot}${volume}" && pass || fail
    done

}

# Update /etc/exports
function updateExportsFile() {

    local netAddress=$(hostname -i | awk -F "." '{print $1"."$2".0.0"}')

    for volume in "${volumes[@]}"; do
        outputOperation "Adding export directory ${exportRoot}${exportPVRoot}${volume} to /etc/exports..."
        if ! grep "${exportRoot}${exportPVRoot}${volume}" "/etc/exports"; then
            printf "${exportRoot}${exportPVRoot}${volume}\t${netAddress}/255.255.0.0(rw,no_root_squash)\n" >>"/etc/exports" && pass || fail
        else
            # Volume already exists in /etc/exports, so warn the user
            warn
        fi 
    done

}

# Install NFS packages
function installNFSPackages() {

    local distro="$(getDistro)"

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
        outputOperation "Installing prerequisite packages..."
        yum -y --enablerepo "${baseRepo}" install "nfs-utils" "rpcbind" && pass || fail
    # Fedora
    elif [[ "${distro}" == "fedora" ]]; then
        outputOperation "Installing prerequisite packages..."
        dnf -y --enablerepo "fedora" install "nfs-utils" "rpcbind" && pass || fail
    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        outputOperation "Installing prerequisite packages..."
        apt-get -y install "nfs-kernel-server" "rpcbind" && pass || fail
    fi


}

# Enable NFS services
function enableNFSServices() {

    local distro="$(getDistro)"

    # CentOS/CentOS/Fedora
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        local services=("nfs-idmap" "nfs-lock" "nfs-server" "rpcbind")
    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        local services=("nfs-kernel-server")
    fi

    for service in "${services[@]}"; do
        outputOperation "Enabling service ${service}..."
        systemctl enable "${service}" && pass || fail
        outputOperation "Starting service ${service}..."
        systemctl start "${service}" && pass || fail
    done

}

# Configure firewall
function configureFirewall() {

    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        outputOperation "Opening NFS ports..."
        firewall-cmd --add-service=nfs --permanent && pass || warn
        outputOperation "Reloading firewall rules..."
        firewall-cmd --reload && pass || warn
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        outputOperation "Opening NFS ports..."
        ufw allow "nfs" && pass || warn
        outputOperation "Reloading firewall rules..."
        ufw reload && pass || warn
    fi

}

# Report status
function term() {

    outputToTerminal ""
    outputToTerminal "NFS successfully configured!"

}

init "${@}"

createExportDirectories
updateExportsFile
installNFSPackages
enableNFSServices
configureFirewall
term
