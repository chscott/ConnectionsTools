# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

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