# Script: Server side testing - Common
# Author: Marina Krynina
#################################################################################################
# \USER_PROFILE
#        \TestResults
#        \Logs

try
{
    $scriptPath = $env:USERPROFILE
    . .\LoggingV2.ps1 $true $scriptPath "Execute-UnitTest-Server.ps1"
    . .\$TESTFRAMEWORKFOLDER\Execute-UnitTest-Server.ps1 $scriptPath
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
