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

# See which fixes are installed
$installedFixes=@()
$output=$(& ".\updateSilent.bat" "-fix" "-installDir" "${icInstallDir}")
foreach ($line in ${output}) {
	if ("${line}" -match "Fix name:") {
		$installedFixes+=$(("${line}" -split ": ")[1])
	}
}
$installedFixes=$(${installedFixes} | Sort-Object)

log "Installed Connections fixes:"

# For each installed fix, get details from the Connections efix files
foreach ($fix in ${installedFixes}) {
    $description=$(Get-Content "${icInstallDir}\version\${fix}.efix" | Select-String "short-description" | ForEach-Object { (("${_}" -split "=")[1]) -replace '[<>\"]','' })
	$version=$(Get-Content "${icInstallDir}\version\${fix}.efix" | Select-String "build-version" | ForEach-Object { (("${_}" -split "=")[1]) -replace '[<>\"]','' })
	$date=$(Get-Content "${icInstallDir}\version\${fix}.efix" | Select-String "build-date" | ForEach-Object { (("${_}" -split "=")[1]) -replace '[<>\"]','' })
	log "${separator}"
	"{0,-13}{1,-11}" -f "Fix ID:", "${fix}"
	"{0,-13}{1,-11}" -f "Description:", "${description}"
	"{0,-13}{1,-11}" -f "Version:", "${version}"
	"{0,-13}{1,-11}" -f "Date:", "${date}"
}

log "${separator}"

# Return to the original directory
Pop-Location -StackName ConnectionsTools