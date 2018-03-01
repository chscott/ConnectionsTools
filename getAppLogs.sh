#!/bin/bash

appName=${1}
option=${2}
binDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logViewer=${binDir}/logViewer.sh
profileDir="$(dirname "${binDir}")"
logsDir=${profileDir}/logs
logFile=${logsDir}/${appName}.log
timeFormat="+%m/%d/%y %H:%M:%S:%3N %Z"

function usage() {
    echo "Usage: getAppLogs.sh <WebSphere application name> [minutes of logging to pull]"
    echo "Example: getAppLogs.sh News 5"
    echo "Returns the last five minutes of logging from the News application."
    exit 1
}

# Ensure an app name was provided
if [ -z ${appName} ]; then
    usage
fi

if [ -z ${option} ]; then
    ${logViewer} -includeExtensions appName=${appName} -outLog ${logFile} 
elif [ ${option} = 'today' ]; then
    midnight=$(date +%m/%d/%y) 
    ${logViewer} -includeExtensions appName=${appName} -startDate ${midnight} -outLog ${logFile}
elif [ ${option} = 'lastHour' ]; then
    oneHourAgo=$(date -d '1 hour ago' "${timeFormat}")
    ${logViewer} -includeExtensions appName=${appName} -startDate "${oneHourAgo}" -outLog ${logFile}
elif [[ ${option} =~ ^[0-9]+$ ]]; then
    option="${option} minutes ago"
    nMinutesAgo=$(date -d "${option}" "${timeFormat}")
    ${logViewer} -includeExtensions appName=${appName} -startDate "${nMinutesAgo}" -outLog ${logFile}
else
    usage
fi
