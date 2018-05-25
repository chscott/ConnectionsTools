# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Stop WAS application servers
if ($(directoryExists "${wasInstallDir}") -eq "true") {
	& "${PSScriptRoot}\stopAppServers.ps1"
}

# Stop WAS nodeagents
if ($(directoryExists "${wasInstallDir}") -eq "true") {
	& "${PSScriptRoot}\stopNodeagents.ps1"
}

# Stop WAS Deployment Manager
if ($(directoryExists "${wasDmgrProfile}") -eq "true") {
	& "${PSScriptRoot}\stopDmgr.ps1"
}

# Stop IHS Admin
if ($(directoryExists "${ihsInstallDir}") -eq "true") {
	& "${PSScriptRoot}\stopIHSAdmin.ps1"
}

# Stop IHS
if ($(directoryExists "${ihsInstallDir}") -eq "true") {
	& "${PSScriptRoot}\stopIHS.ps1"
}

# Stop DB2
if ($(directoryExists "${db2InstallDir}") -eq "true") {
	& "${PSScriptRoot}\stopDB2.ps1"
}