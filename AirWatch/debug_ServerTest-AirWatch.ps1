# Script: Server side testing - AirWatch
# Author: Marina Krynina
#################################################################################################
# \USER_PROFILE
#        \TestResults
#        \Logs

try
{
     $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

    . .\LoggingV3.ps1 $true $scriptPath "ServerTest-AirWatch.ps1"
    . .\TestFramework\ServerTest-AirWatch.ps1 $scriptPath "TestFramework"
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
