# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Start DB2
if ($(directoryExists "${db2InstallDir}") -eq "true") {
	& "${PSScriptRoot}\startDB2.ps1"
}

# Start IHS
if ($(directoryExists "${ihsInstallDir}") -eq "true") {
	& "${PSScriptRoot}\startIHS.ps1"
}

# Start WAS Deployment Manager
if ($(directoryExists "${wasDmgrProfile}") -eq "true") {
	& "${PSScriptRoot}\startDmgr.ps1"
}

# Start WAS nodeagents
if ($(directoryExists "${wasInstallDir}") -eq "true") {
	& "${PSScriptRoot}\startNodeagents.ps1"
}

# Start WAS application servers
if ($(directoryExists "${wasInstallDir}") -eq "true") {
	& "${PSScriptRoot}\startAppServers.ps1"
}