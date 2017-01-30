Param(
    [string] $scriptPath
)


###############################################################################
# Author: Kulothunkan Palasundram
# Desc:   Functions to support removal of office web apps server from farm
# Main
###############################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 

try
{
    $msg = "remove office web apps server from farm"
    log "INFO: Starting $msg"

    # Do the work
    $process = "$PSHOME\powershell.exe"
    $argument = "-file $scriptPath\Config\Remove-WAC2013Server.ps1 ; exit `$LastExitCode"

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