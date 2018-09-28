#!/bin/bash

function usage() {

    log "Usage: getAppLogs.sh --profile PROFILE [--app APP] [--duration DURATION] [--severity SEVERITY]"
    log ""
    log "(Required) PROFILE is the name of a WebSphere profile"
    log "(Optional) APP is any valid WebSphere application name"
    log "(Optional) DURATION is an integer representing minutes of logging to retrieve or the special values 'today', 'lastHour' or 'monitor'"
    log "(Optional) SEVERITY is the minimum level of logs to retrieve ('warning' or 'fatal'). Omit to retrieve all levels"
    log ""
    log "Examples:"
    log ""
    log "Get all logs (equivalent to generating a full SystemOut.log or trace.log):"
    log "$ sudo getAppLogs.sh --profile profile1"
    log ""
    log "Get all logs from today (i.e. since 12:00 AM):"
    log "$ sudo getAppLogs.sh --profile profile1 --duration today"
    log ""
    log "Get warning logs for the News app from the last hour:"
    log "$ sudo getAppLogs.sh --profile profile1 --app News --duration lastHour --severity warning"
    log ""
    log "Get logs for the News app from the last 5 minutes:"
    log "$ sudo getAppLogs.sh --profile profile1 --app News --duration 5"
    log ""
    log "Monitor logs for the News app:"
    log "$ sudo getAppLogs.sh --profile profile1 --app News --duration monitor"

}

function init() {

    # Source prereqs
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    . "/etc/ictools.conf"
    . "${scriptDir}/utils.sh"

    # Make sure we're running as root
    checkForRoot

    # Verify prereqs
    if [[ ! -d "${wasProfileRoot}" ]]; then
        log "The wasProfileRoot variable must be set in /etc/ictools.conf to point to your WAS profile root directory (e.g. /opt/IBM/WebSphere/AppServer)"
        exit 1
    fi 
    type -a date > /dev/null 2>&1
    if [[ ${?} != 0 ]]; then
        log "The date command is required to run this script"
        exit 1
    fi 

    # Process the user arguments
    while [[ ${#} -gt 0 ]]; do
        local key="${1}"
        local value="${2}"
        case "${key}" in
            --profile)
                profile="${value}"
                shift;shift;;
            --app)
                app="${value}"
                shift;shift;;
            --duration)
                duration="${value}"
                shift;shift;;
            --severity)
                severity="${value}"
                shift;shift;;
            --help)
                usage
                exit 0;;
            *)
                log "Unrecognized argument ${key}"
                usage
                exit 1
        esac
    done

    # Verify we have a profile
    if [[ -z "${profile}" ]]; then
        usage
        exit 1
    fi

    # Verify that the profile directory exists
    if [[ "$(directoryExists "${wasProfileRoot}/${profile}")" != "true" ]]; then
        log "The specified profile ${profile} does not exist on this system. Exiting."
        exit 1
    fi 

    # Verify that HPEL logging is configured
    if ! find "${wasProfileRoot}/${profile}/logs" -name "hpelRepository.owner" 2>/dev/null; then
        log "No HPEL log repository exists for this profile. Exiting."
        exit 1
    fi

    # If no app was specified, get all logs
    if [[ -z "${app}" ]]; then
        getAllApps="true" 
        app="All"
    else
        getAllApps="false"
    fi

    # If the severity level doesn't match a supported level, get all levels
    if [[ -z "${severity}" || ("${severity}" != "warning" && "${severity}" != "fatal") ]]; then
        severity="all"
    fi

    # Script variables
    logViewer="${wasProfileRoot}/${profile}/bin/logViewer.sh"
    logFile="${wasProfileRoot}/${profile}/logs/${app}.log"
    timeFormat="+%m/%d/%y %H:%M:%S:%3N %Z"

}

init "${@}"

# No time length provided so get everything 
if [[ -z "${duration}" ]]; then
    if [[ "${getAllApps}" == "true" ]]; then
        log "Getting ${severity} log messages for all applications..."
        "${logViewer}" "-minLevel" "${severity}" "-outLog" "${logFile}"
    else
        log "Getting ${severity} log messages for the ${app} application..."
        "${logViewer}" "-includeExtensions" "appName=${app}" "-minLevel" "${severity}" "-outLog" "${logFile}"
    fi

# Special time length value 'today' so get everything since midnight
elif [[ "${duration}" == "today" ]]; then
    midnight="$(date +%m/%d/%y)" 
    if [[ "${getAllApps}" == "true" ]]; then
        log "Getting ${severity} log messages on ${midnight} for all applications..."
        "${logViewer}" "-startDate" "${midnight}" "-minLevel" "${severity}" "-outLog" "${logFile}"
    else
        log "Getting ${severity} log messages on ${midnight} for the ${app} application..." 
        "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${midnight}" "-minLevel" "${severity}" "-outLog" "${logFile}"
    fi

# Special time length value 'lastHour' so get everything for last 60 minutes
elif [[ "${duration}" == "lastHour" ]]; then
    oneHourAgo="$(date -d "1 hour ago" "${timeFormat}")"
    if [[ "${getAllApps}" == "true" ]]; then
        log "Getting ${severity} log messages since ${oneHourAgo} for all applications..."
        "${logViewer}" "-startDate" "${oneHourAgo}" "-minLevel" "${severity}" "-outLog" "${logFile}"
    else
        log "Getting ${severity} log messages since ${oneHourAgo} for the ${app} application..."
        "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${oneHourAgo}" "-minLevel" "${severity}" "-outLog" "${logFile}"
    fi

# Special time length value 'monitor' so tail the logs
elif [[ "${duration}" == "monitor" ]]; then
    if [[ "${getAllApps}" == "true" ]]; then
        log "Monitoring ${severity} log messages for all applications (Ctrl-C to stop)..."
        "${logViewer}" "-minLevel" "${severity}" "-monitor" 1
    else
        log "Monitoring ${severity} log messages for the ${app} application (Ctrl-C to stop)..."
        "${logViewer}" "-includeExtensions" "appName=${app}" "-minLevel" "${severity}" "-monitor" 1
    fi

# Time length specified as integer so get that many minutes of logging
elif [[ "${duration}" =~ ^[0-9]+$ ]]; then
    duration="${duration} minutes ago"
    nMinutesAgo="$(date -d "${duration}" "${timeFormat}")"
    if [[ "${getAllApps}" == "true" ]]; then
        log "Getting ${severity} log messages since ${nMinutesAgo} for all applications..."
        "${logViewer}" "-startDate" "${nMinutesAgo}" "-minLevel" "${severity}" "-outLog" "${logFile}"
    else
        log "Getting ${severity} log messages since ${nMinutesAgo} for the ${app} application..."
        "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${nMinutesAgo}" "-minLevel" "${severity}" "-outLog" "${logFile}"
    fi

# Invalid value
else
    log "Time duration must be an integer or the special values 'monitor', 'lastHour', or 'today'"
    exit 1
fi
