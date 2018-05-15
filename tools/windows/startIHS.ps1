# Source prereqs
. (Join-Path "${PSScriptRoot}" etc\ictools.ps1)
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

startIHSServer

# Reset global variables
term