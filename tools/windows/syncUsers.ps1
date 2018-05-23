# Source prereqs
. C:\ProgramData\ConnectionsTools\ictools.ps1
. (Join-Path "${PSScriptRoot}" utils.ps1)

init

# Make sure we're running as admin
checkForAdmin

# Make sure TDI is available on this system
checkForTDI

Write-Host -NoNewLine ("{0,${left2Column}}" -f "Synchronizing Profiles with LDAP...")

# Change directories to run the command (only seems to be required for Windows)
Push-Location -Path "${tdiSolutionDir}" -StackName ConnectionsTools

& "${tdiSolutionDir}\sync_all_dns.bat" *>${null}

# Report status
if (${LASTEXITCODE} -eq 0) {
    Write-Host -ForegroundColor Green ("{0,${right2Column}}" -f "SUCCESS")
} else {
    Write-Host -ForegroundColor Red ("{0,${right2Column}}" -f "FAILURE")
}

# Change back to the previous directory
Pop-Location -StackName ConnectionsTools