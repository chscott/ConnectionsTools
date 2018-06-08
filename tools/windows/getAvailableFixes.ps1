# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Make sure this is a Deployment Manager node
checkForDmgr

# Must change to the updateInstall directory or WAS_HOME will be reset
Push-Location -Path "${icInstallDir}\updateInstaller" -StackName ConnectionsTools

# Set WAS_HOME
$env:WAS_HOME="${wasInstallDir}"

log "Getting a list of Connections fixes available to install in ${icFixesDir}..."

# See which fixes have already been installed
$installedFixes=@()
$output=$(& ".\updateSilent.bat" "-fix" "-installDir" "${icInstallDir}")
foreach ($line in ${output}) {
	if ("${line}" -match "Fix name:") {
		$installedFixes+=$(("${line}" -split ": ")[1])
	}
}
$installedFixes=$(${installedFixes} | Sort-Object)

# See which fixes are available in the fixes directory
$availableFixes=@()
$output=$(& ".\updateSilent.bat" "-fix" "-installDir" "${icInstallDir}" "-fixDir" "${icFixesDir}")
foreach ($line in ${output}) {
	if ("${line}" -match "^\[[0-9]*\]") {
		$availableFixes+=$(("${line}" -split " ")[1] -replace ",","")
	}
}

# Filter out the fixes that are both available and already installed. The remainder are the ones available to install
$availableToInstallFixes=@()
foreach ($availableFix in ${availableFixes}) {
    $alreadyInstalled="false"
    foreach ($installedFix in ${installedFixes}) {
        if ("${installedFix}" -eq "${availableFix}") {
            $alreadyInstalled="true" 
        }
    }
    if ("${alreadyInstalled}" -eq "false") {
		$availableToInstallFixes+="${availableFix}"
    }
}

if (${availableToInstallFixes}.Count -eq 0) {
    log "There are no fixes available to install"
} else {
    log "Fixes available to install: ${availableToInstallFixes}"
}

# Return to the original directory
Pop-Location -StackName ConnectionsTools