# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Verify commands are available
Get-Command "unzip.exe" *>${null}
if (!${?}) {
	log "The unzip.exe command is required to run this script"
	exit 1
} 

# Ensure the user supplied a string to search for
$string=${args}[0]
if (!"${string}") {
	log "No search string supplied. Exiting."
	exit 1
} else {
	log "Searching JARs in $((pwd).Path) for '${string}'..."
	Get-ChildItem -Recurse -File -Include "*.jar" | 
		ForEach-Object {
			$file=${_}
			$match=$(& "unzip.exe" -c "${file}" | Select-String "${string}")
			if (${match}) {
				log "${file}"
			}
		}
}