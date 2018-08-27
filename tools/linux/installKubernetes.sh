#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installKubernetes.log"
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
    isMasterNode="false"
    k8sConfigFile="/etc/kubernetes/admin.conf"
    joinClusterScript="/etc/kubernetes/joinCluster.sh"
    warnings="false"

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
            --master-node)
                isMasterNode="true"
                shift;;
            *)
                outputToTerminal "Unrecognized argument ${key}"
                exit 1
        esac
    done

}

# Print the usage text to the terminal
function usage() {

    outputToTerminal "Usage: installKubernetes.sh [OPTIONS]"
    outputToTerminal ""
    outputToTerminal "Options:"
    outputToTerminal ""
    outputToTerminal "--check"
    outputToTerminal "  Checks the system to see if meets the requirement to install Component Pack components."
    outputToTerminal ""
    outputToTerminal "--master-node"
    outputToTerminal "  Designate this as the master node for the Kubernetes cluster."

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
    
    # Verify docker-ce is installed at the required level
    outputOperation "Verifying Docker ${CP_DOCKER_SUPPORTED_RELEASE} is installed..."
    if [[ "$(getDockerCEVersion)" == "${CP_DOCKER_SUPPORTED_RELEASE}" ]]; then pass; else fail; fi 
        
    # See if Kubernetes is already installed
    outputOperation "Verifying Kubernetes is not already installed..."
    if [[ "$(isK8sComponentInstalled "kubeadm")" == "false" && 
          "$(isK8sComponentInstalled "kubectl")" == "false" && 
          "$(isK8sComponentInstalled "kubelet")" == "false" ]]; then pass; else fail; fi 

}

# Do the install
function install() {

    local distro="$(getDistro)"
    local version=""

    # Disable SELinux if enabled
    if [[ "$(commandExists "setenforce")" == "true" ]]; then
        outputOperation "Disabling SELinux..."
        setenforce 0 && pass || fail
    fi

    # CentOS/RHEL/Fedora
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then

        # All three are identical except for the package manager used. Set that to generic "mgr" to avoid duplicate code
        if [[ "${distro}" == "centos" || "${distro}" == "rhel" ]]; then
            local mgr="yum"
        elif [[ "${distro}" == "fedora" ]]; then
            local mgr="dnf" 
        fi

        # Add Kubernetes repo 
        outputToLog "Adding kubernetes repo..."
        local repoFile="/etc/yum.repos.d/kubernetes.repo"
        # Truncate file in case it exists
        printf "[kubernetes]\n" >|"${repoFile}"
        printf "name=Kubernetes\n" >>"${repoFile}"
        printf "baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\n" >>"${repoFile}"
        printf "enabled=1\n" >>"${repoFile}"
        printf "gpgcheck=1\n" >>"${repoFile}"
        printf "repo_gpgcheck=1\n" >>"${repoFile}"
        printf "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg " >>"${repoFile}"
        printf "https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg\n" >>"${repoFile}"

        # Update the package index
        outputOperation "Updating package index..."
        "${mgr}" -y makecache fast && pass || fail

        # Get the latest version of Kubernetes target (using kubeadm)
        outputToLog "Getting the latest version of Kubernetes target installation version ${CP_K8S_SUPPORTED_RELEASE}..."
        version="$("${mgr}" list "kubeadm" --showduplicates | \
            grep "${CP_K8S_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}')" 
        outputToLog "Latest version available: ${version}"

        # Install Kubernetes
        outputOperation "Performing Kubernetes install..."
        "${mgr}" -y install "kubelet-${version}" "kubeadm-${version}" "kubectl-${version}" && pass || fail

        # Lock the Kubernetes packages
        outputOperation "Locking the kubeadm, kubectl and kubelet packages to prevent auto-update..."
        "${mgr}" -y versionlock "kubeadm" "kubectl" "kubelet" && pass || fail

        # Update /etc/sysctl.d/k8s.conf

    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then

        # Install prereqs
        outputOperation "Installing prerequisite packages..."
        apt-get -y install \
            "apt-transport-https" \
            "ca-certificates" \
            "curl" \
            "gnupg2" \
            "software-properties-common" \
            "ufw" \
            && pass || fail

        # Add Kubernetes GPG key
        outputOperation "Adding Kubernetes GPG key to apt..."
        curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | apt-key add - && pass || fail

        # Add Kubernetes repo
        outputOperation "Adding Kubernetes repo..."
        add-apt-repository "deb [arch=amd64] http://apt.kubernetes.io kubernetes-xenial main" && pass || fail

        # Update the apt package index
        outputOperation "Updating package index..."
        apt-get -y update && pass || fail

        # Get the latest version of Kubernetes target (using kubeadm)
        outputToLog "Getting the latest version of Kubernetes target installation version ${CP_K8S_SUPPORTED_RELEASE}..."
        version="$(apt-cache madison "kubeadm" | \
            grep "${CP_K8S_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk -F '\\| ' '{print $2}' | \
            tr -d ' ')" 
        outputToLog "Latest version available: ${version}"

        # Install Kubernetes
        outputOperation "Performing Kubernetes install..."
        apt-get -y install "kubeadm=${version}" "kubectl=${version}" "kubelet=${version}" && pass || fail

        # Lock the Kubernetes packages
        outputOperation "Locking the kubeadm, kubectl and kubelet packages to prevent auto-update..."
        apt-mark hold "kubeadm" "kubectl" "kubelet" && pass || fail

    fi

}

# Configure systemd to automatically start kubelet
function configAutoStart() {

    outputOperation "Enabling auto-start for Kubernetes..."
    systemctl enable "kubelet" && pass || fail
    outputOperation "Starting Kubernetes..."
    systemctl start "kubelet" && pass || fail

}

# Set up this node as the master node
function configMasterNode() {

    local distro="$(getDistro)"
    local thisNode="$(uname -n)"

    outputToLog "Configuring node ${thisNode} as the master node..." 

    # Configure the firewall
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        # firewall-cmd uses a dash for ranges
        local masterNodePorts=("6443" "2379-2380" "10250-10252")
        for masterNodePort in "${masterNodePorts[@]}"; do
            outputOperation "Opening port(s) ${masterNodePort}..."
            firewall-cmd "--add-port=${masterNodePort}/tcp" --permanent && pass || warn
        done
        outputOperation "Reloading firewall rules..."
        firewall-cmd --reload && pass || warn
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        # ufw uses a colon for ranges
        local masterNodePorts=("6443" "2379:2380" "10250:10252")
        for masterNodePort in "${masterNodePorts[@]}"; do
            outputOperation "Opening port(s) ${masterNodePort}..."
            ufw allow "${masterNodePort}/tcp" && pass || warn
        done
        outputOperation "Reloading firewall rules..."
        ufw reload && pass || warn
    fi

    # Initialize the cluster
    outputOperation "Initializing cluster. This may take several minutes..."
    kubeadm init --pod-network-cidr="192.168.0.0/16" && pass || fail

    # Install pod network add-on
    local calicoUrl="https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted"
    outputOperation "Installing Calico rbac-kdd.yaml..."
    kubectl apply --filename "${calicoUrl}/rbac-kdd.yaml" && pass || fail
    outputOperation "Installing Calico calico.yaml..."
    kubectl apply --filename "${calicoUrl}/kubernetes-datastore/calico-networking/1.7/calico.yaml" && pass || fail

}

# Set up this node as a worker node
function configWorkerNode() {

    local distro="$(getDistro)"
    local thisNode="$(uname -n)"

    outputToLog "Configuring node ${thisNode} as a worker node..."

    # Configure the firewall 
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        # firewall-cmd uses a dash for ranges
        local workerNodePorts=("10250" "30000-32767")
        for workerNodePort in "${workerNodePorts[@]}"; do
            outputOperation "Opening port(s) ${workerNodePort}..."
            firewall-cmd "--add-port=${workerNodePort}/tcp" --permanent && pass || warn
        done
        outputOperation "Reloading firewall rules..."
        firewall-cmd --reload && pass || warn
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        # ufw uses a colon for ranges
        local workerNodePorts=("10250" "30000:32767")
        for workerNodePort in "${workerNodePorts[@]}"; do
            outputOperation "Opening port(s) ${workerNodePort}..."
            ufw allow "${workerNodePort}/tcp" && pass || warn
        done
        outputOperation "Reloading firewall rules..."
        ufw reload && pass || warn
    fi

    # Copy admin.conf from master so kubectl can be used
    outputToTerminal ""
    outputToTerminal "Access to the master node is required to copy setup scripts. Prompting for credentials..."
    read -p "Master node: " masterNode 2>&101
    read -p "User account on master node: " user 2>&101
    if [[ -n "${masterNode}" && -n "${user}" ]]; then
        scp "${user}@${masterNode}:{${k8sConfigFile},${joinClusterScript}}" "/etc/kubernetes/" || 
            outputToTerminal "Failed to log into master node. Unable to copy admin.conf"
    else
        outputToLog "WARNING: Master node credentials not provided. Unable to copy setup scripts"
    fi

}

# Report status
function term() {
    
    local thisNode="$(uname -n)"

    if [[ "${isMasterNode}" == "true" ]]; then
        outputToTerminal ""
        if [[ "${warnings}" == "false" ]]; then
            outputToTerminal "Kubernetes cluster successfully initialized on ${thisNode}!"
        else
            outputToTerminal "Kubernetes cluster initialized with warnings on ${thisNode}. Review ${logFile} for additional details."
        fi
        outputToTerminal "Use the command that follows to join other nodes to the cluster."
        outputToTerminal "Note: The token expires in 24 hours. To generate a new one, run 'kubeadm token create' on master node ${thisNode}."
        outputToTerminal ""
        local joinCommand="$(grep "kubeadm join" "${logFile}" | awk '{$1=$1};1' | tr -d '\n')"
        joinCommand+=" --ignore-preflight-errors=all"
        # Write the command to a file that can be copied
        printf "${joinCommand}" >"${joinClusterScript}" && chmod u+x "${joinClusterScript}"
        outputToTerminal "${joinCommand}" 
    else
        outputToTerminal ""
        if [[ "${warnings}" == "false" ]]; then
            outputToTerminal "Kubernetes worker node successfully initialized on ${thisNode}!"
        else
            outputToTerminal "Kubernetes worker node ${thisNode} initialized with warnings. Review ${logFile} for additional details."
        fi
        outputToTerminal "Enter the 'kubeadmn join' command to add this node to your cluster."
        outputToTerminal "If it has been less than 24 hours since you initialized the cluster, you can run ${joinClusterScript}."
        outputToTerminal "Otherwise, you will need to generate a new token on the master node using the 'kubeadm token create' command."
    fi

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
    configAutoStart
    if [[ "${isMasterNode}" == "true" ]]; then
        configMasterNode
    else
        configWorkerNode
    fi
    term
fi 
