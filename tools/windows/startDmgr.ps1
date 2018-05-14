# Source prereqs
. (Join-Path "${PSScriptRoot}" etc\ictools.ps1)
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Make sure we're running as admin
checkForAdmin

# Make sure this is a Deployment Manager node
checkForDmgr

# Build an array of WAS profiles
if (Test-Path -Path "${wasProfileRoot}") {
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
}

# Find the Deployment Manager profile
ForEach ($profile In ${profiles}) {

	# Determine the profile type
    $profileKey="${wasProfileRoot}\${profile}\properties\profileKey.metadata"
    if (Test-Path "${profileKey}") {
        $profileType=$(getWASProfileType "${profileKey}")
    }

    if ("${profileType}" -eq "DEPLOYMENT_MANAGER") {

        # If the profile directory has no servers directory, skip it
		if (Test-Path -Path "${wasProfileRoot}\${profile}\servers") {
            $servers=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers") 
            # Start the server (should only be one for Deployment Manager)
            ForEach ($server in ${servers}) {
                startWASServer "${server}" "${wasProfileRoot}\${profile}"
            }
        } else {
            log "No servers were found in the ${profile} profile"
            exit 1
        }
		
    }

}