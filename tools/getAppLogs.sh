#!/bin/bash

appName=${1}
timeLength=${2}
binDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logViewer=${binDir}/logViewer.sh
profileDir="$(dirname "${binDir}")"
logsDir=${profileDir}/logs
logFile=${logsDir}/${appName}.log
timeFormat="+%m/%d/%y %H:%M:%S:%3N %Z"

function debug() {
    printf "appName: ${appName}\n"
    printf "timeLength: ${timeLength}\n"
    printf "binDir: ${binDir}\n"
    printf "logViewer: ${logViewer}\n"
    printf "profileDir: ${profileDir}\n"
    printf "logsDir: ${logsDir}\n"
    printf "logFile: ${logFile}\n"
    exit 0
}

function usage() {
    printf "Usage: getAppLogs.sh [application] [time]\n"
    printf "[application] is any valid WebSphere application name or the special value 'All'\n"
    printf "[time] is an integer representing minutes of logging to retrieve or the special values 'today' or 'lastHour'\n"
    printf "\n"
    printf "Examples:\n"
    printf "getAppLogs.sh Activities today (get all messages from Activities app since midnight)\n"
    printf "getAppLogs.sh Blogs lastHour (get all messages from Blogs app for last 60 minutes)\n"
    printf "getAppLogs.sh Communities 5 (get all messages from Communities app for last 5 minutes)\n"
    printf "getAppLogs.sh All 30 (get all messages from all apps for last 30 minutes)\n"
    printf "getAppLogs.sh All (get all messages from all apps since beginning of log)\n"
    exit 1
}

# Ensure an app name was provided
if [ -z ${appName} ]; then
    usage
fi

# Check to see if the app name is Debug
if [ ${appName} = 'Debug' ]; then
    debug
fi

# Check to see if the app name is All
getAllApps=false
if [ ${appName} = 'All' ]; then
   getAllApps=true 
fi

# No time length provided so get everything 
if [ -z ${timeLength} ]; then
    if [ ${getAllApps} = 'true' ]; then
        printf "Getting all log messages for all applications...\n"
        ${logViewer} -outLog ${logFile} 
    else
        printf "Getting all log messages for the ${appName} application...\n"
        ${logViewer} -includeExtensions appName=${appName} -outLog ${logFile} 
    fi

# Special time length value 'today' so get everything since midnight
elif [ ${timeLength} = 'today' ]; then
    midnight=$(date +%m/%d/%y) 
    if [ ${getAllApps} = 'true' ]; then
        printf "Getting all log messages on ${midnight} for all applications...\n"
        ${logViewer} -startDate ${midnight} -outLog ${logFile}
    else
        printf "Getting all log messages on ${midnight} for the ${appName} application...\n" 
        ${logViewer} -includeExtensions appName=${appName} -startDate ${midnight} -outLog ${logFile}
    fi

# Special time length value 'lastHour' so get everything for last 60 minutes
elif [ ${timeLength} = 'lastHour' ]; then
    oneHourAgo=$(date -d '1 hour ago' "${timeFormat}")
    if [ ${getAllApps} = 'true' ]; then
        printf "Getting all log messages since ${oneHourAgo} for all applications...\n"
        ${logViewer} -startDate "${oneHourAgo}" -outLog ${logFile}
    else
        printf "Getting all log messages since ${oneHourAgo} for the ${appName} application...\n"
        ${logViewer} -includeExtensions appName=${appName} -startDate "${oneHourAgo}" -outLog ${logFile}
    fi

# Time length specified as integer so get that many minutes of logging
elif [[ ${timeLength} =~ ^[0-9]+$ ]]; then
    timeLength="${timeLength} minutes ago"
    nMinutesAgo=$(date -d "${timeLength}" "${timeFormat}")
    if [ ${getAllApps} = 'true' ]; then
        printf "Getting all log messages since ${nMinutesAgo} for all applications...\n"
        ${logViewer} -startDate "${nMinutesAgo}" -outLog ${logFile}
    else
        printf "Getting all log messages since ${nMinutesAgo} for the ${appName} application...\n"
        ${logViewer} -includeExtensions appName=${appName} -startDate "${nMinutesAgo}" -outLog ${logFile}
    fi

# Invalid value
else
    usage
fi
