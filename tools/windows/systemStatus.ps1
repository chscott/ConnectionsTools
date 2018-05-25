# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Check status for DB2
getDB2ServerStatus

# Check status for IHS
getIHSServerStatus

# Check status for IHS Admin
getIHSAdminServerStatus

# Check status for WAS servers

# Build an array of WAS profiles
if ($(directoryExists "${wasProfileRoot}") -eq "true" -and $(directoryHasSubDirs "${wasProfileRoot}") -eq "true") {
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
} else {
	log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
}

foreach ($profile in ${profiles}) {
	# If there is no servers directory or it has no subdirectories, skip this profile
	if ($(directoryExists "${wasProfileRoot}\${profile}\servers") -eq "false" -or 
		$(directoryHasSubDirs "${wasProfileRoot}\${profile}\servers") -eq "false") {
		continue
	} else {
		# Get an array of servers
		$servers=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers")
		foreach ($server in ${servers}) {
			# Only check servers that are in the cell but not of type webserver (since webservers aren't checked the same way)
			if (($(isServerInWASCell "${server}" "${profile}") -eq "true") -and ($(isWASWebserver "${server}" "${profile}") -eq "false")) {
				getWASServerStatus "${server}" "${wasProfileRoot}\${profile}"
			}
		}
	}
}