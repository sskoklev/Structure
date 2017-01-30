# Script: Exchange Web Service managed API Install
# Author: Marina Krynina
#################################################################################################
# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#        \Logs

try
{
    $scriptPath = $env:USERPROFILE
    . .\Install\Install-EwsManagedApi.ps1 $scriptPath

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 