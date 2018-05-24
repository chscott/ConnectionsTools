# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# See if the Deployment Manager is available
if ($(isDmgrAvailable) -eq "False") {
	log "The Deployment Manager must be running to sync nodes"
	exit 1
} 

# Variables
$mode=${args}[0]

function onlineSync() {

	Write-Host -NoNewLine ("{0,${left2Column}}" -f "Synchronizing active nodes...")
	
    # Call wsadmin with the syncNodes.py script to perform online sync
    & "${PSScriptRoot}\wsadmin.ps1" "${PSScriptRoot}\wsadmin\syncNodes.py" *>${null}
 
    # Report status
    if (${LASTEXITCODE} -eq 0) {
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
    }

}

function offlineSync($profiles) {

    # Build an array of WAS profiles
	if ($(directoryExists "${wasProfileRoot}") -eq "true" -and $(directoryHasSubDirs "${wasProfileRoot}") -eq "true") {
		$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
	} else {
		log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
	}
	
    foreach ($profile In ${profiles}) {
		# Can only synchronize profiles of type BASE
		if ($(isWASBaseProfile "${profile}") -eq "true") {
			# If there is no servers directory or it has no subdirectories, skip this profile
			if ($(directoryExists "${wasProfileRoot}\${profile}\servers") -eq "false" -or 
				$(directoryHasSubDirs "${wasProfileRoot}\${profile}\servers") -eq "false") {
				continue
			} else {
				# Find the nodeagent
				$server=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers" | Select-String -Pattern "nodeagent" | Select-Object -First 1) 
				# Make sure the nodeagent is part of the cell
				if ($(isServerInWASCell "${server}" "${profile}") -eq "true") {
					Write-Host -NoNewLine ("{0,${left2Column}}" -f "Synchronizing servers in ${profile} profile...")
					# Make sure the nodeagent is stopped
					if ($(getWASServerStatus "${server}" "${wasProfileRoot}\${profile}" "true") -eq "STOPPED") {
						# Do the sync
						& "${wasProfileRoot}\${profile}\bin\syncNode.bat" "${wasDmgrHost}" "-user" "${wasAdmin}" "-password" "${wasAdminPwd}" *>${null}
						# Log status
						if (${LASTEXITCODE} -eq 0) {
							Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
						} else {
							Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
						}
					} else {
						Write-Host -NoNewLine -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
						Write-Host " (nodeagent is still running)"
					}
				}
			}
		}                    
	}
	
}

# See which mode was requested
if ("${mode}" -eq "--offline") {
	offlineSync
} else {
	# Online mode can only run on the Deployment Manager
	checkForDmgr
	onlineSync
}