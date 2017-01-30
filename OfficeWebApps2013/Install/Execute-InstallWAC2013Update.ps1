Param(
    [string] $scriptPath
)


#################################################################################################
# Author: Marina Krynina
# Desc:   Functions to support installation of SharePoint updates
#################################################################################################

function CheckForError
{
    # check if error.txt exists. if yes, read it and throw exception
    # This is done to get an error code from the scheduled task.
    $errorFile = "$scriptPath\error.txt"
    if (CheckFileExists($errorFile))
    {
        $error = Get-Content $errorFile
        Remove-Item $errorFile
   
        throw $error
    }
}

############################################################################################
# Main
############################################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 

try
{
    $msg = "Start installation of SharePoint update(s)"
    log "INFO: Starting $msg"
    log "INFO: Getting variables values or setting defaults if the variables are not populated."

    # *** setup account 
    $domain = get-domainshortname
    $domainFull = get-domainname


    # Manage Agility variables
    $patchLocation = $scriptPath + (Get-VariableValue $MWSUPDATES_LOCATION "\InstallMedia\MWSUpdates" $true)
    $patches = (Get-VariableValue $MWSUPDATES_LIST "wacserver*.exe" $true)
    
    # Do the work
    $process = "$PSHOME\powershell.exe"
    $argument = "-file $scriptPath\Install\Install-WAC2013Update.ps1 -scriptPath $scriptPath -patchLocation $patchLocation -patches `"$patches`" ; exit `$LastExitCode"

    log "INFO: Calling $process as an Administrator"
    log "INFO: Arguments $argument"

    LaunchProcessAsAdministrator $process $argument

    # Check for error
    CheckForError

    log "INFO: Finished $msg."

    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}