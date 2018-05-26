# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Variables
$spacesPlusAlnum="\s+[\w\d]"
$app=${args}[0]
$padding="       "
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
$string+="${separator}"

if (!"${app}") {
    # No app was specified, so get all apps
	log "Getting role assignments for all applications. This may take some time..."
    $output=$(& "${PSScriptRoot}\wsadmin.ps1" "${PSScriptRoot}\wsadmin\getAppRoles.py")
} else {
    # Only get the specified app
	log "Getting role assignments for the ${app} application..."
    $output=$(& "${PSScriptRoot}\wsadmin.ps1" "${PSScriptRoot}\wsadmin\getAppRoles.py" "${app}")
}

# Extract only the relevant lines
foreach ($line in ${output}) {
	if ("${line}" -match "${string}") {
		if ("${line}" -match "^Everyone|^All authenticated|^Mapped") {
			log "${padding}${line}"
		} else {
			log "${line}"
		}
	}
}