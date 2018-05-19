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

	Write-Host -NoNewLine ("{0,-60}" -f "Synchronizing active nodes...")
	
    # Call wsadmin with the syncNodes.py script to perform online sync
    & "${PSScriptRoot}\wsadmin.ps1" "${PSScriptRoot}\wsadmin\syncNodes.py" *>${null}
 
    # Report status
    if (${?}) {
        Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE")
    }

}

function offlineSync($profiles) {

    # Build an array of WAS profiles
	if ($(directoryExists "${wasProfileRoot}") -eq "true" -and $(directoryHasSubDirs "${wasProfileRoot}") -eq "true") {
		$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
	} else {
		log "Error: wasProfileRoot must be set to a valid directory in ictools.conf"
	}
	
    ForEach ($profile In ${profiles}) {
		# Can only synchronize profiles of type BASE
		if ($(isWASBaseProfile "${profile}") -eq "true") {
			# If there is no servers directory or it has no subdirectories, skip this profile
			if ($(directoryExists "${wasProfileRoot}\${profile}\servers") -eq "false" -or 
				$(directoryHasSubDirs "${wasProfileRoot}\${profile}\servers") -eq "false") {
				continue
			} else {
				# Get an array of servers (only named "nodeagent")
				$servers=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers" | Select-String -Pattern "nodeagent") 
				# Make sure all servers are 1) part of this cell and 2) stopped
				$areAllServersInCell="true"
                $areAllServersStopped="true"
                ForEach ($server in ${servers}) {
					if ($(isServerInWASCell "${server}" "${profile}") -eq "false") {
						$areAllServersInCell="false"
					}
                    if ($(getWASServerStatus "${server}" "${wasProfileRoot}\${profile}" "true") -ne "STOPPED") {
                        $areAllServersStopped="false"
                    }
                }
				# Silently ignore any servers that are not part of this cell
				if ("${areAllServersInCell}" -eq "true") {
					Write-Host -NoNewLine ("{0,-60}" -f "Synchronizing servers in ${profile} profile...")
				}
				# Try the sync if all servers are stopped
                if ("${areAllServersStopped}" -eq "true") {
                    & "${wasProfileRoot}\${profile}\bin\syncNode.bat" "${wasDmgrHost}" "-user" "${wasAdmin}" "-password" "${wasAdminPwd}" *>${null}
                    # Log status
                    if (${?}) {
                        Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
                    } else {
                        Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE")
                    }
                } else {
					Write-Host -NoNewLine -ForegroundColor Red ("{0,-7}" -f "FAILURE")
					Write-Host " (At least one server is still running)"
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