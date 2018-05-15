# Source prereqs
. (Join-Path "${PSScriptRoot}" etc\ictools.ps1)
. (Join-Path "${PSScriptRoot}" utils.ps1)

# Set global variables
init

# Make sure we're running as admin
checkForAdmin

# Make sure TDI is available on this system
checkForTDI

Write-Host -NoNewLine ("{0,-60}" -f "Synchronizing Profiles with LDAP...")

# Change directories to run the command (only seems to be required for Windows)
Push-Location -Path "${tdiSolutionDir}" -StackName ConnectionsTools

& "${tdiSolutionDir}\sync_all_dns.bat" *>${null}

# Change back to the previous directory
Pop-Location -StackName ConnectionsTools

# Report status
if (${?}) {
    Write-Host -ForegroundColor Green ("{0,-7}" -f "SUCCESS")
} else {
    Write-Host -ForegroundColor Red ("{0,-7}" -f "FAILURE")
}

# Reset global variables
term