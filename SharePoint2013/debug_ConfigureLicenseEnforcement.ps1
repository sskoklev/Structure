# Script: SharePoint2013 Farm Config
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
    $scriptPath = "c:\users\devraus01"
    . .\LoggingV2.ps1 $true $scriptPath "Execute-LicenseEnforcement.ps1"
    . .\Config\Execute-LicenseEnforcement.ps1 $scriptPath
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
