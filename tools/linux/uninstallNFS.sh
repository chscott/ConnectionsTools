#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/uninstallNFS.log"
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
    clean="false"
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
            --clean)
                clean="true"
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

    outputToTerminal "Usage: uninstallNFS.sh [OPTIONS]"
    outputToTerminal ""
    outputToTerminal "Options:"
    outputToTerminal ""
    outputToTerminal "--export-root <directory>"
    outputToTerminal "  The root directory from which NFS exports will be deleted."
    outputToTerminal ""
    outputToTerminal "--clean"
    outputToTerminal "  In addition to uninstalling NFS services, also delete the NFS export directories. Data will be lost!"

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

# Uninstall the specified package. Current behavior relies on package managers not returning error codes if packages are simply not found
function uninstallPackage() {

    local distro="$(getDistro)"

    # yum
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
        if yum list installed "${package}"; then 
            outputOperation "Removing package ${package}..."
            yum remove -y "${package}" && pass || fail
        fi
    # dnf
    elif [[ "${distro}" == "fedora" ]]; then
        if dnf list installed "${package}"; then 
            outputOperation "Removing package ${package}..."
            dnf remove -y "${package}" && pass || fail
        fi
    # apt
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if dpkg-query --list "${package}" | grep "^.i"; then 
            outputOperation "Removing package ${package}..."
            apt-get purge -y "${package}" && pass || fail
        fi
    fi

}

# Do the uninstall
function uninstall() {

    local distro="$(getDistro)"

    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        local packages=("nfs-utils" "rpcbind")
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        local packages=("nfs-kernel-server" "rpcbind")
    fi
         
    for package in "${packages[@]}"; do
        uninstallPackage "${package}"
    done

}

# Update /etc/exports
function updateExportsFile() {

    local netAddress=$(hostname -i | awk -F "." '{print $1"."$2".0.0"}')

    for volume in "${volumes[@]}"; do
        if grep "${exportRoot}${exportPVRoot}${volume}" "/etc/exports" >/dev/null 2>&1; then
            outputOperation "Removing export directory ${exportRoot}${exportPVRoot}${volume} from /etc/exports..."
            sed -i "\%${exportRoot}${exportPVRoot}${volume}%d" "/etc/exports" && pass || fail
        fi 
    done

}

# Configure firewall
function configureFirewall() {

    local distro="$(getDistro)"

    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        outputOperation "Closing NFS ports..."
        firewall-cmd --remove-service=nfs --permanent && pass || warn
        outputOperation "Reloading firewall rules..."
        firewall-cmd --reload && pass || warn
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        outputOperation "Closing NFS ports..."
        ufw deny "nfs" && pass || warn
        outputOperation "Reloading firewall rules..."
        ufw reload && pass || warn
    fi

}

# Delete export directories
function makeClean() {

    outputOperation "Deleting Connections export directories in ${exportRoot}${exportPVRoot}..."
    rm -f -r "${exportRoot}${exportPVRoot}" && pass || fail

}

# Report status
function term() {

    outputToTerminal ""
    outputToTerminal "NFS successfully uninstalled!"

}

init "${@}"

if [[ "${clean}" == "true" ]]; then
    # Since this is destructive, ask for confirmation
    outputToTerminal ""
    outputToTerminal "WARNING! The --clean option will remove the ${exportRoot}${exportPVRoot} directory."
    outputToTerminal "All data will be deleted!"
    outputToTerminal ""
    read -p "If you are certain you want to do this, enter 'yes' and press Enter: " answer 2>>"${terminal}"
    outputToTerminal ""
    if [[ -n "${answer}" && "${answer}" == "yes" ]]; then
        uninstall
        updateExportsFile
        configureFirewall
        makeClean
        term
    else
        exitWithError "Aborting NFS uninstall"
    fi
else
    uninstall
    updateExportsFile
    configureFirewall
    term
fi
