#! /bin/bash

# Verify the script has the prereqs needed to run
function init() {
    
    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # etcd port
    ETCD_PORT=4001

    # ICp 1.2.1 ports
    ICP_PORTS_121=(80 179 443 2380 3306 ${ETCD_PORT}
    4194 4444 4567 4568 5000 5044 5046 8001 8080
    8082 8084 8101 8181 8443 8500 8600 8743 8888
    9200 9235 9300 18080 35357)

    # ICp 1.2.1 K8s port ranges
    K8S_PORT_RANGES_121=(10248-10252 30000-32767)

    # ICp 2.1.0.1 ports
    ICP_PORTS_2101=(80 179 443 2222 2380 3130 3306 ${ETCD_PORT}
    4194 4242 4444 4567 4568 5044 5046 6969 8001 8080 8082
    8084 8101 8181 8443 8500 8600 8743 8888 9099 9100 9200
    9235 9300 9443 18080 24007 24008 31030 31031)

    # ICp 2.1.0.1 K8s port ranges
    K8S_PORT_RANGES_2101=(10248-10252 30000-32767 49152-49251)

    # See which version we're checking
    if [[ ! -z "${1}" && "${1}" == "--v1" ]]; then
        icpPorts=("${ICP_PORTS_121[@]}")
        k8sPortRanges=("${K8S_PORT_RANGES_121[@]}")
    elif [[ ! -z "${1}" && "${1}" == "--v2" ]]; then
        icpPorts=("${ICP_PORTS_2101[@]}")
        k8sPortRanges=("${K8S_PORT_RANGES_2101[@]}")
    else
        # Defaults to v1
        icpPorts=("${ICP_PORTS_121[@]}")
        k8sPortRanges=("${K8S_PORT_RANGES_121[@]}")
    fi

}

init "${@}"

# Array of ports in use
portsInUse=()

# Get a snapshot of netstat output
netstatOutput="$(netstat -anp)"

# Check ICp ports
for port in "${icpPorts[@]}"; do
    echo "${netstatOutput}" | awk '{print $4}' | grep -q ":${port}$"
    if [[ ${?} == 0 ]]; then
        portsInUse+=("${port}")
    fi
done

# Check K8s ports 
for portRange in "${k8sPortRanges[@]}"; do
    inUsePorts=()
    portRangeStart=$(echo ${portRange} | awk -F '-' '{print $1}')
    portRangeEnd=$(echo ${portRange} | awk -F '-' '{print $2}')
    inUsePorts=($(
        echo "${netstatOutput}" | \
        grep "^tcp.*" | \
        awk '{print $4}' | \
        awk -F ':' -v "start=${portRangeStart}" -v "end=${portRangeEnd}" '{ if ($NF >= start && $NF <= end) print $NF }' \
    ))
    for port in "${inUsePorts[@]}"; do
        portsInUse+=("${port}")
    done
done

echo "The following ports must be available but are already in use:"

# Print the unique ports
printf "%s\n" "${portsInUse[@]}" | sort -n | uniq
