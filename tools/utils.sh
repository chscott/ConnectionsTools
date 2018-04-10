#!/bin/bash
# utils.sh

# Source prereqs
. "/etc/ictools.conf"

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

    local script="$(basename "${0}")"

	if [[ ${EUID} != 0 ]]; then
		log "${script} needs to run as root. Exiting."
		exit 1
	fi

}

# Tests to make sure the WAS Deployment Manager is available on this system
function checkForDmgr() {

    local script="$(basename "${0}")"

    if [[ ! -d "${wasDmgrProfile}" ]]; then
        log "${script} can only run on the Deployment Manager node. Exiting."
        exit 1
    fi

}

# Tests to make sure Connections is installed on this system
function checkForIC() {

    local script="$(basename "${0}")"

    if [[ ! -d "${icInstallDir}" ]]; then
        log "${script} can only run on Connections nodes. Exiting."
        exit 1
    fi

}

# Tests to make sure TDI is installed on this system
function checkForTDI() {

    local script="$(basename "${0}")"

    if [[ ! -d "${tdiSolutionDir}" ]]; then
        log "${script} can only run on TDI nodes. Exiting."
        exit 1
    fi

}

# Tests to make sure Kubernetes is available on this system
function checkForK8s() {

    local script="$(basename "${0}")"

    if [[ ! -x "${kubectl}" ]]; then
        log "${script} can only run on Component Pack nodes. Exiting."
        exit 1
    fi

}

# Print message
# $1: message to print
function log() {

    local message="${1}"

	printf "%s\n" "${message}"

}

# Given a profileKey.metadata file, return the profile type
function getWasProfileType() {

    local profileKeyFile="${1}"
    local profileType=""

    profileType="$(grep "com.ibm.ws.profile.type" "${profileKeyFile}" | awk -F "=" '{print $2}')"
    
    if [[ ${?} == 0 ]]; then
        echo "${profileType}"
    else
        echo "INVALID"
    fi

}

# Check to see if Deployment Manager is available
function isDmgrAvailable() {

    local status="$(nmap "${wasDmgrHost}" -p ${wasDmgrSoapPort})"

    if [[ "${status}" =~ "open" ]]; then
        echo 0
    else
        echo 1
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
        printf "${left3Column}" "Server: ${server} "
        printf "${middle3Column}" "Profile: $(basename ${profile})"
    fi

    # This approach is much faster than using serverStatus.sh and unlikely to yield false positives
    ps -ef | grep -v "grep" | grep "${profile}" | awk '{print $NF}' | grep "${server}" >/dev/null 2>&1

    if [[ ${?} == 0 ]]; then
        # If we found a match, the server is started
        if [[ "${noDisplay}" == "true" ]]; then
            # Return status via subshell
            echo "STARTED"
        else
            # Return status via display
            printf "${right3Column}" "${greenText}STARTED${normalText}"
        fi
    else 
        # If we did not find a match, the server is stopped
        if [[ "${noDisplay}" == "true" ]]; then
            # Return status via subshell
            echo "STOPPED"
        else
            # Return status via display
            printf "${right3Column}" "${redText}STOPPED${normalText}"
        fi
    fi

}

# Start the specified WAS server
# $1: server
# $2: profile path
function startWASServer() {

    local server="${1}"
    local profile="${2}"

    printf "${left2Column}" "Starting server ${server} in profile $(basename "${profile}")..."

    # Get the result of the startServer.sh command
    local status="$("${profile}/bin/startServer.sh" "${server}")"

    # Check to see if server is started
    if [[ "${status}" =~ "ADMU3027E" || "${status}" =~ "ADMU3000I" ]]; then
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    else
        printf "${right2Column}" "${redText}FAILURE${normalText}"
    fi

}

# Stop the specified WAS server
# $1: server
# $2: profile path
function stopWASServer() {

    local server="${1}"
    local profile="${2}"

    printf "${left2Column}" "Stopping server ${server} in profile $(basename "${profile}")..."

    # Get the result of the stopServer.sh command
    local status="$("${profile}/bin/stopServer.sh" "${server}" -username "${wasAdmin}" -password "${wasAdminPwd}")"

    # Check to see if server is stopped
    if [[ "${status}" =~ "ADMU0509I" || "${status}" =~ "ADMU4000I" ]]; then
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    else
        printf "${right2Column}" "${redText}FAILURE${normalText}"
    fi

}

# Prints the status of the IHS server
function getIHSServerStatus() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        return
    fi

    printf "${left2Column}" "Server: IHS"

    # See if the server is running
    ps -ef | grep "${ihsInstallDir}/bin/httpd" | grep -v "grep" >/dev/null 2>&1

    if [[ ${?} == 0 ]]; then
        # If we found a match, the server is started
        printf "${right2Column}" "${greenText}STARTED${normalText}"
    else 
        # If we did not find a match, the server is stopped
        printf "${right2Column}" "${redText}STOPPED${normalText}"
    fi

}

# Start IHS server
function startIHSServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Starting IHS server..."

    # Start the server
    "${ihsInstallDir}/bin/apachectl" -k "start" >/dev/null 2>&1
    
    # Check to see if server is started
    if [[ ${?} == 0 ]]; then
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    else
        printf "${right2Column}" "${redText}FAILURE${normalText}"
    fi 

}

# Stop IHS server
function stopIHSServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${ihsInstallDir}" || ! -d "${ihsInstallDir}" ]]; then
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Stopping IHS server..."

    # Stop the server
    "${ihsInstallDir}/bin/apachectl" -k "stop" >/dev/null 2>&1
    
    # Wait a few seconds for process termination 
    sleep ${serviceDelaySeconds} 

    # Kill any remaining processes
    ps -ef | grep "${ihsInstallDir}/bin" | grep -v "grep" | awk '{print $2}' | xargs -r kill -9 >/dev/null 2>&1

    # Check to see if server is stopped
    if [[ ${?} == 0 ]]; then
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    else
        printf "${right2Column}" "${redText}FAILURE${normalText}"
    fi 

}

# Prints the status of the Solr server
function getSolrServerStatus() {

    # If no Solr installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${solrInstallDir}" || ! -d "${solrInstallDir}" ]]; then
        return
    fi

    printf "${left2Column}" "Server: Solr"

    # See if the server is running
    ps -ef | grep "solr/quick-results-collection" | grep -v "grep" >/dev/null 2>&1

    if [[ ${?} == 0 ]]; then
        # If we found a match, the server is started
        printf "${right2Column}" "${greenText}STARTED${normalText}"
    else 
        # If we did not find a match, the server is stopped
        printf "${right2Column}" "${redText}STOPPED${normalText}"
    fi

}

# Start Solr server
function startSolrServer() {

    # If no Solr installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${solrInstallDir}" || ! -d "${solrInstallDir}" ]]; then
        log "Solr does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Starting Solr server..."

    # See if Java is installed
    local java="$(which java)"
    if [[ ${?} != 0 ]]; then
        printf "${right2Column}" "${redText}FAILURE${normalText}" "(Could not find Java)"
        exit 1
    fi

    cd "${solrInstallDir}/node1"

    # Start Solr
    nohup "${java}" \
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
        printf "${right2Column}" "${redText}FAILURE${normalText}"
    else
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    fi 

}

# Stop Solr server
function stopSolrServer() {

    # If no Solr installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${solrInstallDir}" || ! -d "${solrInstallDir}" ]]; then
        log "Solr does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Stopping Solr server..."

    # See if Java is installed
    local java="$(which java)"
    if [[ ${?} != 0 ]]; then
        printf "${right2Column}" "${redText}FAILURE${normalText}" "(Could not find Java)"
        exit 1
    fi

    # Stop Solr
    "${java}" \
        -jar "${solrInstallDir}/node1/start.jar" \
        "-DSTOP.PORT=${solrPort}" \
        "-DSTOP.KEY=${solrKey}" \
        "--stop" \
        >/dev/null 2>&1

    # Wait a few seconds for the server to stop
    sleep ${serviceDelaySeconds} 

    # See if the server is stopped
    ps -ef | grep "solr/quick-results-collection" | grep -v "grep" >/dev/null 2>&1
    if [[ ${?} == 1 ]]; then
        # Failure to grep Solr is success in a stop scenario
        printf "${right2Column}" "${greenText}SUCCESS${normalText}"
    else
        printf "${right2Column}" "${redText}FAILURE${normalText}"
    fi 

}

# Prints the status of the DB2 server
function getDB2ServerStatus() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${db2InstallDir}" || ! -d "${db2InstallDir}" ]]; then
        return
    fi

    printf "${left2Column}" "Server: DB2"

    # See if the server is running
    ps -ef | grep "db2sysc" | grep -v "grep" >/dev/null 2>&1

    if [[ ${?} == 0 ]]; then
        # If we found a match, the server is started
        printf "${right2Column}" "${greenText}STARTED${normalText}"
    else 
        # If we did not find a match, the server is stopped
        printf "${right2Column}" "${redText}STOPPED${normalText}"
    fi

}

# Start DB2 
function startDB2Server() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${db2InstallDir}" || ! -d "${db2InstallDir}" ]]; then
        log "DB2 does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Starting DB2..."

    result=$(sudo -i -u "${db2InstanceUser}" "db2start")

    if [[ "${result}" =~ "SQL1063N" || "${result}" =~ "SQL1026N" ]]; then
        printf "${right2Column}" "${greenText}SUCCESS${normalText}" 
    else
        printf "${right2Column}" "${redText}FAILURE${normalText}" 
    fi

}

# Stop DB2
function stopDB2Server() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if [[ -z "${db2InstallDir}" || ! -d "${db2InstallDir}" ]]; then
        log "DB2 does not appear to be installed on this system. Exiting."
        exit 0
    fi

    printf "${left2Column}" "Stopping DB2..."

    result=$(sudo -i -u "${db2InstanceUser}" "db2stop")

    if [[ "${result}" =~ "SQL1064N" || "${result}" =~ "SQL1032N" ]]; then
        printf "${right2Column}" "${greenText}STOPPED${normalText}" 
    else
        printf "${right2Column}" "${redText}FAILED${normalText}" 
    fi

}
