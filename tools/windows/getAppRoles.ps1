# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Variables
$spacesPlusAlnum="[[:blank:]]+[[:alnum:]]"
$app=${args}[0]
$string=""

$string+="^Application:${spacesPlusAlnum}|"
$string+="^Role:${spacesPlusAlnum}|"
$string+="^Everyone\?:${spacesPlusAlnum}|"
$string+="^All authenticated\?:${spacesPlusAlnum}|"
$string+="^Mapped users:${spacesPlusAlnum}|"
$string+="^Mapped groups:${spacesPlusAlnum}|"
$string+="^All authenticated in trusted realms\?:${spacesPlusAlnum}|"
$string+="^Mapped users access ids:${spacesPlusAlnum}|"
$string+="^Mapped groups access ids:${spacesPlusAlnum}|"
$string+="================================================================================"

if (!"${app}") {
    # No app was specified, so get all apps
	& "${PSScriptRoot}\wsadmin.ps1" "${PSScriptRoot}\wsadmin\getAppRoles.py"
    #$output=$(& "${PSScriptRoot}\wsadmin.ps1" "${PSScriptRoot}\wsadmin\getAppRoles.py")
} else {
    # Only get the specified app
    $output=$(& "${PSScriptRoot}\wsadmin.p1" "${PSScriptRoot}\wsadmin\getAppRoles.py" "${app}")
}

Write-Host "${output}"