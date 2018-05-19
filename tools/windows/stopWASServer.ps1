# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Process the user arguments
$argsList = New-Object System.Collections.ArrayList(,${args})
$profile=$null
$server=$null
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

if ($(isServerInWASCell "${server}" "${profile}") -eq "true") {
	stopWASServer "${server}" "${wasProfileRoot}\${profile}"
} else {
	Write-Host "Error: ${server} is not in WAS cell ${wasCellName}"
}