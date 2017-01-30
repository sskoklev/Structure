# MWS2R3 - Install a Office Web Apps update ###############################################################
# Author: Marina Krynina
# Desc:  installs an update
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
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition   
    $scriptName = $MyInvocation.MyCommand.Name

    . .\LoggingV2.ps1 $true $scriptPath "Execute-InstallWAC2013Update.ps1"
    . .\Install\Execute-InstallWAC2013Update.ps1 $scriptPath
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 

