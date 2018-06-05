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

# If one argument is provided, it is the string to search for (in the current directory). If two, it is the directory (0) to search and the string (1)
if ((${args}.Count) -eq 1) {
	$path=(Get-Location).Path
	$string=${args}[0]
} elseif ((${args}.Count) -eq 2) {
	$path=${args}[0]
	$string=${args}[1]
}

# Change directory to the Deployment Manager bin directory
Push-Location -Path "${wasDmgrProfile}\bin" -StackName ConnectionsTools
	
if (!"${string}") {
	log "No search string supplied. Exiting."
	exit 1
}

log "Searching JARs in ${path} for '${string}'..."

Get-ChildItem -Path "${path}" -Recurse -Directory -ErrorAction SilentlyContinue | 
	ForEach-Object {
		$directory=${_}.FullName
		cd "${directory}"
		Get-ChildItem -File -Path "*.jar" |
			ForEach-Object {
				$file=${_}
				$match=$(& "unzip.exe" -c "${file}" | Select-String "${string}")
				if (${match}) {
					log "${file}"
				}
			}
	}

# Return to the original directory
Pop-Location -StackName ConnectionsTools