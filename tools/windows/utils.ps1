# Source the prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1

# Print message
function log($message) {

    "{0}" -f "${message}"

}

function init() { 

	# Set script variables
	$script:ErrorActionPreference = "SilentlyContinue"
	$script:WarningPreference = "SilentlyContinue"
	$script:ProgressPreference = "SilentlyContinue"
	
	# Ensure minimum PS version
	$psVersion=$PSVersionTable.PSVersion.Major
	if (${psVersion} -lt 5) {
		log "Unsupported PowerShell version. Please upgrade to PowerShell 5 or later."
		exit 1
	}
	
}

# Tests to make sure the effective user ID is Administrator
function checkForAdmin() {

    $script=$(Split-Path $($MyInvocation.ScriptName) -Leaf)

    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        log "${script} needs to run as Administrator. Exiting."
        exit 1
    }

}

# Tests to make sure the WAS Deployment Manager is available on this system
function checkForDmgr() {

    $script=$(Split-Path $($MyInvocation.ScriptName) -Leaf)

    if (!(Test-Path -Path "${wasDmgrProfile}")) {
        log "${script} can only run on the Deployment Manager node. Exiting."
        exit 1
    }

}

# Tests to make sure Connections is installed on this system
function checkForIC() {

	$script=$(Split-Path $($MyInvocation.ScriptName) -Leaf)
	

    if (!(Test-Path -Path "${icInstallDir}")) {
        log "${script} can only run on Connections nodes. Exiting."
        exit 1
    }

}

# Tests to make sure TDI is installed on this system
function checkForTDI() {

    $script=$(Split-Path $($MyInvocation.ScriptName) -Leaf)

    if (!(Test-Path -Path "${tdiSolutionDir}")) {
        log "${script} can only run on TDI nodes. Exiting."
        exit 1
    }

}

# Verify that a given directory exists
function directoryExists($directory) {

	if (Test-Path -Path "${directory}") {
		return "true"
	} else {
		return "false"
	}
	
}

# Verify that a given directory has subdirectories
function directoryHasSubDirs($directory) {
	if ($((Get-ChildItem "${directory}" -Directory | Measure-Object).Count -gt 0 2>${null})) {
		return "true"
	} else {
		return "false"
	}
	
}

# Given a profileKey.metadata file, return the profile type
function getWASProfileType($profileKeyFile) {

    $profileType=$(
        Select-String -Path "${profileKeyFile}" -Pattern "com.ibm.ws.profile.type" -CaseSensitive | 
        ForEach-Object { $_.Line.Split('=')[1]; }
    )
    
    if (${?}) {
        return "${profileType}"
    } else {
        return "INVALID"
    }

}

# Determine if a given profile is of type DEPLOYMENT_MANAGER
function isWASDmgrProfile($profile) {

	# Determine the profile type
    $profileKey="${wasProfileRoot}\${profile}\properties\profileKey.metadata"
    if (Test-Path "${profileKey}") {
        $profileType=$(getWASProfileType "${profileKey}")
    }

    if ("${profileType}" -eq "DEPLOYMENT_MANAGER") {
		return "true"
	} else {
		return "false"
	}

}

# Determine if a given profile is of type BASE
function isWASBaseProfile($profile) {

	# Determine the profile type
    $profileKey="${wasProfileRoot}\${profile}\properties\profileKey.metadata"
    if (Test-Path "${profileKey}") {
        $profileType=$(getWASProfileType "${profileKey}")
    }

    if ("${profileType}" -eq "BASE") {
		return "true"
	} else {
		return "false"
	}

}

# Determine if a given server is part of the WAS cell
function isServerInWASCell($server, $profile) {

	$isInCell="false"
	$server
	$profile
		
	# Build an array of servers known to this cell
	$cellServers=$(
		Get-ChildItem -Path "${wasProfileRoot}\${profile}\config\cells\${wasCellName}\nodes" -Recurse -Include serverindex.xml 2>${null} | 
		Select-String "serverName" |
		ForEach-Object { 
			$_.ToString().Split() | 
			Select-String serverName | 
			foreach { 
				$_.Line.Split('=').Replace('"','') | 
				Select-String -NotMatch serverName
			}
		}
	) | Sort-Object -Unique
	
	# Verify that this server exists in the cell
	foreach ($cellServer in ${cellServers}) {
		if ("${cellServer}" -eq "${server}") {
			$isInCell="true"
		}
	}

	return "${isInCell}"

}

# Check to see if Deployment Manager is available
function isDmgrAvailable() {

	# Test-NetConnection appears to need the global scope vars to be set to SilentlyContinue
	$global:ErrorActionPreference = "SilentlyContinue"
	$global:WarningPreference = "SilentlyContinue"
	$global:ProgressPreference = "SilentlyContinue"
	
    $status=$((Test-NetConnection -ComputerName "${wasDmgrHost}" -Port ${wasDmgrSoapPort}).TcpTestSucceeded)
	
	# Reset the global scope vars
	$global:ErrorActionPreference = "Continue"
	$global:WarningPreference = "Continue"
	$global:ProgressPreference = "Continue"
	
	return "${status}"

}

# Prints the status of the specified WAS server
# $server: server to check
# $profile: profile root
# $noDisplay: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getWASServerStatus($server, $profile, $noDisplay) {
	
    # If no WAS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
	if (!"${wasInstallDir}" -or !(Test-Path "${wasInstallDir}")) {
		return
	}

	# Get the basename of the profile directory
	$profileBasename=$(Split-Path "${profile}" -Leaf)
	
	# Only print info if noDisplay is not true
	if ("${noDisplay}" -ne "true") {
		Write-Host -NoNewLine ("{0,${left2Column}}" -f "Server: ${profileBasename}.${server}")
	}
	
	# This approach is much faster than using serverStatus.bat and unlikely to yield false positives
	if (Get-WmiObject Win32_Process -Filter "Name='java.exe' AND CommandLine LIKE '%${profileBasename}%'" | 
		ForEach-Object { return $_.CommandLine } | 
		ForEach-Object { 
			$_.Split() | 
			Where-Object { $_ -ne "" } | 
			Select-Object -Last 1 | 
			Select-String -Pattern "${server}" -Quiet 
		}) {
		# If we found a match, the server is started
		if ("${noDisplay}" -eq "true") {
			# Return status
			return "STARTED"
		} else {
			# Display status
			Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "STARTED")
		}
	} else {
		# If we did not find a match, the server is stopped
		if ("${noDisplay}" -eq "true") {
			# Return status
			return "STOPPED"
		} else {
			# Display status
			Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "STOPPED")
		}
	}
	
}

# Start the specified WAS server
# $server: server
# $profile: profile path
function startWASServer($server, $profile) {

	# Get the basename of the profile directory
	$profileBasename=$(Split-Path "${profile}" -Leaf)

    Write-Host -NoNewLine ("{0,${left2Column}}" -f "Starting server ${server} in profile ${profileBasename}...")

    # Get the result of the startServer.bat command
	$status=$(& "${profile}\bin\startServer.bat" "${server}" *>&1)

    # Check to see if server is started
    if ("${status}" -like "*ADMU3027E*" -or "${status}" -like "*ADMU3000I*") {
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
    }

}

# Stop the specified WAS server
# $server: server
# $profile: profile path
function stopWASServer($server, $profile) {

	# Get the basename of the profile directory
	$profileBasename=$(Split-Path "${profile}" -Leaf)

    Write-Host -NoNewLine ("{0,${left2Column}}" -f "Stopping server ${server} in profile ${profileBasename}...")

    # Get the result of the startServer.bat command
	$status=$(& "${profile}\bin\stopServer.bat" "${server}" -username "${wasAdmin}" -password "${wasAdminPwd}" *>&1)
	
	# Check to see if server is stopped
    if ("${status}" -like "*ADMU0509I*" -or "${status}" -like "*ADMU4000I*") {
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
    }

}

# Prints the status of the IHS server
function getIHSServerStatus() {

	# If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
	if (!"${ihsInstallDir}" -or !(Test-Path "${ihsInstallDir}")) {
		return
	}
		
	Write-Host -NoNewLine ("{0,${left2Column}}" -f "Server: IHS")

    # See if the server is running
	if (Get-WmiObject Win32_Process -Filter "Name='httpd.exe'") {
		# If we found a match, the server is started
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "STARTED")
	} else {
		# If we did not find a match, the server is stopped
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "STOPPED")
	}

}

# Start IHS server
function startIHSServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if (!"${ihsInstallDir}" -or !(Test-Path "${ihsInstallDir}")) {
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    }

    Write-Host -NoNewLine ("{0,${left2Column}}" -f "Starting IHS server...")

	# Stop the server
    $status=$(& "${ihsInstallDir}\bin\apache.exe" -k "start" *>${null})
    
	# Check to see if server is started
    if (Get-WmiObject Win32_Process -Filter "Name='httpd.exe'") {
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
    }

}

# Stop IHS server
function stopIHSServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if (!"${ihsInstallDir}" -or !(Test-Path "${ihsInstallDir}")) {
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    }

	Write-Host -NoNewLine ("{0,${left2Column}}" -f "Stopping IHS server...")

    # Stop the server
    $status=$(& "${ihsInstallDir}\bin\apache.exe" -k "stop" *>${null})
	    
    # Wait a few seconds for process termination 
    Start-Sleep -s ${serviceDelaySeconds} 

    # Kill any remaining processes
	if (Get-WmiObject Win32_Process -Filter "Name='httpd.exe'") {
		Stop-Process -Name "httpd.exe" -Force
	}

    # Check to see if server is stopped
    if (Get-WmiObject Win32_Process -Filter "Name='httpd.exe'") {
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
    } else {
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
    }

}

# Prints the status of the DB2 server
function getDB2ServerStatus() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
	if (!"${db2InstallDir}" -or !(Test-Path "${db2InstallDir}")) {
        return
    }
	
	Write-Host -NoNewLine ("{0,${left2Column}}" -f "Server: DB2")

    # See if the server is running
	if (Get-WmiObject Win32_Process -Filter "Name='db2sysc.exe' OR Name='db2syscs.exe'") {
		# If we found a match, the server is started
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "STARTED")
	} else {
		# If we did not find a match, the server is stopped
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "STOPPED")
	}

}

# Start DB2 
function startDB2Server() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if (!"${db2InstallDir}" -or !(Test-Path "${db2InstallDir}")) {
        log "DB2 does not appear to be installed on this system. Exiting."
        exit 0
    }

	Write-Host -NoNewLine ("{0,${left2Column}}" -f "Starting DB2...")

	$status=$(& "${db2InstallDir}\bin\db2start.exe" *>&1)

    if ("${status}" -like "*SQL1063N*" -or "${status}" -like "*SQL1026N*") {
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
	} elseif ("${status}" -like "*SQL1025N*") {
		Write-Host -NoNewLine -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
		Write-Host " (active connections)"
    } else {
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE") 
    }

}

# Stop DB2
function stopDB2Server() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if (!"${db2InstallDir}" -or !(Test-Path "${db2InstallDir}")) {
        log "DB2 does not appear to be installed on this system. Exiting."
        exit 0
    }

    Write-Host -NoNewLine ("{0,${left2Column}}" -f "Stopping DB2...")

    $status=$(& "${db2InstallDir}\bin\db2stop.exe" *>&1)
	
	if ("${status}" -like "*SQL1064N*" -or "${status}" -like "*SQL1032N*") {
        Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE") 
    }

}

# Set script variables
$script:ErrorActionPreference = "SilentlyContinue"
$script:WarningPreference = "SilentlyContinue"
$script:ProgressPreference = "SilentlyContinue"