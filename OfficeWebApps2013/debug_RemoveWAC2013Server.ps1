######################################################### 
# Script: debug_RemoveWAC2013Server  ####################
# Author: Kulothunkan Palasundram
# Desc:  Removes a server from the Office Web Apps Farm 
#########################################################
# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#            \MWSUpdates
#        \Logs

try
{
    $scriptPath = $env:USERPROFILE
    . .\LoggingV2.ps1 $true $scriptPath "Execute-RemoveWAC2013Server.ps1"
    . .\Config\Execute-RemoveWAC2013Server.ps1 $scriptPath
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 

