#!/bin/bash
# connectToRedis.sh: Connect to the Redis microservice

# Source the prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function init() {

    checkForRoot
    checkForK8s

}

function commonCommands() {

    printf "%s\n" "${greenText}Common Redis commands:${normalText}"
    printf "\t%s\n" "${greenText}client list: List client connections${normalText}" 
    printf "\t%s\n" "${greenText}info: Print server information${normalText}" 
    printf "\t%s\n" "${greenText}keys <pattern>: List all keys matching the pattern${normalText}" 
    printf "\t%s\n" "${greenText}monitor: Stream all requests received by the server${normalText}" 
    printf "\t%s\n" "${greenText}pubsub channels: List active channels${normalText}" 
    printf "\t%s\n" "${greenText}subscribe <channel>: Stream messages published to the given channel${normalText}" 
    printf "\t%s\n" "${greenText}quit: Close the connection${normalText}" 

}

init "${@}"

# Get an array of all Mongo pods
pods=($("${scriptDir}/getPodInfo.sh" --all | grep "redis-server" | awk '{print $1}'))

# Try to connect to a pod
for pod in "${pods[@]}"; do

    log "Connecting to ${pod}..."
    commonCommands 

    "${kubectl}" exec "${pod}" --namespace "${icNamespace}" --stdin --tty -- redis-cli -a "${redisPassword}"

    # If we successfully connected to a pod, exit. Otherwise, try the next one. redis-cli returns exit code 130 on SIGINT 
    # used to stop commands like MONITOR. Check for that and consider it successful.
    rc=${?}
    if [[ ${rc} == 0 || ${rc} == 130 ]]; then
        exit 0 
    fi

done
