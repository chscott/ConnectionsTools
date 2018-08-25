#!/bin/bash

function init() {

    # Set up the log file
    logFile="/var/log/installKubernetes.log"
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
    isMasterNode="false"
    k8sConfigFile="/etc/kubernetes/admin.conf"

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
            --master-node)
                isMasterNode="true"
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

    printToConsole "Usage: installKubernetes.sh [OPTIONS]"
    printToConsole ""
    printToConsole "Options:"
    printToConsole ""
    printToConsole "--check"
    printToConsole ""
    printToConsole "Checks the system to see if meets the requirement to install Component Pack components."
    printToConsole ""
    printToConsole "--master-node"
    printToConsole ""
    printToConsole "Designate this as the master node for the Kubernetes cluster."

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

    printToConsole "Checking to ensure system has all prerequisites in place to install Kubernetes..."

    # Check the platform requirements
    printToLog "Checking to see if platform meets requirements to install Component Pack..."
    if [[ "$(isCPSupportedPlatform)" == "false" ]]; then 
        exitWithError "This platform does not meet the requirements to install Component Pack"
    fi
    
    # Verify Docker is installed at the required level
    printToLog "Checking to see if Docker ${CP_DOCKER_SUPPORTED_RELEASE} is installed..."
    if [[ ! "$(getDockerCEVersion)" == "${CP_DOCKER_SUPPORTED_RELEASE}" ]]; then 
        exitWithError "Docker ${CP_DOCKER_SUPPORTED_RELEASE} must be installed before installing Kubernetes"
    fi
        
    # See if Kubernetes is already installed
    printToLog "Checking to see if Kubernetes components are already installed..."
    if [[ "$(isK8sComponentInstalled "kubeadm")" == "true" || 
          "$(isK8sComponentInstalled "kubectl")" == "true" ||
          "$(isK8sComponentInstalled "kubelet")" == "true" ]]; then 
        exitWithError "One or more Kubernetes components is already installed. Uninstall Kubernetes before trying to reinstall"
    fi

}

# Do the install
function install() {

    local distro="$(getDistro)"
    local version=""

    printToConsole "Installing Kubernetes..."

    # Disable SELinux if enabled
    printToLog "Disabling SELinux..."
    if [[ "$(commandExists "setenforce")" == "true" ]]; then
        setenforce 0
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
        printToLog "Adding kubernetes repo..."
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

        # Update the yum package index
        printToLog "Updating package index..."
        "${mgr}" -y makecache fast || exitWithError "Failed to update the yum package index"

        version="$("${mgr}" list "kubeadm" --showduplicates | \
            grep "${CP_K8S_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk '{print $2}')" 

        # Install Kubernetes
        printToLog "Performing Kubernetes install..."
        "${mgr}" -y install "kubelet-${version}" "kubeadm-${version}" "kubectl-${version}" || exitWithError "Failed to install Kubernetes"

        # Lock the Kubernetes packages
        printToLog "Locking the kubeadm, kubectl and kubelet packages to prevent auto-update..."
        "${mgr}" -y versionlock "kubeadm" "kubectl" "kubelet"

        # Update /etc/sysctl.d/k8s.conf

    # Debian/Ubuntu
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then

        # Install prereqs
        printToLog "Installing prerequisite packages..."
        apt-get -y install "apt-transport-https" "ca-certificates" "curl" "gnupg2" "software-properties-common" ||
            exitWithError "Failed to install prerequisite packages" 

        # Add Kubernetes GPG key
        printToLog "Adding Kubernetes GPG key to apt..."
        curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | apt-key add - || exitWithError "Failed to add Kubernetes GPG key"

        # Add Kubernetes repo
        printToLog "Adding Kubernetes repo..."
        add-apt-repository "deb [arch=amd64] http://apt.kubernetes.io kubernetes-xenial main" || exitWithError "Failed to add Kubernetes repo"

        # Update the apt package index
        printToLog "Updating package index..."
        apt-get -y update || exitWithError "Failed to update the apt package index"

        # Get the latest version of Kubernetes target
        printToLog "Getting the latest version of Kubernetes target installation version ${CP_K8S_SUPPORTED_RELEASE}..."
        version="$(apt-cache madison "kubeadm" | \
            grep "${CP_K8S_SUPPORTED_RELEASE}" | \
            sort -r | \
            head -1 | \
            awk -F '\\| ' '{print $2}' | \
            tr -d ' ')" 
        printToLog "Latest version available: ${version}"

        # Install Kubernetes
        printToLog "Performing Kubernetes install..."
        apt-get -y install "kubeadm=${version}" "kubectl=${version}" "kubelet=${version}" || exitWithError "Failed to install Kubernetes"

        # Lock the Kubernetes packages
        printToLog "Locking the kubeadm, kubectl and kubelet packages to prevent auto-update..."
        apt-mark hold "kubeadm" "kubectl" "kubelet"

    fi

    printToConsole "Kubernetes successfully installed"

}

# Configure systemd to automatically start kubelet
function configAutoStart() {

    if [[ "$(commandExists "systemctl")" == "true" ]]; then
        printToLog "Enabling auto-start for kubelet..."
        systemctl enable "kubelet" || printToConsole "WARNING: Failed to enable kubelet for auto-start. Manual configuration required"
        printToConsole "Starting kubelet..."
        systemctl start "kubelet" || printToConsole "WARNING: Failed to start kubelet. Manual start required"
    else
        printToConsole "WARNING: Unable to configure auto-start for kubelet because systemctl command was not found" 
    fi

}

# Set up this node as the master node
function configMasterNode() {

    local distro="$(getDistro)"
    local thisNode="$(uname -n)"

    printToConsole "Configuring node ${thisNode} as the master node..." 

    # Configure the firewall
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        if [[ "$(commandExists "firewall-cmd")" == "true" ]]; then
            # firewall-cmd uses a dash for ranges
            local masterNodePorts=("6443" "2379-2380" "10250-10252")
            for masterNodePort in "${masterNodePorts[@]}"; do
                printToLog "Opening port(s) ${masterNodePort}..."
                firewall-cmd "--add-port=${masterNodePort}/tcp" --permanent || 
                    printToConsole "WARNING! Unable to open firewall port ${masterNodePort}. Manual configuration required"             
            done
            # Reload the rules
            firewall-cmd --reload
        else
            printToConsole "WARNING: Unable to configure firewall because firewall-cmd command was not found"
        fi
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if [[ "$(commandExists "ufw")" == "true" ]]; then
            # ufw uses a colon for ranges
            local masterNodePorts=("6443" "2379:2380" "10250:10252")
            for masterNodePort in "${masterNodePorts[@]}"; do
                printToLog "Opening port(s) ${masterNodePort}..."
                ufw allow "${masterNodePort}/tcp"
                    printToConsole "WARNING! Unable to open firewall port ${masterNodePort}. Manual configuration required"             
            done
            # Reload the rules
            ufw reload
        else
            printToConsole "WARNING: Unable to configure firewall because ufw command was not found"
        fi
    fi

    # Initialize the cluster
    if [[ "$(commandExists "kubeadm")" == "true" ]]; then
        printToConsole "Initializing cluster. This make take several minutes..."
        kubeadm init --pod-network-cidr="192.168.0.0/16" || exitWithError "Failed to initialize cluster"
    else
        exitWithError "Unable to initialize cluster because kubeadm command was not found" 
    fi

    # Install pod network add-on
    if [[ "$(commandExists "kubectl")" == "true" ]]; then
        local calicoUrl="https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted"
        printToLog "Installing pod network add-on..."
        kubectl apply --filename "${calicoUrl}/rbac-kdd.yaml" || exitWithError "Unable to install pod networking"
        kubectl apply --filename "${calicoUrl}/kubernetes-datastore/calico-networking/1.7/calico.yaml" || 
            exitWithError "Unable to install pod networking"
    else
        exitWithError "Unable to install pod networking because kubectl command was not found" 
    fi

    printToConsole "Kubernetes cluster successfully initialized on ${thisNode}. Use the command that follows to join other nodes to the cluster."
    printToConsole "Note: The token expires in 24 hours. To generate a new one, run 'kubeadm token create' on master node ${thisNode}."
    printToConsole ""
    local joinCommand="$(grep "kubeadm join" "${logFile}" | tr -d '\n')"
    joinCommand+=" --ignore-preflight-errors=all"
    printToConsole "${joinCommand}" 

}

# Set up this node as a worker node
function configWorkerNode() {

    local distro="$(getDistro)"
    local thisNode="$(uname -n)"

    printToConsole "Configuring node ${thisNode} as a worker node..."

    # Configure the firewall 
    if [[ "${distro}" == "centos" || "${distro}" == "rhel" || "${distro}" == "fedora" ]]; then
        if [[ "$(commandExists "firewall-cmd")" == "true" ]]; then
            # firewall-cmd uses a dash for ranges
            local workerNodePorts=("10250" "30000-32767")
            for workerNodePort in "${workerNodePorts[@]}"; do
                printToLog "Opening port(s) ${workerNodePort}..."
                firewall-cmd "--add-port=${workerNodePort}/tcp" --permanent || 
                    printToConsole "WARNING! Unable to open firewall port ${workerNodePort}. Manual configuration required"             
            done
            # Reload the rules
            firewall-cmd --reload
        else
            printToConsole "WARNING: Unable to configure firewall because firewall-cmd command was not found"
        fi
    elif [[ "${distro}" == "debian" || "${distro}" == "ubuntu" ]]; then
        if [[ "$(commandExists "ufw")" == "true" ]]; then
            # ufw uses a colon for ranges
            local workerNodePorts=("10250" "30000:32767")
            for workerNodePort in "${workerNodePorts[@]}"; do
                printToLog "Opening port(s) ${workerNodePort}..."
                ufw allow "${workerNodePort}/tcp"
                    printToConsole "WARNING! Unable to open firewall port ${workerNodePort}. Manual configuration required"             
            done
            # Reload the rules
            ufw reload
        else
            printToConsole "WARNING: Unable to configure firewall because ufw command was not found"
        fi
    fi

    # Copy admin.conf from master so kubectl can be used
    if [[ "$(commandExists "scp")" == "true" ]]; then
        printToConsole "Attempting to copy admin.conf from the master node so kubectl commands can run on this node..."
        read -p "Master node: " masterNode 2>&101
        read -p "User account on master node: " user 2>&101
        if [[ -n "${masterNode}" && -n "${user}" ]]; then
            scp "${user}@${masterNode}:${k8sConfigFile}" "${k8sConfigFile}" ||
                printToConsole "WARNING: Unable to copy admin.conf from master node. Unable to run kubectl commands on this node."
        fi
            
    else
        printToConsole "WARNING: Unable to copy admin.conf from master node. Unable to run kubectl commands on this node."
    fi

    printToConsole "Kubernetes worker node successfully initialized on ${thisNode}. Enter the 'kubeadmn join' command to add this node to your cluster."
    printToConsole "The exact command to run can be found in ${logFile} on the master node. Make sure to run it as root."

}

init "${@}"

if [[ "${checkRequirements}" == "true" ]]; then
    # Just check requirements
    checkForRequirements
else
    # Do the install
    checkForPrereqs
    install
    configAutoStart
    if [[ "${isMasterNode}" == "true" ]]; then
        configMasterNode
    else
        configWorkerNode
    fi
fi 
