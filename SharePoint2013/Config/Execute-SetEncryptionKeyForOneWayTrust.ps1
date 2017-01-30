Param(
    [string] $scriptPath
)


#################################################################################################
# Author: Marina Krynina
# Desc:   Functions to support using people picker over a one-way trust
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

$msg = "Start People picker configuration - Set app password"
log "INFO: Starting $msg"
log "INFO: Getting variables values or setting defaults if the variables are not populated."

# *** setup account 
$domain = get-domainshortname
$domainFull = get-domainname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user

$APP_PASSWORD = (Get-VariableValue $APP_PASSWORD $password $true)    

# STSADM.EXE -o setapppassword -password $APP_PASSWORD
$process = "$PSHOME\powershell.exe"
try
{
    $argument = "-file $scriptPath\Config\Set-EncryptionKeyForOneWayTrust.ps1 -scriptPath $scriptPath -password $APP_PASSWORD; exit `$LastExitCode"

    log "INFO: Calling $process under identity $domain\$user"
    log "INFO: Arguments $argument"

    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password

    # DEBUG
    # . .\Config\Set-EncryptionKeyForOneWayTrust.ps1 $scriptPath $APP_PASSWORD
    
    CheckForError

    log "INFO: Finished $msg."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}