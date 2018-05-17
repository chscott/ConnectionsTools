# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

# Build an array of WAS profiles
if (Test-Path -Path "${wasProfileRoot}") {
	$profiles=$(Get-ChildItem -Directory "${wasProfileRoot}")
}

# For each profile...
ForEach ($profile In ${profiles}) {

	# Determine the profile type
    $profileKey="${wasProfileRoot}\${profile}\properties\profileKey.metadata"
    if (Test-Path "${profileKey}") {
        $profileType=$(getWASProfileType "${profileKey}")
    }

	# Only need to continue if the profile type is BASE
    if ("${profileType}" -eq "BASE") {
	
		# Build an array of servers known to this cell
		$cellServers=$(
			Get-ChildItem -Path "${wasProfileRoot}\${profile}\config\cells\${wasCellName}\nodes" -Recurse -Include serverindex.xml 2>${null} | 
			Select-String "serverName" |
			ForEach-Object { 
				$_.ToString().Split() | 
				Select-String serverName | 
				ForEach { 
					$_.Line.Split('=').Replace('"','') | 
					Select-String -NotMatch serverName
				}
			}
		)
		$cellServers=$(${cellServers} | Sort-Object -Unique)

        # If the profile directory has no servers directory, skip it
		if (Test-Path -Path "${wasProfileRoot}\${profile}\servers") {
			# Get an array of servers (only named "nodeagent")
            $profileServers=$(Get-ChildItem -Directory "${wasProfileRoot}\${profile}\servers" | Select-String -Pattern "nodeagent") 
            # Loop through the profile servers
            ForEach ($profileServer in ${profileServers}) {
				# Verify that this server exists in the cell
				ForEach ($cellServer in ${cellServers}) {
					if ("${cellServer}" -eq "${profileServer}") {
						stopWASServer "${profileServer}" "${wasProfileRoot}\${profile}"
					}
				}
            }
		}
		
    }

}