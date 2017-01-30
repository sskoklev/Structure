# MWS2R3 - Install a SharePoint update ###############################################################
# Author: Marina Krynina
# Desc:   Manages sharepoint services and installs an update
############################################################################################
# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#            \MWSUpdates
#        \Logs

try
{
    # $scriptPath = $env:USERPROFILE
    $scriptPath = "c:\users\mkrynina"
    . .\LoggingV2.ps1 $true $scriptPath "Execute-InstallSP2013Update.ps1"
    . .\Install\Execute-InstallSP2013Update.ps1 $scriptPath
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 

