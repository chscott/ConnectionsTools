# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Make sure this is a Deployment Manager node
checkForDmgr

# Get the fixes to uninstall
$fixes=New-Object System.Collections.ArrayList(,${args})

# Make sure fixes to uninstall were specified
if (${fixes}.Count -eq 0) {
	log "No fixes specified"
	log "Usage: uninstallFixes.sh fix1 [fix2] [fixN]..."
	exit 1
}

# See if the Deployment Manager is available
if ($(isDmgrAvailable) -eq "False") {
	log "The Deployment Manager must be running to uninstall fixes"
	exit 1
} 

# Must change to the updateInstall directory or WAS_HOME will be reset
Push-Location -Path "${icInstallDir}\updateInstaller" -StackName ConnectionsTools

# Set WAS_HOME
$env:WAS_HOME="${wasInstallDir}"

Write-Host -NoNewLine ("{0,${left2Column}}" -f "Uninstalling Connections fixes...")

# Uninstall the fixes
# The ${fixes} variable must be unquoted or entire string will be considered one fix
$output=$(& ".\updateSilent.bat" `
    "-installDir" "${icInstallDir}" `
    "-fix" `
    "-uninstall" `
    "-fixDir" "${icFixesDir}" `
    "-fixes" ${fixes} `
    "-featureCustomizationBackedUp" "yes" `
    "-wasUserId" "${wasAdmin}" `
    "-wasPassword" "${wasAdminPwd}" `
	*>&1
)

# Extract the puiReturnCode
foreach ($line in ${output}) {
	if (("${line}" | Select-String "UpdateInstaller.puiReturnCode")) {
		$status=$(("${line}" -split "UpdateInstaller.puiReturnCode is ")[1])
		break
	}
}

# Print status
if (${status} -eq 0) {
    Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
} else {
    Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
	log ""
	log "Failure log:"
	foreach ($line in ${output}) {
		"${line}"
	}
}

# Return to the original directory
Pop-Location -StackName ConnectionsTools