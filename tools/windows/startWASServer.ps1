# Source prereqs
. (Join-Path "${PSScriptRoot}" etc\ictools.ps1)
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

# Process the user arguments
$argsList = New-Object System.Collections.ArrayList(,${args})
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

# Determine the profile type
$profileKey="${wasProfileRoot}\${profile}\properties\profileKey.metadata"
if (Test-Path -Path "${profileKey}") {
    $profileType=$(getWASProfileType "${profileKey}")
}

# Take appropriate action based on profile type
if ("${profileType}" -eq "DEPLOYMENT_MANAGER") {
    # Deployment manager profiles have no nodeagent, so just start the server directly
    startWASServer "${server}" "${wasProfileRoot}\${profile}"
} elseif ("${profileType}" -eq "BASE") {
    if ("${server}" -eq "nodeagent") {
        # Admin just wants to start the nodeagent, so only do that
        startWASServer "nodeagent" "${wasProfileRoot}\${profile}"
    } else {
        # Admin wants to start the app server, so start the nodeagent first
        startWASServer "nodeagent" "${wasProfileRoot}\${profile}"
        startWASServer "${server}" "${wasProfileRoot}\${profile}"
    }
}

# Reset global variables
term