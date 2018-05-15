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

# Stop WAS servers
& "${PSScriptRoot}\stopAppServers.ps1"

# Stop WAS nodeagents
& "${PSScriptRoot}\stopNodeagents.ps1"

# Stop WAS Deployment Manager
& "${PSScriptRoot}\stopDmgr.ps1"

# Stop IHS
& "${PSScriptRoot}\stopIHS.ps1"

# Stop DB2
& "${PSScriptRoot}\stopDB2.ps1"

# Reset global variables
term