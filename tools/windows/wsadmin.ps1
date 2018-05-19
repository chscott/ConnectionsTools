# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Make sure we're on the Deployment Manager
checkForDmgr

# See if the Deployment Manager is available
if ($(isDmgrAvailable) -eq "False") {
	log "The Deployment Manager must be running to launch wsadmin"
	exit 1
} 

# Get the full path of the provided file (needed since we cd to the Deployment Manager bin directory later)
$argsList = New-Object System.Collections.ArrayList(,${args})
if (${argsList}.Count -gt 0 -And $(Test-Path ${argsList}[0])) {
	$script=$((Resolve-Path ${argsList}[0]).Path)
	# Clear first element so the remaining args can be passed to wsadmin
	${argsList}.RemoveRange(0,1)
	$args=${argsList}
} elseif (${argsList}.Count -gt 0 -And !$(Test-Path ${argsList}[0])) {
	log $(${argsList}[0] + ": No such file or directory")
	exit 1
}

# Change directory to the Deployment Manager bin directory
Push-Location -Path "${wasDmgrProfile}\bin" -StackName ConnectionsTools

if (!"${script}") {
    # No script provided, so just start a wsadmin shell  
    & "${wasDmgrProfile}\bin\wsadmin.bat" "-lang" "jython" "-user" "${wasAdmin}" "-password" "${wasAdminPwd}"
} elseif (!${args}) {
	# No arguments provided, so just run wsadmin with the script as input
	& "${wasDmgrProfile}\bin\wsadmin.bat" "-lang" "jython" "-user" "${wasAdmin}" "-password" "${wasAdminPwd}" "-f" "${script}"
} else {
    # Run wsadmin with the script as input and pass the additional arguments
    & "${wasDmgrProfile}\bin\wsadmin.bat" "-lang" "jython" "-user" "${wasAdmin}" "-password" "${wasAdminPwd}" "-f" "${script}" ${args}
}

# Return to the original directory
Pop-Location -StackName ConnectionsTools