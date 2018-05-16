# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
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

# Stop WAS server
stopWASServer "${server}" "${wasProfileRoot}\${profile}"

# Reset global variables
term