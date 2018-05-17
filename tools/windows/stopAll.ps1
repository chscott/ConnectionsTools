# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

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