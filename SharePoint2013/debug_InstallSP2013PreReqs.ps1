# Script: SharePoint2013 pre-reqs Install
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
    . .\LoggingV2.ps1 $true $scriptPath "Install-SharePoint2013PreRequisites.ps1"
    . .\Install\Install-SharePoint2013PreRequisites.ps1 $scriptPath
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
