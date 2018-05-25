# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Process the user arguments
$argsList=New-Object System.Collections.ArrayList(,${args})
$profile=$server=$null
while (${argsList}.Count -gt 0) {
	$key=${argsList}[0]
	$value=${argsList}[1]
	switch ("${key}") {
		"--profile" { $profile="${value}" }
		"--server" { $server="${value}" }
		default { log "Unrecognized argument ${key}" }
	}
	${argsList}.RemoveRange(0,2)
}

# Only stop servers that are in the cell but not of type webserver (since webservers aren't stopped the same way)
if (($(isServerInWASCell "${server}" "${profile}") -eq "true") -and ($(isWASWebserver "${server}" "${profile}") -eq "false")) {
	stopWASServer "${server}" "${wasProfileRoot}\${profile}"
} elseif ($(isServerInWASCell "${server}" "${profile}") -eq "false") {
	log "Error: ${server} is not in WAS cell ${wasCellName}"
} elseif ($(isWASWebserver "${server}" "${profile}") -eq "true") {
	log "Error: ${server} is a webserver. Start IHS using startIHS.ps1"
}