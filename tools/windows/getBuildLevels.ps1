# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Make sure this is a Deployment Manager node
checkForDmgr

$notAvailable="Data missing from manifest"
# Add any apps to this list that you want to ignore. Generally, that means non-Connections apps
$excludes=@(
	#"commsvc",
	#"DefaultApplication",
	#"ibmasyncrsp",
	#"isclite",
	#"ivtApp",
	#"OTiS",
	#"query",
	#"WebSphereOauth20SP",
	#"WebSphereWSDM"
	"foo"
)

# Keep track of the Apps as we are processing them
$currentApp=""
$earCounter=0

# Get all manifest files and loop through them
Get-ChildItem -Recurse -Path "${wasDmgrProfile}\config\cells\${wasCellName}\applications" -Include "MANIFEST.MF" |
	ForEach-Object {
	
		# Loop variables
		$file="${_}"
		$app=${null}
		$module=${null}
		$title=${null}
		$version=${null}
		
		# Get the app
		$tokens=("${file}" -Split "\\")
		foreach ($token in ${tokens}) {
			if ("${token}" -like "*.ear") {
				$app="${token}".Replace(".ear", "")
				break
			}
		}
				
		# Check to see if the App is in the exclude array (skip if it is)
		if (!"${app}" -or ${excludes} -contains "${app}") {
			Write-Host "App is either null or on the exclude list"
			return
		}
		
		# Get the module
		$module=${tokens}[-3]
		
		# Check if we found the module for the App itself and give it a more friendly name
		if ("${module}" -eq "${app}") {
			$module="${module}.ear"
		}
				
		# Update the currentApp, if necessary
		if ("${app}" -ne "${currentApp}") {
			log "${separator}"
			$currentApp="${app}"
			$appCounter=0
		} else {
			$appCounter++
		}
				
		# Print the App name only if it's the first pass for that App
		if (${appCounter} -eq 0) {
			Write-Host ("{0,-10}{1,-10}`n" -f "App:", "${app}")
		}
		
		# Get the title from the manifest
		$title=$(((Get-Content "${file}" | Select-String "Implementation-Title") -Split ": ")[1])
		if (!"${title}") {
			$title="${notAvailable}"
		}
		
		# Get the version from the manifest
		$version=$(((Get-Content "${file}" | Select-String "Implementation-Version") -Split ": ")[1])
		if (!"${version}") {
			$version="${notAvailable}"
		}
		
		# Print the module name
		if (!"${module}") {
			Write-Host ("`n{0,-10}{1,-10}" -f "Module:", "${app}")
		} else {
			Write-Host ("`n{0,-10}{1,-10}" -f "Module:", "${module}")
		}
		
		# Print the title 
		if ("${title}" -eq "${notAvailable}") {
			Write-Host -ForegroundColor Red ("{0,-10}{1,-10}" -f "Title:", "${title}")
		} else {
			Write-Host ("{0,-10}{1,-10}" -f "Title:", "${title}")
		}
		
		# Print the version
		if ("${version}" -eq "${notAvailable}") {
			Write-Host -ForegroundColor Red ("{0,-10}{1,-10}" -f "Version:", "${version}")
		} else {
			Write-Host ("{0,-10}{1,-10}" -f "Version:", "${version}")
		}
		
	}