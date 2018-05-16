# Source the prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1

function init() { 

	$global:ErrorActionPreference = "SilentlyContinue"
	$global:WarningPreference = "SilentlyContinue"
	$global:ProgressPreference = "SilentlyContinue"

}

function term() { 

	$global:ErrorActionPreference = "Continue"
	$global:WarningPreference = "Continue"
	$global:ProgressPreference = "Continue"

}

# Tests to make sure the effective user ID is Administrator
function checkForAdmin() {

    $script=$(Split-Path $($MyInvocation.ScriptName) -Leaf)

    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "${script} needs to run as Administrator. Exiting."
        exit 1
    }

}

# Tests to make sure the WAS Deployment Manager is available on this system
function checkForDmgr() {

    $script=$(Split-Path $($MyInvocation.ScriptName) -Leaf)

    if (!(Test-Path -Path "${wasDmgrProfile}")) {
        Write-Host "${script} can only run on the Deployment Manager node. Exiting."
        exit 1
    }

}

# Tests to make sure Connections is installed on this system
function checkForIC() {

	$script=$(Split-Path $($MyInvocation.ScriptName) -Leaf)
	

    if (!(Test-Path -Path "${icInstallDir}")) {
        Write-Host "${script} can only run on Connections nodes. Exiting."
        exit 1
    }

}

# Tests to make sure TDI is installed on this system
function checkForTDI() {

    $script=$(Split-Path $($MyInvocation.ScriptName) -Leaf)

    if (!(Test-Path -Path "${tdiSolutionDir}")) {
        Write-Host "${script} can only run on TDI nodes. Exiting."
        exit 1
    }

}

# Print message
function log($message) {

    "{0}" -f "${message}"

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

# Check to see if Deployment Manager is available
function isDmgrAvailable() {

    $status=$((Test-NetConnection -ComputerName "${wasDmgrHost}" -Port ${wasDmgrSoapPort}).TcpTestSucceeded)
	return "${status}"

}

# Prints the status of the specified WAS server
# $server: server to check
# $profile: profile root
# $noDisplay: (Optional) boolean (true returns the result via subshell, any other value prints to display)
function getWASServerStatus($server, $profile, $noDisplay) {
	
    # If no WAS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
	if (!"${wasInstallDir}" -Or !(Test-Path "${wasInstallDir}")) {
		return
	}

	# Get the basename of the profile directory
	$profileBasename=$(Split-Path "${profile}" -Leaf)
	
	# Only print info if noDisplay is not true
	if ("${noDisplay}" -ne "true") {
		Write-Host -NoNewLine ("{0,-20}{1,-40}" -f "Server: ${server}", "Profile: ${profileBasename}")
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
			Write-Host -ForegroundColor Green ("{0,-7}" -f "STARTED")
		}
	} else {
		# If we did not find a match, the server is stopped
		if ("${noDisplay}" -eq "true") {
			# Return status
			return "STOPPED"
		} else {
			# Display status
			Write-Host -ForegroundColor Red ("{0,-7}" -f "STOPPED")
		}
	}
	
}

# Start the specified WAS server
# $server: server
# $profile: profile path
function startWASServer($server, $profile) {

	# Get the basename of the profile directory
	$profileBasename=$(Split-Path "${profile}" -Leaf)

    Write-Host -NoNewLine ("{0,-60}" -f "Starting server ${server} in profile ${profileBasename}...")

    # Get the result of the startServer.bat command
	$status=$(& "${profile}\bin\startServer.bat" "${server}" *>&1)

    # Check to see if server is started
    if ("${status}" -Like "*ADMU3027E*" -Or "${status}" -Like "*ADMU3000I*") {
        Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE")
    }

}

# Stop the specified WAS server
# $server: server
# $profile: profile path
function stopWASServer($server, $profile) {

	# Get the basename of the profile directory
	$profileBasename=$(Split-Path "${profile}" -Leaf)

    Write-Host -NoNewLine ("{0,-60}" -f "Stopping server ${server} in profile ${profileBasename}...")

    # Get the result of the startServer.bat command
	$status=$(& "${profile}\bin\stopServer.bat" "${server}" -username "${wasAdmin}" -password "${wasAdminPwd}" *>&1)
	
	# Check to see if server is stopped
    if ("${status}" -Like "*ADMU0509I*" -Or "${status}" -Like "*ADMU4000I*") {
        Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE")
    }

}

# Prints the status of the IHS server
function getIHSServerStatus() {

	# If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
	if (!"${ihsInstallDir}" -Or !(Test-Path "${ihsInstallDir}")) {
		return
	}
		
	Write-Host -NoNewLine ("{0,-60}" -f "Server: IHS")

    # See if the server is running
	if (Get-WmiObject Win32_Process -Filter "Name='httpd.exe'") {
		# If we found a match, the server is started
        Write-Host -ForegroundColor Green ("{0,-7}" -f "STARTED")
	} else {
		# If we did not find a match, the server is stopped
        Write-Host -ForegroundColor Red ("{0,-7}" -f "STOPPED")
	}

}

# Start IHS server
function startIHSServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if (!"${ihsInstallDir}" -Or !(Test-Path "${ihsInstallDir}")) {
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    }

    Write-Host -NoNewLine ("{0,-60}" -f "Starting IHS server...")

	# Stop the server
    $status=$(& "${ihsInstallDir}\bin\apache.exe" -k "start" *>${null})
    
	# Check to see if server is started
    if (Get-WmiObject Win32_Process -Filter "Name='httpd.exe'") {
        Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE")
    }

}

# Stop IHS server
function stopIHSServer() {

    # If no IHS installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if (!"${ihsInstallDir}" -Or !(Test-Path "${ihsInstallDir}")) {
        log "IHS does not appear to be installed on this system. Exiting."
        exit 0
    }

	Write-Host -NoNewLine ("{0,-60}" -f "Stopping IHS server...")

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
        Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE")
    } else {
        Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
    }

}

# Prints the status of the DB2 server
function getDB2ServerStatus() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
	if (!"${db2InstallDir}" -Or !(Test-Path "${db2InstallDir}")) {
        return
    }
	
	Write-Host -NoNewLine ("{0,-60}" -f "Server: DB2")

    # See if the server is running
	if (Get-WmiObject Win32_Process -Filter "Name='db2sysc.exe' OR Name='db2syscs.exe'") {
		# If we found a match, the server is started
        Write-Host -ForegroundColor Green ("{0,-7}" -f "STARTED")
	} else {
		# If we did not find a match, the server is stopped
        Write-Host -ForegroundColor Red ("{0,-7}" -f "STOPPED")
	}

}

# Start DB2 
function startDB2Server() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if (!"${db2InstallDir}" -Or !(Test-Path "${db2InstallDir}")) {
        log "DB2 does not appear to be installed on this system. Exiting."
        exit 0
    }

	Write-Host -NoNewLine ("{0,-60}" -f "Starting DB2...")

	$status=$(& "${db2InstallDir}\bin\db2start.exe" *>&1)

    if ("${status}" -Like "*SQL1063N*" -Or "${status}" -Like "*SQL1026N*") {
        Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE") 
    }

}

# Stop DB2
function stopDB2Server() {

    # If no DB2 installation directory is specified in ictools.conf or the directory doesn't exist, do nothing
    if (!"${db2InstallDir}" -Or !(Test-Path "${db2InstallDir}")) {
        log "DB2 does not appear to be installed on this system. Exiting."
        exit 0
    }

    Write-Host -NoNewLine ("{0,-60}" -f "Stopping DB2...")

    $status=$(& "${db2InstallDir}\bin\db2stop.exe" *>&1)
	
	if ("${status}" -Like "*SQL1064N*" -Or "${status}" -Like "*SQL1032N*") {
        Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
    } else {
        Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE") 
    }

}