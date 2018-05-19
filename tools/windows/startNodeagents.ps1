# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Build an array of WAS profiles
if ($(directoryExists "${wasProfileRoot}") -eq "true" -and $(directoryHasSubDirs "${wasProfileRoot}") -eq "true") {
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
} else {
	log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
}

foreach ($profile in ${profiles}) {
	# Deployment Manager profiles have no nodeagent, so skip them
    if ($(isWASBaseProfile "${profile}") -eq "true") {
        # If there is no servers directory or it has no subdirectories, skip this profile
		if ($(directoryExists "${wasProfileRoot}\${profile}\servers") -eq "false" -or 
			$(directoryHasSubDirs "${wasProfileRoot}\${profile}\servers") -eq "false") {
			continue
		} else {
			# Find the nodeagent
            $server=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers" | Select-String -Pattern "nodeagent" | Select-Object -First 1) 
			if ($(isServerInWASCell "${server}" "${profile}") -eq "true") {
				# The server is part of the cell, so go ahead and start it
				startWASServer "${server}" "${wasProfileRoot}\${profile}"
			}
        }	
    }
}