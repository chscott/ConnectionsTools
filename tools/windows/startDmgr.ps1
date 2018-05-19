# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Make sure this is a Deployment Manager node
checkForDmgr

# Build an array of WAS profiles
if ($(directoryExists "${wasProfileRoot}") -eq "true" -and $(directoryHasSubDirs "${wasProfileRoot}") -eq "true") {
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
} else {
	log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
}

foreach ($profile in ${profiles}) {
    if ($(isWASDmgrProfile "${profile}") -eq "true") {
		# If there is no servers directory or it has no subdirectories, skip this profile
		if ($(directoryExists "${wasProfileRoot}\${profile}\servers") -eq "false" -or 
			$(directoryHasSubDirs "${wasProfileRoot}\${profile}\servers") -eq "false") {
			continue
		} else {
			# Get an array of servers
            $servers=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers") 
            foreach ($server in ${servers}) {
				if ($(isServerInWASCell "${server}" "${profile}") -eq "true") {
					# The server is part of the cell, so go ahead and start it
					startWASServer "${server}" "${wasProfileRoot}\${profile}"
				}
            }
        }	
    }
}