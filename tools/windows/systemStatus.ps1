# Source prereqs
. (Join-Path "${PSScriptRoot}" etc\ictools.ps1)
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Make sure we're running as admin
checkForAdmin

# Build an array of WAS profiles
if (Test-Path -Path "${wasProfileRoot}") {
	$profiles=$(Get-ChildItem "${wasProfileRoot}" -Directory | Select Name)
}

# Check status for DB2
getDB2ServerStatus

# Check status for IHS
getIHSServerStatus

# Check status for WAS servers
ForEach (${profile} in ${profiles}) {

    # Get an array of servers
    $servers=$(Get-ChildItem "${wasProfileRoot}\$(${profile}.Name)\servers" -Directory | Select Name)

    # Get the server status
    ForEach (${server} in ${servers}) {
		getWASServerStatus "$(${server}.Name)" "${wasProfileRoot}\$(${profile}.Name)"
    }

}

# Check status for Pink components