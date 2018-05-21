# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Verify ictools.conf data is available
if (!"${wasProfileRoot}" -or !"${wasCellName}") {
	log "The wasProfileRoot and wasCellName variables must be set in ictools.ps1"
	exit 1
}

# Process the user arguments
$argsList=New-Object System.Collections.ArrayList(,${args})
$profile=$app=$duration=$null
while (${argsList}.Count -gt 0) {
	$key=${argsList}[0]
	$value=${argsList}[1]
	switch ("${key}") {
		"--profile" { $profile="${value}" }
		"--app" { $app="${value}" }
		"--duration" { $duration="${value}" }
		default { log "Unrecognized argument ${key}" }
	}
	${argsList}.RemoveRange(0,2)
}

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

# Verify we have a profile
if (!"${profile}") {
	usage
	exit 1
} elseif ("${profile}" -eq "") {
	log "profile is an empty string"
}

# Verify that the profile directory exists
if ($(directoryExists "${wasProfileRoot}\${profile}") -ne "true") {
	log "The specified profile ${profile} does not exist on this system. Exiting."
	exit 1
}

# Verify that HPEL logging is configured
if ($((Get-ChildItem -Recurse "${wasProfileRoot}\${profile}" -Include "hpelRepository.owner" | Measure-Object).Count) -eq 0) {
	log "HPEL logging is not enabled for this profile. Exiting."
	exit 1
}

# If no app was specified, get all logs
if (!"${app}") {
	$getAllApps="true" 
	$app="All"
} else {
	$getAllApps="false" 
}

# Script variables
$logViewer="${wasProfileRoot}\${profile}\bin\logViewer.bat"
$logFile="${wasProfileRoot}\${profile}\logs\${app}.log"
$timeFormat="MM/dd/yyyy HH:mm:ss:fff zzz"

# No time length provided so get everything 
if (!"${duration}") {
    if ("${getAllApps}" -eq "true") {
        log "Getting all log messages for all applications..."
        & "${logViewer}" "-outLog" "${logFile}"
    } else {
        log "Getting all log messages for the ${app} application..."
        & "${logViewer}" "-includeExtensions" "appName=${app}" "-outLog" "${logFile}"
    }
}

# Special time length value 'today' so get everything since midnight
elseif ("${duration}" -eq "today") {
    $midnight="$(Get-Date -UFormat +%m/%d/%y)" 
    if ("${getAllApps}" -eq "true") {
        log "Getting all log messages on ${midnight} for all applications..."
        & "${logViewer}" "-startDate" "${midnight}" "-outLog" "${logFile}"
    } else {
        log "Getting all log messages on ${midnight} for the ${app} application..." 
        & "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${midnight}" "-outLog" "${logFile}"
    }
}

# Special time length value 'lastHour' so get everything for last 60 minutes
elseif ("${duration}" -eq "lastHour") {
    $oneHourAgo="$(Get-Date -Date ((Get-Date) - (New-TimeSpan -Hours 1)) -Format "${timeFormat}")" -Replace "(.*):(.*)", '$1$2'
    if ("${getAllApps}" -eq "true") {
        log "Getting all log messages since ${oneHourAgo} for all applications..."
        & "${logViewer}" "-startDate" "${oneHourAgo}" "-outLog" "${logFile}"
    } else {
        log "Getting all log messages since ${oneHourAgo} for the ${app} application..."
        & "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${oneHourAgo}" "-outLog" "${logFile}"
    }
}

# Special time length value 'monitor' so tail the logs
elseif ("${duration}" -eq "monitor") {
    if ("${getAllApps}" -eq "true") {
        log "Monitoring log messages for all applications (Ctrl-C to stop)..."
        & "${logViewer}" "-monitor" 1
    } else {
        log "Monitoring log messages for the ${app} application (Ctrl-C to stop)..."
        & "${logViewer}" "-includeExtensions" "appName=${app}" "-monitor" 1
    }
}

# Time length specified as integer so get that many minutes of logging
elseif ("${duration}" -match "^[0-9]+$") {
	$nMinutesAgo="$(Get-Date -Date ((Get-Date) - (New-TimeSpan -Minutes ${duration})) -Format "${timeFormat}")" -Replace "(.*):(.*)", '$1$2'
    if ("${getAllApps}" -eq "true") {
        log "Getting all log messages since ${nMinutesAgo} for all applications..."
        & "${logViewer}" "-startDate" "${nMinutesAgo}" "-outLog" "${logFile}"
    } else {
        log "Getting all log messages since ${nMinutesAgo} for the ${app} application..."
        & "${logViewer}" "-includeExtensions" "appName=${app}" "-startDate" "${nMinutesAgo}" "-outLog" "${logFile}"
    }
}

# Invalid value
else {
    log "Time duration must be an integer or the special value 'monitor'"
    exit 1
}