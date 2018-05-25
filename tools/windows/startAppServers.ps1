# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# First start the nodeagents, as these must be running to start application servers
& "${PSScriptRoot}\startNodeagents.ps1"

# Build an array of WAS profiles
if ($(directoryExists "${wasProfileRoot}") -eq "true" -and $(directoryHasSubDirs "${wasProfileRoot}") -eq "true") {
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
} else {
	log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
}

foreach ($profile in ${profiles}) {
	# Deployment Manager profiles have no application servers, so skip them
    if ($(isWASBaseProfile "${profile}") -eq "true") {
		# If there is no servers directory or it has no subdirectories, skip this profile
		if ($(directoryExists "${wasProfileRoot}\${profile}\servers") -eq "false" -or 
			$(directoryHasSubDirs "${wasProfileRoot}\${profile}\servers") -eq "false") {
			continue
		} else {
			# Get an array of servers (not named "nodeagent")
            $servers=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers" | Select-String -NotMatch -Pattern "nodeagent") 
            foreach ($server in ${servers}) {
				# Only start servers that are in the cell but not of type webserver (since webservers aren't started the same way)
				if (($(isServerInWASCell "${server}" "${profile}") -eq "true") -and ($(isWASWebserver "${server}" "${profile}") -eq "false")) {
					startWASServer "${server}" "${wasProfileRoot}\${profile}"
				}
			}
        }	
    }
}