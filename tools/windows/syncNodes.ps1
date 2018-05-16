# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

# See if the Deployment Manager is available
if ($(isDmgrAvailable) -eq "False") {
	log "The Deployment Manager must be running to launch wsadmin"
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

    # Sync the nodes
    ForEach ($profile In ${profiles}) {

        # Determine the profile type
		$profileKey="${wasProfileRoot}\${profile}\properties\profileKey.metadata"
		if (Test-Path "${profileKey}") {
			$profileType=$(getWASProfileType "${profileKey}")
		}
		
		if ("${profileType}" -eq "BASE") {

			# If the profile directory has no servers directory, skip it
			if (Test-Path -Path "${wasProfileRoot}\${profile}\servers") {
			
				# Get an array of servers
				$servers=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers") 
				
				# Make sure all servers are stopped
                $areAllServersStopped="true"
                ForEach ($server in ${servers}) {
                    $status=$(getWASServerStatus "${server}" "${wasProfileRoot}\${profile}" "true")
                    if ("${status}" -ne "STOPPED") {
                        $areAllServersStopped="false"
                    }
                }
				
				Write-Host -NoNewLine ("{0,-60}" -f "Synchronizing servers in ${profile} profile...")
				
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
	$doOfflineSync="true"
	# Offline mode requires an array of WAS profiles from the local system
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
} else {
	$doOfflineSync="false"
	# Online mode can only run on the Deployment Manager
	checkForDmgr
}

# Do the requested sync
if ("${doOfflineSync}" -eq "true") {
    offlineSync ${profiles}
} else {
    onlineSync
}

# Reset global variables
term