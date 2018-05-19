# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Verify commands are available
Get-Command xmllint *>${null}
if (!${?}) {
	log "The xmllint command is required to run this script"
	exit 1
} 

# Ensure the user supplied the file to validate
$xmlFile=${args}[0]
if (!$(Test-Path "${xmlFile}")) {
	log "Usage: validateXML.ps1 XML_FILE"
	exit 1
} else {
	$fileObject=$(Get-Item "${xmlFile}")
	$directory=${fileObject}.DirectoryName
	$file=${fileObject}.Name
	$base=${fileObject}.BaseName
	$xsdFile="${directory}\${base}.xsd"
}

xmllint -schema "${xsdFile}" "${xmlFile}" --noout