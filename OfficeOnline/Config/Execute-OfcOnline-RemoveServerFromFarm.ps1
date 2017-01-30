Param(
    [string] $scriptPath
)


###############################################################################
# Author: Kulothunkan Palasundram
# Updated: Marina Krynina
# Desc:   Functions to support removal of office web apps server from farm
# Main
###############################################################################
Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\LoggingV3.ps1 $true $scriptPath "Execute-OfcOnline-RemoveServerFromFarm.ps1"

try
{
    $msg = "remove current server from Office Online farm"
    log "INFO: Starting $msg"

    # Do the work
    $process = "$PSHOME\powershell.exe"
    $argument = "-file $scriptPath\Config\OfcOnline-RemoveServerFromFarm.ps1 -scriptPath $scriptPath ; exit `$LastExitCode"

    log "INFO: Calling $process by using LaunchProcessAsAdministrator"
    log "INFO: Arguments $argument"

    LaunchProcessAsAdministrator $process $argument 

    log "INFO: Finished $msg."

    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}