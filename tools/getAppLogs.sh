#!/bin/bash
# getAppLogs.sh: User-friendly front end for logViewer

# Source prereqs
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "/etc/ictools.conf"
. "${scriptDir}/utils.sh"

function usage() {

    log "Usage: getAppLogs.sh --profile PROFILE [--app APP] [--duration DURATION]"
    log ""
    log "(Required) PROFILE is the name of a WebSphere profile"
    log "(Optional) APP is any valid WebSphere application name"
    log "(Optional) DURATION is an integer representing minutes of logging to retrieve or the special values 'today', 'lastHour' or 'monitor'"
    log ""
    log "Examples:"
    log ""
    log "Get all logs (equivalent to generating a full SystemOut.log or trace.log):"
    log "$ sudo getAppLogs.sh --profile profile1"
    log ""
    log "Get all logs from today (i.e. since 12:00 AM):"
    log "$ sudo getAppLogs.sh --profile profile1 --duration today"
    log ""
    log "Get logs for the News app from the last hour:"
    log "$ sudo getAppLogs.sh --profile profile1 --app News --duration lastHour"
    log ""
    log "Get logs for the News app from the last 5 minutes:"
    log "$ sudo getAppLogs.sh --profile profile1 --app News --duration 5"
    log ""
    log "Monitor logs for the News app:"
    log "$ sudo getAppLogs.sh --profile profile1 --app News --duration monitor"

}

function init() {

    # Make sure we're running as root
    checkForRoot

    # Verify ictools.conf data is available
    if [[ -z "${wasProfileRoot}" || -z "${wasCellName}" ]]; then
        log "The wasProfileRoot and wasCellName variables must be set in /etc/ictools.conf"
        exit 1
    fi 

    # Process the user arguments
    while [[ ${#} -gt 0 ]]; do
        key="${1}"
        case "${key}" in
            --profile)
                profile="${2}"
                shift;shift;;
            --app)
                app="${2}"
                shift;shift;;
            --duration)
                duration="${2}"
                shift;shift;;
            *)
                log "Unrecognized argument ${1}"
                shift;;
        esac
    done

    # Verify we have a profile
    if [[ -z "${profile}" ]]; then
        usage
        exit 1
    fi

    # Verify that the profile directory exists
    if [[ ! -d "${wasProfileRoot}/${profile}" ]]; then
        log "The specified profile ${profile} does not exist on this system. Exiting."
        exit 1
    fi 

    # Verify that HPEL logging is configured
    hpelFiles=$(find "${wasProfileRoot}/${profile}" -name "hpelRepository.owner" | wc -l)
    if [[ ${hpelFiles} == 0 ]]; then
        log "HPEL logging is not enabled for this profile. Exiting."
        exit 1
    fi

    # If no app was specified, get all logs
    getAllApps="false"
    if [ -z "${app}" ]; then
        getAllApps="true" 
        app="All"
    fi

    # Script variables
    logViewer="${wasProfileRoot}/${profile}/bin/logViewer.sh"
    logFile="${wasProfileRoot}/${profile}/logs/${app}.log"
    timeFormat="+%m/%d/%y %H:%M:%S:%3N %Z"

}

init "${@}"

# No time length provided so get everything 
if [ -z "${duration}" ]; then
    if [ "${getAllApps}" = "true" ]; then
        log "Getting all log messages for all applications..."
        "${logViewer}" "-outLog" "${logFile}"
    else
        log "Getting all log messages for the ${app} application..."
        "${logViewer}" "-includeExtensions" "appName=${app}" "-outLog" "${logFile}"
    fi

# Special time length value 'today' so get everything since midnight
elif [ "${duration}" = "today" ]; then
    midnight="$(date +%m/%d/%y)" 
    if [ "${getAllApps}" = "true" ]; then
        log "Getting all log messages on ${midnight} for all applications..."
        "${logViewer}" "-startDate" "${midnight}" "-outLog" "${logFile}"
    else
        log "Getting all log messages on ${midnight} for the ${app} application..." 
        "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${midnight}" "-outLog" "${logFile}"
    fi

# Special time length value 'lastHour' so get everything for last 60 minutes
elif [ "${duration}" = "lastHour" ]; then
    oneHourAgo="$(date -d "1 hour ago" "${timeFormat}")"
    if [ "${getAllApps}" = "true" ]; then
        log "Getting all log messages since ${oneHourAgo} for all applications..."
        "${logViewer}" "-startDate" "${oneHourAgo}" "-outLog" "${logFile}"
    else
        log "Getting all log messages since ${oneHourAgo} for the ${app} application..."
        "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${oneHourAgo}" "-outLog" "${logFile}"
    fi

# Special time length value 'monitor' so tail the logs
elif [ "${duration}" = "monitor" ]; then
    if [ "${getAllApps}" = "true" ]; then
        log "Monitoring log messages for all applications (Ctrl-C to stop)..."
        "${logViewer}" "-monitor" 1
    else
        log "Monitoring log messages for the ${app} application (Ctrl-C to stop)..."
        "${logViewer}" "-monitor" 1
    fi

# Time length specified as integer so get that many minutes of logging
elif [[ "${duration}" =~ ^[0-9]+$ ]]; then
    duration="${duration} minutes ago"
    nMinutesAgo="$(date -d "${duration}" "${timeFormat}")"
    if [ "${getAllApps}" = "true" ]; then
        log "Getting all log messages since ${nMinutesAgo} for all applications..."
        "${logViewer}" "-startDate" "${nMinutesAgo}" "-outLog" "${logFile}"
    else
        log "Getting all log messages since ${nMinutesAgo} for the ${app} application..."
        "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${nMinutesAgo}" "-outLog" "${logFile}"
    fi

# Invalid value
else
    log "Time duration must be an integer"
    exit 1
fi
