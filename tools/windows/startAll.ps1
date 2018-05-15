# Source prereqs
. (Join-Path "${PSScriptRoot}" etc\ictools.ps1)
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

# Build an array of WAS profiles
if (Test-Path -Path "${wasProfileRoot}") {
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
}

# Start DB2
& "${PSScriptRoot}\startDB2.ps1"

# Start IHS
& "${PSScriptRoot}\startIHS.ps1"

# Start WAS Deployment Manager
& "${PSScriptRoot}\startDmgr.ps1"

# Start WAS nodeagents and application servers
& "${PSScriptRoot}\startAppServers.ps1"

# Reset global variables
term