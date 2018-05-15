# Source prereqs
. (Join-Path "${PSScriptRoot}" etc\ictools.ps1)
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

# Build an array of WAS profiles
if (Test-Path -Path "${wasProfileRoot}") {
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
}

# Start WAS server nodeagents
ForEach ($profile In ${profiles}) {

	# Determine the profile type
    $profileKey="${wasProfileRoot}\${profile}\properties\profileKey.metadata"
    if (Test-Path "${profileKey}") {
        $profileType=$(getWASProfileType "${profileKey}")
    }

    if ("${profileType}" -eq "BASE") {

        # If the profile directory has no servers directory, skip it
		if (Test-Path -Path "${wasProfileRoot}\${profile}\servers") {
			# Get an array of servers (only the nodeagent!)
            $servers=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers" | Select-String -Pattern "nodeagent") 
            # Start the servers
            ForEach ($server in ${servers}) {
                startWASServer "${server}" "${wasProfileRoot}\${profile}"
            }
        } else {
            log "No servers were found in the ${profile} profile"
            exit 1
        }
		
    }

}

# Reset global variables
term