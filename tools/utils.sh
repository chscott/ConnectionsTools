#!/bin/bash
# utils.sh

# Source prereqs
. /etc/ictools.conf

# This is used to give us a file descriptor to print to normal stdout since we'll be redirecting fd 1 to the script log
#fd101=$(${ls} /proc/${BASHPID}/fd | ${grep} 101)
#if [ -z ${fd101} ]; then
#    exec 101>&1
#fi

# Reset the file descriptors for normal output
#function resetOutput() {
#    exec 1>&101 2>&1
#}

# Redirect the file descriptors for script output
#function redirectOutput() {
#    exec 1>>${scriptLog} 2>&1
#    # This is needed to give process substition a chance to complete before main shell continues
#    sleep 1
#}

# Tests to make sure the effective user ID is root
function checkForRoot() {

    local script=$(basename ${0})
	if [[ "${EUID}" != 0 ]]; then
		log "${script} needs to run as root. Exiting."
		exit 1
	fi

}

# Print message to stderr with date/time prefix
# $1: message to print
function log() {

    local message=${1}
	printf '%s\n' "${message}"

}

# Given a profileKey.metadata file, return the profile type
function getWasProfileType() {

    local profileKeyFile="${1}"
    local profileType=""

    profileType=$(grep "com.ibm.ws.profile.type" "${profileKeyFile}" | awk -F '=' '{print $2}')  
    
    if [[ ${?} == 0 ]]; then
        echo "${profileType}"
    else
        echo "INVALID"
    fi

}

# Prints the status of the specified WAS server
# $1: server to check
# $2: profile root
# $3: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getWASServerStatus() {

    local server="${1}"
    local profile="${2}"
    local noDisplay="${3}"

    # Only print info if noDisplay is not true
    if [[ "${noDisplay}" != "true" ]]; then
        printf "%-20.20s" "Server: ${server} "
        printf "%-40.40s" "Profile: $(basename ${profile})"
    fi

    # This approach is much faster than using serverStatus.sh and unlikely to yield false positives
    ps -ef | grep -v "grep" | grep "${profile}" | awk '{print $NF}' | grep "${server}" >/dev/null 2>&1

    # If grep found a match, the server is started
    if [[ ${?} == 0 ]]; then
        if [[ "${noDisplay}" == "true" ]]; then
            # Return status via subshell
            echo "STARTED"
        else
            # Return status via display
            printf " %-7s\n" "${greenText}STARTED${normalText}"
        fi
    else 
        if [[ "${noDisplay}" == "true" ]]; then
            # Return status via subshell
            echo "STOPPED"
        else
            # Return status via display
            printf " %-7s\n" "${redText}STOPPED${normalText}"
        fi
    fi

}

# Prints the status of the IHS server
function getIHSServerStatus() {

    printf "%-60.60s" "Server: IHS"

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z ${ihsInstallDir} || ! -d ${ihsInstallDir} ]]; then
        exit 0
    fi

    # See if the server is running
    ps -ef | grep ${ihsInstallDir}/bin/httpd | grep -v 'grep' >/dev/null 2>&1

    # If grep found a match, the server is started
    if [[ ${?} == 0 ]]; then
        printf " %-7s\n" "${greenText}STARTED${normalText}"
    else 
        printf " %-7s\n" "${redText}STOPPED${normalText}"
    fi

}

# Prints the status of the Solr server
function getSolrServerStatus() {

    printf "%-60.60s" "Server: Solr"

    # If no Solr installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z ${solrInstallDir} || ! -d ${solrInstallDir} ]]; then
        exit 0
    fi

    # See if the server is running
    ps -ef | grep 'solr/quick-results-collection' | grep -v 'grep' >/dev/null 2>&1

    # If grep found a match, the server is started
    if [[ ${?} == 0 ]]; then
        printf " %-7s\n" "${greenText}STARTED${normalText}"
    else 
        printf " %-7s\n" "${redText}STOPPED${normalText}"
    fi

}

# Start the specified WAS server
# $1: server
# $2: profile path
function startWASServer() {

    local server="${1}"
    local profile="${2}"
    local started="false"

    printf "%-60.60s" "Starting server ${server} in profile $(basename ${profile})..."

    # Get the result of the startServer.sh command
    local status=$("${profile}/bin/startServer.sh" "${server}")

    # Check to see if server is started
    echo "${status}" | grep -E "ADMU3027E|ADMU3000I" >/dev/null 2>&1
    if [[ ${?} == 0 ]]; then
        printf " %-7s\n" "${greenText}STARTED${normalText}"
        started="true"
    fi
    
    if [[ "${started}" == "false" ]]; then
        printf " %-7s\n" "${redText}FAILED${normalText}"
    fi 

}

# Start IHS server
function startIHSServer() {

    local serverStatus

    printf "%-60.60s" "Starting IHS server..."

    # Start the server
    ${ihsInstallDir}/bin/apachectl -k start >/dev/null 2>&1
    
    # Check to see if server is stopped
    if [[ ${?} == 0 ]]; then
        printf " %-7s\n" "${greenText}STARTED${normalText}"
    else
        printf " %-7s\n" "${redText}FAILED${normalText}"
    fi 

}

# Start Solr server
function startSolrServer() {

    printf "%-60.60s" "Starting Solr server..."

    # See if Java is installed
    local java=$(which java)
    if [[ ${?} != 0 ]]; then
        printf " %-7s %s\n" "${redText}FAILED${normalText}" "(Could not find Java)"
        exit 1
    fi

    cd "${solrInstallDir}/node1"

    # Start Solr
    nohup ${java} \
        -jar "${solrInstallDir}/node1/start.jar" \
        "-DSTOP.PORT=${solrPort}" \
        "-DSTOP.KEY=${solrKey}" \
        "-Djetty.ssl.clientAuth=true" \
        "-Dhost=$(hostname --fqdn)" \
        "-Dcollection.configName=myConf" \
        "-DzkRun" \
        "-DnumShards=1" \
        "-Dbootstrap_confdir=${solrInstallDir}/node1/solr/quick-results-collection/conf" \
        >/dev/null 2>&1 &

    # Wait a few seconds for the server to start
    sleep ${serviceDelaySeconds} 

    # See if the server is started
    ps -ef | grep "solr/quick-results-collection" | grep -v "grep" >/dev/null 2>&1
    if [[ ${?} == 1 ]]; then
        # Failure to grep Solr is failure in a start scenario
        printf " %-7s\n" "${redText}FAILED${normalText}"
    else
        printf " %-7s\n" "${greenText}STARTED${normalText}"
    fi 

}

# Stop the specified WAS server
# $1: server
# $2: profile path
function stopWASServer() {

    local server="${1}"
    local profile="${2}"
    local stopped="false"

    printf "%-60.60s" "Stopping server ${server} in profile $(basename ${profile})..."

    # Get the result of the stopServer.sh command
    local status=$("${profile}/bin/stopServer.sh" "${server}" -username "${wasAdmin}" -password "${wasAdminPwd}")

    # Check to see if server is stopped
    echo "${status}" | grep -E "ADMU0509I|ADMU4000I" >/dev/null 2>&1
    if [[ ${?} == 0 ]]; then
        printf " %-7s\n" "${greenText}STOPPED${normalText}"
        stopped="true"
    fi
    
    if [[ "${stopped}" == "false" ]]; then
        printf " %-7s\n" "${redText}FAILED${normalText}"
    fi 

}

# Stop IHS server
function stopIHSServer() {

    local serverStatus

    printf "%-60.60s" "Stopping IHS server..."

    # Stop the server
    ${ihsInstallDir}/bin/apachectl -k stop >/dev/null 2>&1
    
    # Wait a few seconds for process termination 
    sleep ${serviceDelaySeconds} 

    # Kill any remaining processes
    ps -ef | grep ${ihsInstallDir}/bin | grep -v 'grep' | awk '{print $2}' | xargs -r kill -9 >/dev/null 2>&1

    # Check to see if server is stopped
    if [[ ${?} == 0 ]]; then
        printf " %-7s\n" "${greenText}STOPPED${normalText}"
    else
        printf " %-7s\n" "${redText}FAILED${normalText}"
    fi 

}

# Stop Solr server
function stopSolrServer() {

    printf "%-60.60s" "Stopping Solr server..."

    # See if Java is installed
    local java=$(which java)
    if [[ ${?} != 0 ]]; then
        printf " %-7s %s\n" "${redText}FAILED${normalText}" "(Could not find Java)"
        exit 1
    fi

    # Stop Solr
    ${java} -jar ${solrInstallDir}/node1/start.jar -DSTOP.PORT=${solrPort} -DSTOP.KEY=${solrKey} --stop >/dev/null 2>&1

    # Wait a few seconds for the server to stop
    sleep ${serviceDelaySeconds} 

    # See if the server is stopped
    ps -ef | grep 'solr/quick-results-collection' | grep -v 'grep' >/dev/null 2>&1
    if [[ ${?} == 1 ]]; then
        # Failure to grep Solr is success in a stop scenario
        printf " %-7s\n" "${greenText}STOPPED${normalText}"
    else
        printf " %-7s\n" "${redText}FAILED${normalText}"
    fi 

}

# Check to see if Deployment Manager is available
function isDmgrAvailable() {

    local status=$(nmap ${wasDmgrHost} -p ${wasDmgrSoapPort})
    echo ${status} | grep 'open' >/dev/null 2>&1

    if [[ ${?} == 0 ]]; then
        echo 0
    else
        echo 1
    fi

}
