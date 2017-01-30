# Script: SharePoint2013 Install
# Author: Marina Krynina
#################################################################################################
# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#        \Logs

try
{
    # delay execution to ensure the VM is up and running after reboot performed by Install Prereqs
    Start-Sleep -s 120
    $scriptPath = $env:USERPROFILE
    . .\LoggingV2.ps1 $true $scriptPath "Install-SharePoint2013.ps1"
    . .\Install\Install-SharePoint2013.ps1 $scriptPath
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 